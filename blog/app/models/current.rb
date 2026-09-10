class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :trace_id
  delegate :user, to: :session, allow_nil: true
end
