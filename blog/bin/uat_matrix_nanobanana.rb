#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../config/environment"

# Extensive UAT Matrix Runner for PR #32 / Issue #18
# Dimensions:
#   1. Storage: Local vs GCS
#   2. Vertex AI: Available (mocked/live) vs Fake/Unavailable
#   3. Cover: Uploaded vs Auto-Generated

puts "🧪" * 30
puts "🍌 EXTENSIVE UAT MATRIX RUNNER (PR #32 / Issue #18)"
puts "Testing 8 permutations of: [Local/GCS] x [AI Real/Fake] x [Upload/Generated]"
puts "🧪" * 30

SAMPLE_IMAGE = Rails.root.join("db/seeds/test_image_600x400.jpg")
helper = Class.new { include ActionView::Helpers::TagHelper; include ApplicationHelper }.new

results = []

def run_case(id, name, storage_tier:, ai_working:, user_uploaded:, &block)
  print "[%02d/08] %-55s " % [id, name]
  
  # Configure active storage service
  service_name = (storage_tier == :gcs ? :google_dev : :local)
  prev_service = Rails.configuration.active_storage.service
  Rails.configuration.active_storage.service = service_name
  
  # Stub or configure Nanobanana
  orig_available = Nanobanana.method(:available?)
  orig_generate = Nanobanana.method(:generate_image)
  
  if ai_working
    Nanobanana.define_singleton_method(:available?) { true }
    Nanobanana.define_singleton_method(:generate_image) do |_prompt|
      Nanobanana::Result.new(
        data: File.binread(SAMPLE_IMAGE),
        content_type: "image/jpeg",
        source: :vertex
      )
    end
  else
    Nanobanana.define_singleton_method(:available?) { false }
    Nanobanana.define_singleton_method(:generate_image) do |_prompt|
      Nanobanana.send(:fake_cover, "UAT Simulated AI failure / missing credentials")
    end
  end

  # Execute test
  post = Post.new(title: "UAT #{id}: #{name}", body: "Extensive UAT verification body with sufficient length.")
  if user_uploaded
    post.cover_image.attach(io: File.open(SAMPLE_IMAGE), filename: "user_upload.jpg", content_type: "image/jpeg")
  end
  post.save!

  unless user_uploaded
    GenerateCoverImageJob.perform_now(post.id)
  end
  post.reload

  # Verifications
  helper = Class.new { include ActionView::Helpers::TagHelper; include ApplicationHelper }.new
  tier_detected = helper.storage_tier
  css_class = helper.cover_image_classes
  tooltip = helper.cover_image_title
  cover_filename = post.cover_image.filename.to_s
  is_attached = post.cover_image.attached?

  passed = true
  reasons = []

  unless is_attached
    passed = false
    reasons << "No cover attached"
  end

  if storage_tier == :local
    unless tier_detected == :local && css_class.include?("cover-image--local") && tooltip.include?("ephemeral")
      passed = false
      reasons << "Local UI badge/provenance mismatch"
    end
  else
    unless tier_detected == :gcs && css_class == "" && tooltip.include?("Google Cloud Storage")
      passed = false
      reasons << "GCS UI badge/provenance mismatch"
    end
  end

  if user_uploaded
    unless cover_filename == "user_upload.jpg"
      passed = false
      reasons << "Cover filename was overwritten instead of kept: #{cover_filename}"
    end
  else
    expected_src = ai_working ? "vertex" : "fake"
    expected_tier = storage_tier.to_s
    unless cover_filename == "cover_#{post.id}_#{expected_src}_#{expected_tier}.png"
      passed = false
      reasons << "Generated filename pattern wrong: #{cover_filename}"
    end
  end

  if passed
    puts "✅ PASS  (#{cover_filename}, tier: #{tier_detected})"
  else
    puts "❌ FAIL  (#{reasons.join(', ')})"
  end

  # Cleanup
  post.destroy

  { id: id, name: name, passed: passed, filename: cover_filename, tier: tier_detected, errors: reasons }
ensure
  Rails.configuration.active_storage.service = prev_service
  Nanobanana.singleton_class.send(:remove_method, :available?)
  Nanobanana.define_singleton_method(:available?, orig_available)
  Nanobanana.singleton_class.send(:remove_method, :generate_image)
  Nanobanana.define_singleton_method(:generate_image, orig_generate)
end

matrix = [
  { id: 1, name: "Local Disk + Real AI + User Upload", storage_tier: :local, ai_working: true, user_uploaded: true },
  { id: 2, name: "Local Disk + Real AI + Auto-Generated", storage_tier: :local, ai_working: true, user_uploaded: false },
  { id: 3, name: "Local Disk + Fake AI + User Upload", storage_tier: :local, ai_working: false, user_uploaded: true },
  { id: 4, name: "Local Disk + Fake AI + Auto-Generated", storage_tier: :local, ai_working: false, user_uploaded: false },
  { id: 5, name: "GCS Bucket + Real AI + User Upload", storage_tier: :gcs, ai_working: true, user_uploaded: true },
  { id: 6, name: "GCS Bucket + Real AI + Auto-Generated", storage_tier: :gcs, ai_working: true, user_uploaded: false },
  { id: 7, name: "GCS Bucket + Fake AI + User Upload", storage_tier: :gcs, ai_working: false, user_uploaded: true },
  { id: 8, name: "GCS Bucket + Fake AI + Auto-Generated", storage_tier: :gcs, ai_working: false, user_uploaded: false }
]

matrix.each do |tc|
  results << run_case(tc[:id], tc[:name], storage_tier: tc[:storage_tier], ai_working: tc[:ai_working], user_uploaded: tc[:user_uploaded])
end

puts "\n" + "=" * 60
puts "📊 UAT SUMMARY: #{results.count { |r| r[:passed] }}/8 passed"
puts "=" * 60
exit(results.all? { |r| r[:passed] } ? 0 : 1)
