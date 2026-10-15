# frozen_string_literal: true

# PromoCampaigns::ExecuteService — runs one campaign to completion.
# Per matched company: grant = min(amount, max_cap - promo_before), skip when
# <= 0 (no row), else CompanyWallet#add_to!(:promo) (writes CompanyWalletLog)
# + PromoGrant row + owner notification (skipped companies: nothing).
# Idempotent: only draft/scheduled/failed execute; unique grant index guards retries.
#
# Returns { success:, matched:, granted:, skipped:, failed: } |
#         { success: false, errors: [...] }
module PromoCampaigns
  class ExecuteService
    # Single-file constant: tag auto-created per granted company for owner notify.
    PROMO_NOTIFICATION_TAG_NAME = "Skycom Promotions".freeze

    def self.call(campaign:)
      new(campaign: campaign).call
    end

    def initialize(campaign:)
      @campaign = campaign
    end

    def call
      @campaign.with_lock do
        unless %w[draft scheduled failed].include?(@campaign.status)
          return { success: false, errors: [ "Campaign already processed" ] }
        end

        # System transition: skip copy validations so legacy/defensive
        # blank title/body still executes using PROMO_DEFAULT_* fallback.
        @campaign.status = :processing
        @campaign.save!(validate: false)
      end

      matched = 0
      granted = 0
      skipped = 0
      failed = 0

      MatcherService.call(campaign: @campaign).find_each do |company|
        matched += 1
        outcome = grant_to(company)
        granted += 1 if outcome == :granted
        skipped += 1 if outcome == :skipped
        failed += 1 if outcome == :failed
      end

      @campaign.status = :completed
      @campaign.processed_at = Time.current
      @campaign.stats = { "matched" => matched, "granted" => granted, "skipped" => skipped, "failed" => failed }
      @campaign.save!(validate: false)
      { success: true, matched: matched, granted: granted, skipped: skipped, failed: failed }
    rescue StandardError => e
      begin
        @campaign.status = :failed
        @campaign.stats = { "error" => e.message }
        @campaign.save!(validate: false)
      rescue StandardError
        nil
      end
      { success: false, errors: [ e.message ] }
    end

    private

    def grant_to(company)
      return :skipped if PromoGrant.exists?(promo_campaign: @campaign, company: company)

      wallet = company.company_wallet
      return :failed if wallet.nil?

      promo_before = wallet.promo_credit_balance
      amount = [ @campaign.amount, @campaign.max_cap - promo_before ].min
      return :skipped if amount.nil? || amount <= 0

      wallet.add_to!(
        balance: :promo, amount: amount,
        source: @campaign,
        description: "Promo '#{@campaign.name}' grant",
        action_type: "promo_grant"
      )
      PromoGrant.create!(
        promo_campaign: @campaign, company: company,
        granted_amount: amount, promo_before: promo_before, promo_after: promo_before + amount
      )
      begin
        notify_owner(company, amount)
      rescue StandardError => e
        Rails.logger.warn("[PromoCampaigns::ExecuteService] notify failed for company #{company.id}: #{e.message}")
      end
      :granted
    rescue ActiveRecord::RecordNotUnique
      :skipped
    rescue StandardError => e
      Rails.logger.warn("[PromoCampaigns::ExecuteService] grant failed for company #{company.id}: #{e.message}")
      :failed
    end

    def notify_owner(company, amount)
      owner = company.employees.find_by(business_type: :owner)
      return if owner.nil?

      tag = NotificationTag.find_or_create_by!(company: company, name: PROMO_NOTIFICATION_TAG_NAME)
      EmployeeNotificationTagAppointment.find_or_create_by!(
        company: company, employee: owner, notification_tag: tag
      )
      Notifications::CreateService.call(
        company: company,
        name: resolve_title(amount),
        description: resolve_body(amount),
        tag_ids: [ tag.id ],
        severity: :info,
        throttle_key: "promo:#{@campaign.id}",
        throttle_window: 1.hour
      )
    end

    def resolve_title(amount)
      interpolate(@campaign.title.presence || PROMO_DEFAULT_TITLE, amount)
    end

    def resolve_body(amount)
      interpolate(@campaign.body.presence || PROMO_DEFAULT_BODY, amount)
    end

    def interpolate(template, amount)
      format(template, amount: amount, name: @campaign.name, max_cap: @campaign.max_cap)
    rescue StandardError
      template
    end
  end
end
