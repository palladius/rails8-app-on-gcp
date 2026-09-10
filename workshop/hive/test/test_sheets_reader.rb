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
end
