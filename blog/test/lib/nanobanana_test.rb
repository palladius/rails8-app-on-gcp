require "test_helper"

class NanobananaTest < ActiveSupport::TestCase
  SAMPLE_IMAGE = Rails.root.join("db/seeds/test_image_600x400.jpg")

  # --- prompt -----------------------------------------------------------------

  test "text under 30 bytes is unintelligible" do
    assert Nanobanana.unintelligible_or_too_short?("Hi", "there")
  end

  test "keyboard mash is unintelligible even when long" do
    assert Nanobanana.unintelligible_or_too_short?("qwertyuiop qwertyuiop", "asdfghjkl asdfghjkl zxcvbnm")
    assert Nanobanana.unintelligible_or_too_short?("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "")
  end

  test "real prose is intelligible" do
    assert_not Nanobanana.unintelligible_or_too_short?("Rails 8 on Cloud Run", "Deploying a blog with Solid Queue and private GCS buckets.")
  end

  test "fallback prompt celebrates prog metal in Modena" do
    prompt = Nanobanana.prompt_for("qwerty", "asdf")
    assert_match(/progressive metal/i, prompt)
    assert_match(/Modena/, prompt)
    assert_no_match(/qwerty/, prompt)
  end

  test "regular prompt is inspired by title and body" do
    prompt = Nanobanana.prompt_for("Rails 8 on Cloud Run", "Deploying a blog with Solid Queue and private GCS buckets.")
    assert_match(/Rails 8 on Cloud Run/, prompt)
    assert_match(/Solid Queue/, prompt)
    assert_no_match(/Modena/, prompt)
  end

  test "both prompts carry the house style" do
    [ Nanobanana.prompt_for("qwerty", "asdf"), Nanobanana.prompt_for("A real title here", "And a proper body that is long enough.") ].each do |prompt|
      assert_match(/banana/i, prompt)
      assert_match(/ruby gem/i, prompt)
      assert_match(/"8"/, prompt)
      assert_match(/1960/, prompt)
      assert_match(/top-right/, prompt)
    end
  end

  test "body is truncated to keep the prompt bounded" do
    prompt = Nanobanana.prompt_for("A real title here", "word " * 1000)
    assert_operator prompt.bytesize, :<, 1500
  end

  # --- availability & generation ---------------------------------------------

  test "not available without a project id" do
    with_env("GOOGLE_CLOUD_PROJECT" => nil, "GCP_PROJECT_ID" => nil) do
      assert_not Nanobanana.available?
    end
  end

  test "not available without application default credentials" do
    with_env("GOOGLE_CLOUD_PROJECT" => "demo-project") do
      stub_singleton(Nanobanana, :credentials, nil) do
        assert_not Nanobanana.available?
      end
    end
  end

  test "falls back to the fake cover when no project is configured" do
    with_env("GOOGLE_CLOUD_PROJECT" => nil, "GCP_PROJECT_ID" => nil) do
      result = Nanobanana.generate_image("anything")
      assert_equal :fake, result.source
      assert_equal "image/png", result.content_type
      assert_equal File.binread(Nanobanana::FAKE_COVER), result.data
    end
  end

  test "falls back to the fake cover when credentials are missing" do
    with_env("GOOGLE_CLOUD_PROJECT" => "demo-project") do
      stub_singleton(Nanobanana, :credentials, nil) do
        assert_equal :fake, Nanobanana.generate_image("anything").source
      end
    end
  end

  test "falls back to the fake cover on network timeouts" do
    with_env("GOOGLE_CLOUD_PROJECT" => "demo-project") do
      stub_singleton(Nanobanana, :access_token!, "tok") do
        stub_singleton(Nanobanana, :post_generate_content, ->(*) { raise Net::OpenTimeout, "boom" }) do
          assert_equal :fake, Nanobanana.generate_image("anything").source
        end
      end
    end
  end

  test "falls back to the fake cover on HTTP errors" do
    with_env("GOOGLE_CLOUD_PROJECT" => "demo-project") do
      stub_singleton(Nanobanana, :access_token!, "tok") do
        stub_singleton(Nanobanana, :post_generate_content, http_response(Net::HTTPForbidden, "403", '{"error":"PERMISSION_DENIED"}')) do
          assert_equal :fake, Nanobanana.generate_image("anything").source
        end
      end
    end
  end

  test "falls back to the fake cover when the model returns no image part" do
    body = { candidates: [ { content: { parts: [ { text: "I refuse." } ] } } ] }.to_json
    with_env("GOOGLE_CLOUD_PROJECT" => "demo-project") do
      stub_singleton(Nanobanana, :access_token!, "tok") do
        stub_singleton(Nanobanana, :post_generate_content, http_response(Net::HTTPOK, "200", body)) do
          assert_equal :fake, Nanobanana.generate_image("anything").source
        end
      end
    end
  end

  test "decodes the inlineData image returned by Vertex AI" do
    png = File.binread(SAMPLE_IMAGE)
    body = { candidates: [ { content: { parts: [
      { text: "Here is your poster" },
      { inlineData: { mimeType: "image/jpeg", data: Base64.strict_encode64(png) } }
    ] } } ] }.to_json

    captured = nil
    capture = lambda do |uri, req_body, token|
      captured = [ uri, req_body, token ]
      http_response(Net::HTTPOK, "200", body)
    end

    with_env("GOOGLE_CLOUD_PROJECT" => "demo-project") do
      stub_singleton(Nanobanana, :access_token!, "tok") do
        stub_singleton(Nanobanana, :post_generate_content, capture) do
          result = Nanobanana.generate_image("draw me a banana")
          assert_equal :vertex, result.source
          assert_equal "image/jpeg", result.content_type
          assert_equal png, result.data
        end
      end
    end

    uri, req_body, token = captured
    assert_equal "tok", token
    assert_equal "aiplatform.googleapis.com", uri.host
    assert_match %r{/v1/projects/demo-project/locations/global/publishers/google/models/#{Nanobanana::MODEL}:generateContent}, uri.path
    assert_equal "draw me a banana", req_body.dig(:contents, 0, :parts, 0, :text)
    assert_includes req_body.dig(:generationConfig, :responseModalities), "IMAGE"
  end

  # --- provenance -------------------------------------------------------------

  test "storage tier is local under the Disk test service" do
    assert_equal :local, Nanobanana.storage_tier
  end

  test "storage tier is gcs for google services" do
    with_storage_service(:google_test) do
      assert_equal :gcs, Nanobanana.storage_tier
    end
  end

  test "local tier stamps a grayscale png of the same size" do
    require "vips"
    out = Nanobanana.stamp_provenance(File.binread(SAMPLE_IMAGE), tier: :local)
    image = Vips::Image.new_from_buffer(out, "")

    assert_equal "\x89PNG".b, out[0, 4]
    assert_equal [ 600, 400 ], [ image.width, image.height ]
    r, g, b = image.getpoint(30, 30).first(3)
    assert_in_delta r, g, 1
    assert_in_delta g, b, 1
  end

  test "gcs tier keeps the colors" do
    require "vips"
    original = Vips::Image.new_from_file(SAMPLE_IMAGE.to_s)
    out = Nanobanana.stamp_provenance(File.binread(SAMPLE_IMAGE), tier: :gcs)
    image = Vips::Image.new_from_buffer(out, "")

    assert_equal [ 600, 400 ], [ image.width, image.height ]
    assert_equal original.getpoint(30, 30).first(3).map(&:round), image.getpoint(30, 30).first(3).map(&:round)
  end

  test "stamp changes the bottom-right corner only" do
    require "vips"
    original = Vips::Image.new_from_file(SAMPLE_IMAGE.to_s)
    stamped  = Vips::Image.new_from_buffer(Nanobanana.stamp_provenance(File.binread(SAMPLE_IMAGE), tier: :gcs), "")

    assert_equal original.getpoint(30, 370).first(3).map(&:round), stamped.getpoint(30, 370).first(3).map(&:round)
    assert_not_equal original.getpoint(560, 360).first(3).map(&:round), stamped.getpoint(560, 360).first(3).map(&:round)
  end

  test "stamping never raises on garbage input" do
    assert_equal "not an image", Nanobanana.stamp_provenance("not an image", tier: :local)
  end

  private

  def http_response(klass, code, body)
    response = klass.new("1.1", code, nil)
    response.instance_variable_set(:@body, body)
    response.instance_variable_set(:@read, true)
    response
  end

  def with_env(envs)
    old = envs.keys.index_with { |k| ENV[k] }
    envs.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
    yield
  ensure
    old.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end

  def with_storage_service(name)
    previous = Rails.configuration.active_storage.service
    Rails.configuration.active_storage.service = name
    yield
  ensure
    Rails.configuration.active_storage.service = previous
  end
end
