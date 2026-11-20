class Current < ActiveSupport::CurrentAttributes
  attribute :session
  # Trace of the current request, set by CloudTraceContext and written into every
  # structured log line by GoogleJsonFormatter (workshop Step 8, Quest 2).
  attribute :trace_id, :span_id, :trace_sampled
  delegate :user, to: :session, allow_nil: true
end
