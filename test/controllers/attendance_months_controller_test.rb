require "test_helper"

class AttendanceMonthsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @attendance_month = attendance_months(:one)
  end

  test "should get index" do
    get attendance_months_url
    assert_response :success
  end

  test "should get new" do
    get new_attendance_month_url
    assert_response :success
  end

  test "should create attendance_month" do
    assert_difference("AttendanceMonth.count") do
      post attendance_months_url, params: { attendance_month: { company_id: @attendance_month.company_id, branch_id: @attendance_month.branch_id, customer_id: @attendance_month.customer_id, logable_id: @attendance_month.logable_id, logable_type: @attendance_month.logable_type, period_id: @attendance_month.period_id } }
    end

    assert_redirected_to attendance_month_url(AttendanceMonth.last)
  end

  test "should show attendance_month" do
    get attendance_month_url(@attendance_month)
    assert_response :success
  end

  test "should get edit" do
    get edit_attendance_month_url(@attendance_month)
    assert_response :success
  end

  test "should update attendance_month" do
    patch attendance_month_url(@attendance_month), params: { attendance_month: { company_id: @attendance_month.company_id, branch_id: @attendance_month.branch_id, customer_id: @attendance_month.customer_id, logable_id: @attendance_month.logable_id, logable_type: @attendance_month.logable_type, period_id: @attendance_month.period_id } }
    assert_redirected_to attendance_month_url(@attendance_month)
  end

  test "should destroy attendance_month" do
    assert_difference("AttendanceMonth.count", -1) do
      delete attendance_month_url(@attendance_month)
    end

    assert_redirected_to attendance_months_url
  end
end
