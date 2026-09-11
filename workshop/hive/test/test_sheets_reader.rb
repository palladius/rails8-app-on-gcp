# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/sheets_reader"

class SheetsReaderTest < Minitest::Test
  def setup
    @sample_rows = [
      ["Timestamp", "Nickname", "Cloud Run URL", "Current Step"],
      ["2026-09-09T14:00:00Z", "RubyGeek", "https://blog-student1.a.run.app", "Step 3: Cloud SQL"],
      ["2026-09-09T14:05:00Z", "CloudNinja", "https://blog-student2.a.run.app", "Step 5: Cloud Run"]
    ]
  end

  def test_parse_rows_into_leaderboard_entries
    entries = WorkshopHive::SheetsReader.parse_rows(@sample_rows)
    assert_equal 2, entries.size

    entry1 = entries[0]
    assert_equal "RubyGeek", entry1[:nickname]
    assert_equal "https://blog-student1.a.run.app", entry1[:url]
    assert_equal "Step 3: Cloud SQL", entry1[:step]
    assert_equal 3, entry1[:step_number]
    assert_equal "2026-09-09T14:00:00Z", entry1[:timestamp]

    entry2 = entries[1]
    assert_equal "CloudNinja", entry2[:nickname]
    assert_equal 5, entry2[:step_number]
  end

  def test_extract_step_number_heuristics
    assert_equal 1, WorkshopHive::SheetsReader.extract_step_number("Step 1: Local Setup")
    assert_equal 7, WorkshopHive::SheetsReader.extract_step_number("step-7-ai-cover")
    assert_equal 0, WorkshopHive::SheetsReader.extract_step_number("Unknown step")
  end

  def test_mock_fallback_when_sheets_not_configured
    # When no sheet ID or credentials are provided, return mock data for local testing
    entries = WorkshopHive::SheetsReader.fetch_entries(sheet_id: nil, credentials: nil)
    refute_empty entries
    assert entries.all? { |e| e[:nickname] && e[:url] && e[:step] }
  end

  def test_parse_duration
    assert_equal 3600, WorkshopHive::SheetsReader.parse_duration("1h")
    assert_equal 86400, WorkshopHive::SheetsReader.parse_duration("24h")
    assert_equal 172800, WorkshopHive::SheetsReader.parse_duration("2d")
    assert_equal 604800, WorkshopHive::SheetsReader.parse_duration("1w")
    assert_equal 2592000, WorkshopHive::SheetsReader.parse_duration("1mo")
    assert_equal 1800, WorkshopHive::SheetsReader.parse_duration("30m")
    assert_nil WorkshopHive::SheetsReader.parse_duration("all")
    assert_nil WorkshopHive::SheetsReader.parse_duration("")
    assert_nil WorkshopHive::SheetsReader.parse_duration(nil)
  end

  def test_filter_by_max_age
    now = Time.now
    entries = [
      { nickname: "Fresh", url: "https://fresh.run.app", timestamp: (now - 3600).iso8601 }, # 1 hour ago
      { nickname: "Yesterday", url: "https://yesterday.run.app", timestamp: (now - 90000).iso8601 }, # ~25 hours ago
      { nickname: "Ancient", url: "https://ancient.run.app", timestamp: (now - 86400 * 40).iso8601 } # 40 days ago
    ]

    filtered_24h = WorkshopHive::SheetsReader.filter_by_max_age(entries, "24h")
    assert_equal 1, filtered_24h.size
    assert_equal "Fresh", filtered_24h.first[:nickname]

    filtered_2d = WorkshopHive::SheetsReader.filter_by_max_age(entries, "2d")
    assert_equal 2, filtered_2d.size
    assert_equal ["Fresh", "Yesterday"], filtered_2d.map { |e| e[:nickname] }

    filtered_1mo = WorkshopHive::SheetsReader.filter_by_max_age(entries, "1mo")
    assert_equal 2, filtered_1mo.size

    filtered_all = WorkshopHive::SheetsReader.filter_by_max_age(entries, "all")
    assert_equal 3, filtered_all.size
  end

  def test_normalize_url
    assert_equal "https://blog.run.app", WorkshopHive::SheetsReader.normalize_url("https://blog.run.app/")
    assert_equal "https://blog.run.app", WorkshopHive::SheetsReader.normalize_url("https://BLOG.RUN.APP/")
    assert_equal "https://blog.run.app", WorkshopHive::SheetsReader.normalize_url("http://blog.run.app/")
    assert_equal "https://blog.run.app", WorkshopHive::SheetsReader.normalize_url("  https://blog.run.app/  ")
    assert_equal "http://localhost:8088", WorkshopHive::SheetsReader.normalize_url("http://localhost:8088/")
    assert_equal "", WorkshopHive::SheetsReader.normalize_url("")
    assert_equal "", WorkshopHive::SheetsReader.normalize_url(nil)
  end

  def test_deduplicate_by_url_takes_second_or_last_entry
    entries = [
      { nickname: "FirstSubmission", url: "https://my-app.a.run.app/", timestamp: "10:00" },
      { nickname: "AnotherStudent", url: "https://other-app.a.run.app", timestamp: "10:05" },
      { nickname: "SecondSubmission_Updated", url: "https://my-app.a.run.app", timestamp: "10:15" }
    ]

    deduped = WorkshopHive::SheetsReader.deduplicate_by_url(entries)
    assert_equal 2, deduped.size

    # The second / last submission for my-app is retained
    assert_equal "AnotherStudent", deduped[0][:nickname]
    assert_equal "SecondSubmission_Updated", deduped[1][:nickname]
    assert_equal "10:15", deduped[1][:timestamp]
  end

  def test_parse_rows_deduplicates_when_requested
    rows = [
      ["Timestamp", "Nickname", "Cloud Run URL", "Current Step"],
      ["10/09/2026 11:52:31", "Ricc dupe prima", "https://rails8-workshop-fl05-rails-app-421858982833.europe-west1.run.app/", "Step 5"],
      ["10/09/2026 11:53:00", "IndependentStudent", "https://rails8-independent-123.europe-west1.run.app/", "Step 3"],
      ["10/09/2026 11:58:31", "RiccardinoCM26_Gold_FL005", "https://rails8-workshop-fl05-rails-app-421858982833.europe-west1.run.app/", "Step 5"]
    ]

    # Without deduplication
    all_entries = WorkshopHive::SheetsReader.parse_rows(rows, deduplicate: false)
    assert_equal 3, all_entries.size

    # With deduplication
    deduped = WorkshopHive::SheetsReader.parse_rows(rows, deduplicate: true)
    assert_equal 2, deduped.size
    assert_equal "IndependentStudent", deduped[0][:nickname]
    assert_equal "RiccardinoCM26_Gold_FL005", deduped[1][:nickname]
  end

  def test_fetch_entries_deduplicate_parameter
    sample = [
      { nickname: "First", url: "https://dupe.run.app/", timestamp: "11:00" },
      { nickname: "Unique", url: "https://unique.run.app/", timestamp: "11:05" },
      { nickname: "Second", url: "https://dupe.run.app", timestamp: "11:10" }
    ]

    original_raw = WorkshopHive::SheetsReader.method(:get_raw_entries)
    WorkshopHive::SheetsReader.define_singleton_method(:get_raw_entries) { |**_args| sample }

    begin
      # Default: deduplicate: true
      default_entries = WorkshopHive::SheetsReader.fetch_entries
      assert_equal 2, default_entries.size
      assert_equal "Second", default_entries[1][:nickname]

      # Explicit: deduplicate: false (show duplicates)
      all_entries = WorkshopHive::SheetsReader.fetch_entries(deduplicate: false)
      assert_equal 3, all_entries.size
      assert_equal ["First", "Unique", "Second"], all_entries.map { |e| e[:nickname] }
    ensure
      WorkshopHive::SheetsReader.define_singleton_method(:get_raw_entries, original_raw)
    end
  end
end
