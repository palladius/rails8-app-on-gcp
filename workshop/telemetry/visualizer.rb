# frozen_string_literal: true

require "cgi"
require "time"

class FrictionLogVisualizer
  COLORS = {
    bg: "#0d1117",
    card_bg: "#161b22",
    border: "#30363d",
    text_primary: "#f0f6fc",
    text_secondary: "#8b949e",
    accent_blue: "#58a6ff",
    accent_green: "#3fb950",
    accent_yellow: "#d29922",
    accent_red: "#f85149",
    accent_purple: "#bc8cff",
    pause_fill: "url(#pause-pattern)",
    step_palette: [
      "#4285f4", "#34a853", "#fbbc05", "#ea4335",
      "#a142f4", "#24c1e0", "#ff7043", "#78909c", "#00bfa5"
    ]
  }.freeze

  STEP_NAMES = [
    "Step 0: Setup & Prereqs",
    "Step 1: Terraform IaC",
    "Step 2: Local Docker/SQLite",
    "Step 3: Cloud Run Baseline",
    "Step 4: ActiveStorage GCS",
    "Step 5: Cloud SQL Postgres",
    "Step 6: Puma + Solid Queue",
    "Step 7: GenAI Vertex / Nano Banana",
    "Step 8: Hive & Graduation Trophy"
  ].freeze

  def initialize(logs)
    @logs = logs.sort_by { |l| l.started_time || Time.at(0) }
  end

  def render_gantt_svg
    width = 1200
    row_height = 46
    header_height = 110
    height = header_height + (@logs.size * row_height) + 60
    chart_left = 180
    chart_right = width - 40
    chart_width = chart_right - chart_left

    t_min = @logs.map(&:started_time).compact.min
    t_max = @logs.map(&:ended_time).compact.max
    time_span = [t_max - t_min, 1.0].max

    svg = []
    svg << %(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 #{width} #{height}" width="#{width}" height="#{height}">)
    svg << render_svg_defs
    svg << %(<rect width="100%" height="100%" fill="#{COLORS[:bg]}"/>)

    # Title & Subtitle
    svg << %(<text x="30" y="42" fill="#{COLORS[:text_primary]}" font-family="system-ui, -apple-system, sans-serif" font-size="22" font-weight="700">📊 Friction Log Telemetry: FL000–FL007 End-to-End Timeline</text>)
    svg << %(<text x="30" y="68" fill="#{COLORS[:text_secondary]}" font-family="system-ui, -apple-system, sans-serif" font-size="13">Chronological execution tracks with active run periods, pause intervals, and evaluation maturity.</text>)

    # Time grid lines
    num_grid_ticks = 8
    (0..num_grid_ticks).each do |i|
      tick_time = t_min + (time_span * i / num_grid_ticks.to_f)
      gx = chart_left + (chart_width * i / num_grid_ticks.to_f)
      svg << %(<line x1="#{gx}" y1="#{header_height - 15}" x2="#{gx}" y2="#{height - 35}" stroke="#{COLORS[:border]}" stroke-dasharray="3,3"/>)
      svg << %(<text x="#{gx}" y="#{header_height - 20}" fill="#{COLORS[:text_secondary]}" font-family="monospace" font-size="11" text-anchor="middle">#{tick_time.strftime("%b %d")}</text>)
    end

    # Rows
    @logs.each_with_index do |log, idx|
      y = header_height + (idx * row_height)

      # Row background
      bg_col = idx.even? ? COLORS[:card_bg] : COLORS[:bg]
      svg << %(<rect x="20" y="#{y - 4}" width="#{width - 40}" height="#{row_height - 4}" rx="6" fill="#{bg_col}" stroke="#{COLORS[:border]}" stroke-width="0.5"/>)

      # Log ID & Title
      status_color = log.status == "success" ? COLORS[:accent_green] : (log.status == "blocked" ? COLORS[:accent_red] : COLORS[:accent_yellow])
      svg << %(<circle cx="35" cy="#{y + 16}" r="6" fill="#{status_color}"/>)
      svg << %(<text x="50" y="#{y + 20}" fill="#{COLORS[:accent_blue]}" font-family="monospace" font-size="14" font-weight="bold">#{CGI.escapeHTML(log.id)}</text>)
      svg << %(<text x="110" y="#{y + 20}" fill="#{COLORS[:text_secondary]}" font-family="monospace" font-size="11">#{CGI.escapeHTML(log.eval_score)}</text>)

      s_time = log.started_time || t_min
      e_time = log.ended_time || t_max

      bar_start_x = chart_left + ((s_time - t_min) / time_span * chart_width)
      bar_end_x = chart_left + ((e_time - t_min) / time_span * chart_width)
      bar_w = [bar_end_x - bar_start_x, 8.0].max

      # Main Run Bar
      grad_id = log.status == "success" ? "active-grad-green" : "active-grad-blue"
      svg << %(<rect class="run-bar" x="#{bar_start_x.round(1)}" y="#{y + 5}" width="#{bar_w.round(1)}" height="22" rx="4" fill="url(##{grad_id})" opacity="0.9">)
      svg << %(<title>#{CGI.escapeHTML("#{log.id}: #{log.title}\nActive: #{(log.active_duration_seconds / 60.0).round(1)}m | Wall: #{(log.wall_clock_duration_seconds / 3600.0).round(1)}h")}</title>)
      svg << %(</rect>)

      # Pauses
      log.pauses.each do |pause|
        ps = Time.iso8601(pause["started_at"]) rescue nil
        pr = Time.iso8601(pause["resumed_at"]) rescue nil
        if ps && pr
          px1 = chart_left + ((ps - t_min) / time_span * chart_width)
          px2 = chart_left + ((pr - t_min) / time_span * chart_width)
          pw = [px2 - px1, 4.0].max
          svg << %(<rect class="pause-bar" x="#{px1.round(1)}" y="#{y + 5}" width="#{pw.round(1)}" height="22" rx="4" fill="#{COLORS[:pause_fill]}" stroke="#{COLORS[:accent_yellow]}" stroke-width="1.2">)
          svg << %(<title>#{CGI.escapeHTML("Pause: #{pause['reason']}")}</title>)
          svg << %(</rect>)
        end
      end

      # Duration label
      dur_label = log.paused? ? "#{(log.active_duration_seconds / 60.0).round}m active (#{(log.wall_clock_duration_seconds / 3600.0).round}h wall)" : "#{(log.active_duration_seconds / 60.0).round}m"
      svg << %(<text x="#{(bar_end_x + 8).round(1)}" y="#{y + 20}" fill="#{COLORS[:text_secondary]}" font-family="sans-serif" font-size="11">#{dur_label}</text>)
    end

    # Legend
    leg_y = height - 20
    svg << %(<g transform="translate(180, #{leg_y})">)
    svg << %(<rect x="0" y="-10" width="16" height="12" rx="2" fill="url(#active-grad-green)"/>)
    svg << %(<text x="22" y="0" fill="#{COLORS[:text_primary]}" font-family="sans-serif" font-size="11">Active Execution</text>)
    svg << %(<rect x="140" y="-10" width="16" height="12" rx="2" fill="#{COLORS[:pause_fill]}" stroke="#{COLORS[:accent_yellow]}" stroke-width="1"/>)
    svg << %(<text x="162" y="0" fill="#{COLORS[:text_primary]}" font-family="sans-serif" font-size="11">Paused / Interrupted Interval</text>)
    svg << %(<circle cx="340" cy="-4" r="5" fill="#{COLORS[:accent_green]}"/>)
    svg << %(<text x="352" y="0" fill="#{COLORS[:text_primary]}" font-family="sans-serif" font-size="11">Success</text>)
    svg << %(<circle cx="420" cy="-4" r="5" fill="#{COLORS[:accent_red]}"/>)
    svg << %(<text x="432" y="0" fill="#{COLORS[:text_primary]}" font-family="sans-serif" font-size="11">Blocked</text>)
    svg << %(</g>)

    svg << %(</svg>)
    svg.join("\n")
  end

  def render_concurrency_svg
    width = 1100
    height = 420
    fl06 = @logs.find { |l| l.id == "FL006" }
    fl07 = @logs.find { |l| l.id == "FL007" }

    t_start = Time.iso8601("2026-09-11T12:00:00Z")
    t_end = Time.iso8601("2026-09-16T12:00:00Z")
    time_span = t_end - t_start

    chart_left = 180
    chart_right = width - 60
    chart_w = chart_right - chart_left

    svg = []
    svg << %(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 #{width} #{height}" width="#{width}" height="#{height}">)
    svg << render_svg_defs
    svg << %(<rect width="100%" height="100%" fill="#{COLORS[:bg]}"/>)

    # Title
    svg << %(<text x="30" y="42" fill="#{COLORS[:text_primary]}" font-family="system-ui, sans-serif" font-size="22" font-weight="700">⚡ Concurrency &amp; Dual PR Overlap: FL006 vs FL007</text>)
    svg << %(<text x="30" y="68" fill="#{COLORS[:text_secondary]}" font-family="system-ui, sans-serif" font-size="13">Demonstrating parallel run tracks starting from identical ancestor commit, pausing in tandem, and generating concurrent PR pairs.</text>)

    # Day columns (Sep 11, 12, 13, 14, 15, 16)
    days = ["Sep 11 (Thu)", "Sep 12 (Fri)", "Sep 13 (Sat)", "Sep 14 (Sun)", "Sep 15 (Mon)", "Sep 16 (Tue)"]
    days.each_with_index do |dname, i|
      dx = chart_left + (chart_w * i / (days.size - 1.0))
      svg << %(<line x1="#{dx}" y1="95" x2="#{dx}" y2="#{height - 60}" stroke="#{COLORS[:border]}" stroke-dasharray="4,4"/>)
      svg << %(<text x="#{dx}" y="90" fill="#{COLORS[:text_secondary]}" font-family="monospace" font-size="11" text-anchor="middle">#{dname}</text>)
    end

    # Weekend Shading (Sep 12 evening to Sep 15 morning)
    w_start = Time.iso8601("2026-09-12T00:00:00Z")
    w_end = Time.iso8601("2026-09-15T00:00:00Z")
    wx1 = chart_left + ((w_start - t_start) / time_span * chart_w)
    wx2 = chart_left + ((w_end - t_start) / time_span * chart_w)
    svg << %(<rect x="#{wx1.round(1)}" y="105" width="#{(wx2 - wx1).round(1)}" height="#{height - 170}" fill="#{COLORS[:card_bg]}" opacity="0.6"/>)
    svg << %(<text x="#{((wx1 + wx2) / 2.0).round(1)}" y="125" fill="#{COLORS[:text_secondary]}" font-family="monospace" font-size="12" text-anchor="middle">⏸️ Interrupted / Weekend Pause Window</text>)

    # Tracks
    items = [
      { log: fl06, y: 155, prs: ["#99 (8 fixes)", "#109 (Ruby 3.4.5)", "#113 (7 fixes)"], color: COLORS[:accent_blue] },
      { log: fl07, y: 245, prs: ["#130 (Project env)", "#133 (SA IAM + Schema load)"], color: COLORS[:accent_purple] }
    ]

    items.each do |item|
      log = item[:log]
      y = item[:y]
      next unless log

      s_time = log.started_time
      e_time = log.ended_time

      x1 = chart_left + ((s_time - t_start) / time_span * chart_w)
      x2 = chart_left + ((e_time - t_start) / time_span * chart_w)

      # Track label
      svg << %(<text x="30" y="#{y + 16}" fill="#{item[:color]}" font-family="monospace" font-size="16" font-weight="bold">#{log.id}</text>)
      svg << %(<text x="30" y="#{y + 34}" fill="#{COLORS[:text_secondary]}" font-family="monospace" font-size="11">#{log.gcp_project_id}</text>)

      # Bar
      svg << %(<rect x="#{x1.round(1)}" y="#{y}" width="#{(x2 - x1).round(1)}" height="28" rx="6" fill="#{item[:color]}" opacity="0.85"/>)

      # Pauses
      log.pauses.each do |pause|
        ps = Time.iso8601(pause["started_at"])
        pr = Time.iso8601(pause["resumed_at"])
        px1 = chart_left + ((ps - t_start) / time_span * chart_w)
        px2 = chart_left + ((pr - t_start) / time_span * chart_w)
        svg << %(<rect class="pause-bar" x="#{px1.round(1)}" y="#{y}" width="#{(px2 - px1).round(1)}" height="28" rx="4" fill="#{COLORS[:pause_fill]}" stroke="#{COLORS[:accent_yellow]}" stroke-width="1.5">)
        svg << %(<title>#{CGI.escapeHTML("Pause: #{pause['reason']}")}</title>)
        svg << %(</rect>)
      end

      # Ancestor Commit Callout
      svg << %(<circle cx="#{x1.round(1)}" cy="#{y + 14}" r="5" fill="#{COLORS[:accent_yellow]}"/>)
      svg << %(<text x="#{x1.round(1) - 8}" y="#{y - 6}" fill="#{COLORS[:accent_yellow]}" font-family="monospace" font-size="10" text-anchor="end">Branch Base: #{log.code_commit_sha}</text>)

      # Output PR badges
      item[:prs].each_with_index do |pr_text, pidx|
        pr_x = x2 + 12
        pr_y = y + 10 + (pidx * 16)
        svg << %(<text x="#{pr_x.round(1)}" y="#{pr_y}" fill="#{COLORS[:text_primary]}" font-family="sans-serif" font-size="11" font-weight="600">🚀 PR #{pr_text}</text>)
      end
    end

    # Bottom annotation
    svg << %(<rect x="30" y="#{height - 45}" width="#{width - 60}" height="32" rx="4" fill="#{COLORS[:card_bg]}" stroke="#{COLORS[:border]}"/>)
    svg << %(<text x="45" y="#{height - 25}" fill="#{COLORS[:accent_green]}" font-family="monospace" font-size="12">✅ UAT Invariant Validated: FL006 and FL007 shared starting commit 4a2f81a and produced parallel PRs independently resolving overlapping step friction.</text>)

    svg << %(</svg>)
    svg.join("\n")
  end

  def render_step_durations_svg
    width = 1100
    height = 500
    chart_left = 120
    chart_bottom = height - 80
    chart_top = 80
    chart_h = chart_bottom - chart_top
    col_width = 90
    spacing = 30

    svg = []
    svg << %(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 #{width} #{height}" width="#{width}" height="#{height}">)
    svg << render_svg_defs
    svg << %(<rect width="100%" height="100%" fill="#{COLORS[:bg]}"/>)

    # Title
    svg << %(<text x="30" y="40" fill="#{COLORS[:text_primary]}" font-family="system-ui, sans-serif" font-size="22" font-weight="700">⏱️ Active Resolution Time by Workshop Step (Steps 0–8)</text>)
    svg << %(<text x="30" y="64" fill="#{COLORS[:text_secondary]}" font-family="system-ui, sans-serif" font-size="13">Demonstrating step-by-step resolution speedup across iterations (in minutes).</text>)

    # Y-axis ticks (0 to 240 minutes)
    max_min = 240
    (0..4).each do |i|
      val = i * 60
      y = chart_bottom - (chart_h * val / max_min.to_f)
      svg << %(<line x1="#{chart_left}" y1="#{y}" x2="#{width - 240}" y2="#{y}" stroke="#{COLORS[:border]}" stroke-dasharray="3,3"/>)
      svg << %(<text x="#{chart_left - 10}" y="#{y + 4}" fill="#{COLORS[:text_secondary]}" font-family="monospace" font-size="11" text-anchor="end">#{val}m</text>)
    end

    # Stacked Bars per FL
    @logs.each_with_index do |log, idx|
      x = chart_left + 20 + (idx * (col_width + spacing))

      current_y = chart_bottom
      (0..8).each do |step_num|
        st = log.step(step_num)
        dur_min = (st["duration_seconds"].to_i / 60.0)
        seg_h = chart_h * (dur_min / max_min.to_f)
        seg_y = current_y - seg_h
        col = COLORS[:step_palette][step_num]

        if seg_h > 0
          svg << %(<rect x="#{x}" y="#{seg_y.round(1)}" width="#{col_width}" height="#{seg_h.round(1)}" fill="#{col}">)
          svg << %(<title>#{CGI.escapeHTML("#{STEP_NAMES[step_num]}: #{dur_min.round(1)}m (#{st['status']})")}</title>)
          svg << %(</rect>)
        end
        current_y = seg_y
      end

      # Total text on top
      total_m = (log.active_duration_seconds / 60.0).round
      svg << %(<text x="#{x + (col_width / 2.0)}" y="#{current_y - 6}" fill="#{COLORS[:text_primary]}" font-family="monospace" font-size="11" font-weight="bold" text-anchor="middle">#{total_m}m</text>)

      # X label
      svg << %(<text x="#{x + (col_width / 2.0)}" y="#{chart_bottom + 20}" fill="#{COLORS[:accent_blue]}" font-family="monospace" font-size="13" font-weight="bold" text-anchor="middle">#{log.id}</text>)
      svg << %(<text x="#{x + (col_width / 2.0)}" y="#{chart_bottom + 36}" fill="#{COLORS[:text_secondary]}" font-family="sans-serif" font-size="10" text-anchor="middle">#{log.runner.sub('antigravity-', 'agy-')}</text>)
    end

    # Legend on right side
    leg_x = width - 210
    leg_y = 100
    svg << %(<g transform="translate(#{leg_x}, #{leg_y})">)
    svg << %(<text x="0" y="0" fill="#{COLORS[:text_primary]}" font-family="sans-serif" font-size="12" font-weight="bold">Workshop Steps</text>)
    STEP_NAMES.each_with_index do |name, i|
      sy = 20 + (i * 22)
      svg << %(<rect x="0" y="#{sy - 10}" width="12" height="12" rx="2" fill="#{COLORS[:step_palette][i]}"/>)
      svg << %(<text x="18" y="#{sy}" fill="#{COLORS[:text_secondary]}" font-family="sans-serif" font-size="11">#{name.split(':').first}</text>)
    end
    svg << %(</g>)

    svg << %(</svg>)
    svg.join("\n")
  end

  def render_bug_trends_svg
    width = 1000
    height = 400
    chart_left = 100
    chart_right = width - 40
    chart_w = chart_right - chart_left
    chart_bottom = height - 70
    chart_top = 80
    chart_h = chart_bottom - chart_top

    svg = []
    svg << %(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 #{width} #{height}" width="#{width}" height="#{height}">)
    svg << render_svg_defs
    svg << %(<rect width="100%" height="100%" fill="#{COLORS[:bg]}"/>)

    # Title
    svg << %(<text x="30" y="40" fill="#{COLORS[:text_primary]}" font-family="system-ui, sans-serif" font-size="22" font-weight="700">🐛 Bugs Uncovered &amp; Triage Volume across Iterations</text>)
    svg << %(<text x="30" y="64" fill="#{COLORS[:text_secondary]}" font-family="system-ui, sans-serif" font-size="13">Evolution of frictions logged and resolved per Friction Log run.</text>)

    max_bugs = 25
    (0..5).each do |i|
      val = i * 5
      y = chart_bottom - (chart_h * val / max_bugs.to_f)
      svg << %(<line x1="#{chart_left}" y1="#{y}" x2="#{chart_right}" y2="#{y}" stroke="#{COLORS[:border]}" stroke-dasharray="3,3"/>)
      svg << %(<text x="#{chart_left - 10}" y="#{y + 4}" fill="#{COLORS[:text_secondary]}" font-family="monospace" font-size="11" text-anchor="end">#{val}</text>)
    end

    points = []
    bar_w = 40
    @logs.each_with_index do |log, idx|
      cx = chart_left + (chart_w * (idx + 0.5) / @logs.size.to_f)
      by = chart_bottom - (chart_h * log.bugs_found_count / max_bugs.to_f)
      bh = chart_bottom - by

      # Bar
      svg << %(<rect x="#{cx - (bar_w / 2.0)}" y="#{by}" width="#{bar_w}" height="#{bh}" rx="4" fill="#{COLORS[:accent_red]}" opacity="0.75"/>)
      svg << %(<text x="#{cx}" y="#{by - 8}" fill="#{COLORS[:accent_red]}" font-family="monospace" font-size="13" font-weight="bold" text-anchor="middle">#{log.bugs_found_count}</text>)

      # X label
      svg << %(<text x="#{cx}" y="#{chart_bottom + 22}" fill="#{COLORS[:accent_blue]}" font-family="monospace" font-size="13" font-weight="bold" text-anchor="middle">#{log.id}</text>)
      points << [cx, by]
    end

    # Line overlay connecting tops
    polyline = points.map { |x, y| "#{x.round(1)},#{y.round(1)}" }.join(" ")
    svg << %(<polyline points="#{polyline}" fill="none" stroke="#{COLORS[:accent_yellow]}" stroke-width="2.5"/>)
    points.each do |x, y|
      svg << %(<circle cx="#{x.round(1)}" cy="#{y.round(1)}" r="4" fill="#{COLORS[:accent_yellow]}"/>)
    end

    svg << %(</svg>)
    svg.join("\n")
  end

  def render_html_dashboard
    <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Friction Log Telemetry &amp; Retrospective (FL000–FL007)</title>
        <style>
          :root {
            --bg: #0d1117;
            --card-bg: #161b22;
            --border: #30363d;
            --text-primary: #f0f6fc;
            --text-secondary: #8b949e;
            --accent-blue: #58a6ff;
            --accent-green: #3fb950;
            --accent-yellow: #d29922;
            --accent-red: #f85149;
          }
          body {
            margin: 0;
            padding: 30px 20px;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            background-color: var(--bg);
            color: var(--text-primary);
            line-height: 1.5;
          }
          .container {
            max-width: 1200px;
            margin: 0 auto;
          }
          h1, h2, h3 {
            color: var(--text-primary);
          }
          .header {
            margin-bottom: 30px;
            border-bottom: 1px solid var(--border);
            padding-bottom: 20px;
          }
          .badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
            margin-right: 6px;
          }
          .badge-green { background: #238636; color: #fff; }
          .badge-blue { background: #1f6feb; color: #fff; }
          .badge-yellow { background: #9e6a03; color: #fff; }
          .badge-red { background: #da3633; color: #fff; }
          .card {
            background: var(--card-bg);
            border: 1px solid var(--border);
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 30px;
            overflow-x: auto;
          }
          table {
            width: 100%;
            border-collapse: collapse;
            font-size: 13px;
          }
          th, td {
            text-align: left;
            padding: 10px 12px;
            border-bottom: 1px solid var(--border);
          }
          th {
            background-color: #21262d;
            color: var(--text-secondary);
            text-transform: uppercase;
            font-size: 11px;
            letter-spacing: 0.5px;
          }
          tr:hover {
            background-color: #1c2128;
          }
          a {
            color: var(--accent-blue);
            text-decoration: none;
          }
          a:hover {
            text-decoration: underline;
          }
          .chart-img {
            max-width: 100%;
            height: auto;
            border-radius: 6px;
          }
          .code-sha {
            font-family: monospace;
            background: #21262d;
            padding: 2px 6px;
            border-radius: 4px;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>📊 Friction Log Telemetry &amp; Retrospective (FL000–FL007)</h1>
            <p style="color: var(--text-secondary);">
              End-to-end operational telemetry, step bottlenecks, pause tracking, and Git provenance for the Rails 8 on Google Cloud workshop.
            </p>
            <div>
              <span class="badge badge-green">8 Total Runs</span>
              <span class="badge badge-blue">Zero-Branch Architecture</span>
              <span class="badge badge-yellow">Concurrent FL006 &amp; FL007 Validation</span>
            </div>
          </div>

          <div class="card">
            <h2>⏱️ Full Multi-Track Gantt Timeline</h2>
            #{render_gantt_svg}
          </div>

          <div class="card">
            <h2>⚡ Concurrency Overlap: FL006 vs FL007</h2>
            <p style="color: var(--text-secondary); font-size: 13px;">
              Both FL006 and FL007 initiated runs from the same codebase baseline (<span class="code-sha">4a2f81a</span>), paused in tandem over the weekend, and resumed Monday morning producing parallel PRs.
            </p>
            #{render_concurrency_svg}
          </div>

          <div class="card">
            <h2>⏱️ Step Duration Analysis &amp; Speedup Trend</h2>
            #{render_step_durations_svg}
          </div>

          <div class="card">
            <h2>🐛 Bug Evolution &amp; Friction Log Triage</h2>
            #{render_bug_trends_svg}
          </div>

          <div class="card">
            <h2>📋 Friction Log Master Scorecard</h2>
            <table>
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Title</th>
                  <th>Runner</th>
                  <th>GCP Project</th>
                  <th>Active / Wall Duration</th>
                  <th>Bugs</th>
                  <th>Eval Score</th>
                  <th>Provenance (Code / Workshop)</th>
                  <th>Links</th>
                </tr>
              </thead>
              <tbody>
                #{@logs.map { |log| render_table_row(log) }.join("\n")}
              </tbody>
            </table>
          </div>
        </div>
      </body>
      </html>
    HTML
  end

  private

  def render_table_row(log)
    status_badge = case log.status
                   when "success" then %(<span class="badge badge-green">success</span>)
                   when "blocked" then %(<span class="badge badge-red">blocked</span>)
                   else %(<span class="badge badge-yellow">#{log.status}</span>)
                   end

    dur_str = "#{(log.active_duration_seconds / 60.0).round}m"
    dur_str += " / #{(log.wall_clock_duration_seconds / 3600.0).round}h wall" if log.paused?

    pr_links = log.pr_urls.map do |url|
      pr_num = url.split('/').last
      %(<a href="#{url}" target="_blank">##{pr_num}</a>)
    end.join(", ")
    pr_links = "—" if pr_links.empty?

    ghi_num = log.ghi_url.split('/').last
    ghi_link = %(<a href="#{log.ghi_url}" target="_blank">##{ghi_num}</a>)

    <<~ROW
      <tr>
        <td><strong>#{log.id}</strong> #{status_badge}</td>
        <td>#{CGI.escapeHTML(log.title)}</td>
        <td>#{log.runner}</td>
        <td><span class="code-sha">#{log.gcp_project_id}</span></td>
        <td>#{dur_str}</td>
        <td><strong>#{log.bugs_found_count}</strong></td>
        <td>#{log.eval_score}</td>
        <td>
          Code: <span class="code-sha">#{log.code_commit_sha}</span><br>
          Workshop: <span class="code-sha">#{log.workshop_commit_sha}</span>
        </td>
        <td>Issue: #{ghi_link}<br>PRs: #{pr_links}</td>
      </tr>
    ROW
  end

  def render_svg_defs
    <<~DEFS
      <defs>
        <linearGradient id="active-grad-green" x1="0%" y1="0%" x2="100%" y2="0%">
          <stop offset="0%" stop-color="#34a853"/>
          <stop offset="100%" stop-color="#2bb24c"/>
        </linearGradient>
        <linearGradient id="active-grad-blue" x1="0%" y1="0%" x2="100%" y2="0%">
          <stop offset="0%" stop-color="#4285f4"/>
          <stop offset="100%" stop-color="#1a73e8"/>
        </linearGradient>
        <pattern id="pause-pattern" width="8" height="8" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
          <line x1="0" y1="0" x2="0" y2="8" stroke="#{COLORS[:accent_yellow]}" stroke-width="2.5" opacity="0.8"/>
        </pattern>
      </defs>
    DEFS
  end
end
