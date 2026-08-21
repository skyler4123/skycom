# frozen_string_literal: true

class Companies::UsageController < Companies::ApplicationController
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
          monthly_total: monthly&.total_credits.to_i
        }
      end
    end
  end
end
