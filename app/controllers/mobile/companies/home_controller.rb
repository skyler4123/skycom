# frozen_string_literal: true

# Mobile::Companies::HomeController — Shell-First employee dashboard. The shell
# hydrates the punch card, monthly stats, quick actions, company notice and
# today's activity from .json. Check-in is a native form POST to Attendances.
# Serves Stimulus: Mobile_Companies_Home_IndexController
# Endpoints: GET /mobile/companies/:company_id/home(.json)
# Docs: docs/MOBILE.md §2-§4
class Mobile::Companies::HomeController < Mobile::Companies::BaseController
  def index
    @companies = cached_mobile_companies
    @company_utc_offset = company_utc_offset
    company_now = Time.current.getlocal(@company_utc_offset)
    company_today = company_now.to_date

    @attendance_month = @employee.attendance_months.find_by(month: company_today.beginning_of_month)
    @today_shift = @employee.scheduled_shifts.find_by(work_date: company_today)
    @today_logs = @employee.attendance_logs.includes(:branch).where(logged_at: company_now.all_day).order(:logged_at).to_a
    @check_in_logs = @today_logs.select(&:log_type_check_in?)
    @checked_in = @check_in_logs.any?
    @pending_requests_count = AttendanceRequest.where(employee: @employee, status: :pending).count
    @attendance_balance = AttendanceBalance.for(employee: @employee, year: company_today.year)
    @announcement = @employee.documents.announcements.published.order(updated_at: :desc).first

    respond_to do |format|
      format.html do
        @page_title = "Home"
        render_mobile_shell(json_url: mobile_company_home_path(@company, format: :json))
      end
      format.json { render json: home_payload }
    end
  end

  private

  def home_payload
    {
      employee: {
        id: @employee.id,
        name: @employee.name,
        code: @employee.code,
        branch: @employee.branch && { id: @employee.branch.id, name: @employee.branch.name }
      },
      company: { id: @company.id, name: @company.name, utc_offset: @company_utc_offset },
      companies: @companies,
      checked_in: @checked_in,
      today_shift: @today_shift && {
        expected_start_at: @today_shift.expected_start_at,
        expected_end_at: @today_shift.expected_end_at
      },
      check_in_logs: @check_in_logs.map { |log| { logged_at: log.logged_at } },
      today_logs: @today_logs.map do |log|
        {
          log_type: log.log_type,
          logged_at: log.logged_at,
          branch_name: log.branch&.name || @employee.branch&.name || @company.name
        }
      end,
      attendance_month: @attendance_month && {
        total_records: @attendance_month.total_records.to_i,
        total_present_days: @attendance_month.total_present_days.to_i,
        total_overtime_minutes: @attendance_month.total_overtime_minutes.to_i
      },
      attendance_balance: {
        remaining_days: @attendance_balance.remaining_days.to_i,
        pending_days: @attendance_balance.pending_days.to_i
      },
      pending_requests_count: @pending_requests_count,
      announcement: @announcement && {
        name: @announcement.name,
        description: @announcement.description
      }
    }
  end

  def cached_mobile_companies
    Rails.sync_cache.fetch(
      CacheKeyService.user_mobile_companies(
        current_user.id,
        version: current_user.mobile_companies_cache_version
      ),
      expires_in: CACHE_DEFAULT_EXPIRY
    ) do
      current_user.employees.includes(:company)
                  .sort_by { |employee| employee.company.name.to_s }
                  .map { |employee| { "id" => employee.company.id, "name" => employee.company.name } }
    end
  end
end
