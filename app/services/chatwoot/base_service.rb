# frozen_string_literal: true

# Domain surface for Chatwoot account provisioning. One Chatwoot account per
# Skycom company (normal + system companies); the Chatwoot database is the
# second source of truth for chat data, maintained by Skycom (cleared +
# re-provisioned at seed time). No UI lives here — this service is plumbing.
# See docs/CHATWOOT.md.
module Chatwoot
  class BaseService
    # Chatwoot never reuses deleted account ids (Postgres serial), so the
    # dead-id prefix scanned by clear_all! grows with every reseed. This is
    # the consecutive-404 buffer before the scan stops.
    CLEAR_MISS_LIMIT = 500

    class << self
      # Idempotent: a reachable stored account short-circuits; a stale stored
      # id (404) falls through and re-provisions. Raises Chatwoot::Error on
      # transport/validation failure — Company#setup_chatwoot_account rescues.
      def create_account!(company:)
        return no_op_provisioning unless configured?

        if company.chatwoot_account_id.present?
          begin
            return Chatwoot::Client.get("accounts/#{company.chatwoot_account_id}")
          rescue Chatwoot::NotFoundError
            # Stored id is stale — re-provision below.
          end
        end

        account = Chatwoot::Client.post("accounts", body: account_payload(company))
        company.update!(chatwoot_account_id: account["id"])
        account
      end

      # Debug/verify hook: fetches the Chatwoot account corresponding to a
      # company. nil when the company has no stored id or the account is gone
      # (404/403); raises transport errors so failures stay visible.
      def account_for(company)
        raise Chatwoot::Error, "Chatwoot platform token is not configured" unless configured?
        return nil if company.chatwoot_account_id.blank?

        Chatwoot::Client.get("accounts/#{company.chatwoot_account_id}")
      rescue Chatwoot::NotFoundError
        nil
      end

      # Seed-time cleanup. No list-accounts endpoint exists (v3.12), so scan
      # ids 1.. upward: 200 → DELETE (async on Chatwoot's side), non-200 →
      # miss. Stops after CLEAR_MISS_LIMIT consecutive misses.
      def clear_all!
        return no_op_clearing unless configured?

        deleted = 0
        consecutive_misses = 0
        id = 0
        while consecutive_misses < CLEAR_MISS_LIMIT
          id += 1
          begin
            Chatwoot::Client.get("accounts/#{id}")
          rescue Chatwoot::NotFoundError, Chatwoot::UnauthorizedError
            consecutive_misses += 1
            next
          end

          consecutive_misses = 0
          Chatwoot::Client.delete("accounts/#{id}")
          deleted += 1
        end
        deleted
      end

      private

      def account_payload(company)
        {
          "name" => company.name,
          "custom_attributes" => { "skycom_company_id" => company.id }
        }
      end

      def configured?
        Chatwoot::Client.platform_token.present?
      end

      def no_op_provisioning
        Rails.logger.warn("[Chatwoot] CHATWOOT_PLATFORM_TOKEN is not set — skipping account provisioning")
        nil
      end

      def no_op_clearing
        Rails.logger.warn("[Chatwoot] CHATWOOT_PLATFORM_TOKEN is not set — skipping Chatwoot data clear")
        0
      end
    end
  end
end
