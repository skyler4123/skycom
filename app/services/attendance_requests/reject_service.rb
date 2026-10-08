# frozen_string_literal: true

# Reject an AttendanceRequest: stamps the decision, creates no AttendanceDay.
# Returns { success: true } | { success: false, errors: [...] }.
class AttendanceRequests::RejectService
  def self.call(request:, approver:, note: nil)
    new(request: request, approver: approver, note: note).call
  end

  def initialize(request:, approver:, note: nil)
    @request = request
    @approver = approver
    @note = note
  end

  def call
    return failure("Approver is required") if @approver.nil?
    unless @approver.can?(:update, @request)
      return failure("You are not authorized to update this record")
    end

    result = nil
    ActiveRecord::Base.transaction do
      @request.with_lock do
        if !@request.status_pending?
          result = failure("Request already decided")
        else
          @request.update!(
            status: :rejected,
            decided_by: @approver,
            decided_at: Time.current,
            decision_note: @note
          )
          result = { success: true }
        end
      end
    end
    result
  end

  private

  def failure(message)
    { success: false, errors: [ message ] }
  end
end
