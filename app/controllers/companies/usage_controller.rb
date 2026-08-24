# frozen_string_literal: true

# Companies::UsageController — Usage dashboard (hot-path aware).
# Shell-first GET /companies/:id/usage: HTML shell + JSON with wallet snapshot +
# 7-day daily totals (CompanyDailyUsage, app/models/company_daily_usage.rb:9) +
# live Redis delta (company.credit_usage_delta, app/models/company.rb:154 kredis_counter) +
# monthly total (CompanyMonthlyUsage, app/models/company_monthly_usage.rb:9).
# today_total = DB total_credits + live_delta per docs/ATOMIC_PURPOSE.md Hot Path Rule;
# past days = DB only. Usage is metered by CompanyCreditDeduction::* →
# record_credit_usage! and drained by CompanyUsageSyncJob
# (app/jobs/company_usage_sync_job.rb:30).
#
# Opt-in detail logging (docs/ATOMIC_PURPOSE.md — live credit inspection):
# POST .../usage/enable_logging opens a short recording window on the wallet
# (CompanyWallet#enable_usage_logging!), POST .../usage/disable_logging closes it.
# While active, show also returns that window's CompanyUsageLog rows.
class Companies::UsageController < Companies::ApplicationController
  # Single-file constant: max detail rows returned for the active window.
  USAGE_LOGS_LIMIT = 50

  def show
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        wallet = current_company.company_wallet
        today = Time.current.to_date
        days = (6.days.ago.to_date..today).to_a
        rows = CompanyDailyUsage.where(company: current_company, usage_date: days).index_by(&:usage_date)
        live_delta = current_company.credit_usage_delta
        monthly = CompanyMonthlyUsage.find_by(company: current_company, usage_month: today.beginning_of_month)

        daily_usage = days.map do |date|
          total = rows[date]&.total_credits.to_i
          total += live_delta if date == today
          { date: date.to_s, total_credits: total }
        end

        render json: {
          wallet: {
            main_credit_balance: wallet&.main_credit_balance || 0,
            promo_credit_balance: wallet&.promo_credit_balance || 0,
            debt_credit_balance: wallet&.debt_credit_balance || 0,
            currency: current_company.currency
          },
          daily_usage: daily_usage,
          today_total: daily_usage.last[:total_credits],
          live_delta: live_delta,
          monthly_total: monthly&.total_credits.to_i,
          usage_logging: usage_logging_payload(wallet),
          usage_logs: active_window_logs(wallet)
        }
      end
    end
  end

  def enable_logging
    wallet = current_company.company_wallet
    return render_wallet_missing unless wallet

    wallet.enable_usage_logging!
    render json: {
      message: "Usage logging started — recording credit movements for #{CompanyWallet::USAGE_LOGGING_WINDOW / 60} minutes",
      usage_logging: usage_logging_payload(wallet)
    }
  end

  def disable_logging
    wallet = current_company.company_wallet
    return render_wallet_missing unless wallet

    wallet.disable_usage_logging!
    render json: {
      message: "Usage logging stopped",
      usage_logging: usage_logging_payload(wallet)
    }
  end

  private

  def usage_logging_payload(wallet)
    until_time = wallet&.usage_logging_until
    active = wallet.present? && wallet.usage_logging_active?
    {
      active: active,
      until: until_time&.iso8601,
      seconds_remaining: active ? ((until_time - Time.current).ceil).clamp(0, nil) : 0
    }
  end

  # Detail rows exist only inside the active window — once it closes (or is
  # stopped) the table falls back to an empty layout.
  def active_window_logs(wallet)
    return [] unless wallet&.usage_logging_active?

    window_start = wallet.usage_logging_until - CompanyWallet::USAGE_LOGGING_WINDOW
    wallet.company_usage_logs
      .where(created_at: window_start..)
      .order(created_at: :desc)
      .limit(USAGE_LOGS_LIMIT)
      .map { |log| format_usage_log(log) }
  end

  def format_usage_log(log)
    {
      id: log.id,
      action_type: log.action_type,
      change_amount: log.change_amount,
      balance_after: log.balance_after,
      description: log.description,
      created_at: log.created_at.iso8601
    }
  end

  def render_wallet_missing
    render json: { errors: [ "Wallet not found" ] }, status: :unprocessable_content
  end
end
