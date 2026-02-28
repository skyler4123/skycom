require "test_helper"

class AttendanceLogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @attendance_log = attendance_logs(:one)
  end

  test "should get index" do
    get attendance_logs_url
    assert_response :success
  end

  test "should get new" do
    get new_attendance_log_url
    assert_response :success
  end

  test "should create attendance_log" do
    assert_difference("AttendanceLog.count") do
      post attendance_logs_url, params: { attendance_log: { company_id: @attendance_log.company_id, branch_id: @attendance_log.branch_id, customer_id: @attendance_log.customer_id, device_info: @attendance_log.device_info, id_address: @attendance_log.id_address, location: @attendance_log.location, logable_id: @attendance_log.logable_id, logable_type: @attendance_log.logable_type, notes: @attendance_log.notes, period_id: @attendance_log.period_id } }
    end

    assert_redirected_to attendance_log_url(AttendanceLog.last)
  end

  test "should show attendance_log" do
    get attendance_log_url(@attendance_log)
    assert_response :success
  end

  test "should get edit" do
    get edit_attendance_log_url(@attendance_log)
    assert_response :success
  end

  test "should update attendance_log" do
    patch attendance_log_url(@attendance_log), params: { attendance_log: { company_id: @attendance_log.company_id, branch_id: @attendance_log.branch_id, customer_id: @attendance_log.customer_id, device_info: @attendance_log.device_info, id_address: @attendance_log.id_address, location: @attendance_log.location, logable_id: @attendance_log.logable_id, logable_type: @attendance_log.logable_type, notes: @attendance_log.notes, period_id: @attendance_log.period_id } }
    assert_redirected_to attendance_log_url(@attendance_log)
  end

  test "should destroy attendance_log" do
    assert_difference("AttendanceLog.count", -1) do
      delete attendance_log_url(@attendance_log)
    end

    assert_redirected_to attendance_logs_url
  end
end
