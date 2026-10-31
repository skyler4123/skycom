# frozen_string_literal: true

# PromoCampaigns::MatcherService — translates a campaign's JSONB conditions
# into one Company scope. System companies never match.
module PromoCampaigns
  class MatcherService
    def self.call(campaign:)
      new(campaign: campaign).call
    end

    def initialize(campaign:)
      @campaign = campaign
      @conds = campaign.conditions || {}
    end

    def call
      # Background-job rule: suspended companies stay eligible (a promo can
      # reactivate them); disabled companies are skipped.
      scope = Company.where.not(business_type: :system).for_background_jobs
      if @conds["company_ids"].present?
        ids = Array(@conds["company_ids"]).map(&:to_s).select { |v|
          v.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)
        }
        return scope.where(id: ids)
      end
      scope = scope.where(country: Array(@conds["country"])) if @conds["country"].present?
      scope = scope.where(business_type: Array(@conds["business_type"])) if @conds["business_type"].present?
      scope = scope.where("employee_count >= ?", @conds["employee_count_min"].to_i) if @conds["employee_count_min"].present?
      scope = scope.where("employee_count <= ?", @conds["employee_count_max"].to_i) if @conds["employee_count_max"].present?
      scope = scope.where("companies.created_at >= ?", Time.zone.parse(@conds["created_after"].to_s)) if @conds["created_after"].present?
      scope = scope.where("companies.created_at <= ?", Time.zone.parse(@conds["created_before"].to_s)) if @conds["created_before"].present?

      if @conds["promo_balance_min"].present? || @conds["promo_balance_max"].present?
        scope = scope.joins(:company_wallet)
        scope = scope.where("company_wallets.promo_credit_balance >= ?", @conds["promo_balance_min"].to_i) if @conds["promo_balance_min"].present?
        scope = scope.where("company_wallets.promo_credit_balance <= ?", @conds["promo_balance_max"].to_i) if @conds["promo_balance_max"].present?
      end

      scope
    end
  end
end
