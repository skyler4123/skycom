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
    return failure("Request is not pending") unless @request.status_pending?
    return failure("Approver is required") if @approver.nil?
    unless @approver.can?(:update, @request)
      return failure("You are not authorized to update this record")
    end

    @request.update!(
      status: :rejected,
      decided_by: @approver,
      decided_at: Time.current,
      decision_note: @note
    )

    { success: true }
  end

  private

  def failure(message)
    { success: false, errors: [ message ] }
  end
end
