# frozen_string_literal: true

# Cal.com webhook receiver. Cal.com (Docker) delivers booking lifecycle
# events to Rails (host) at RAILS_PUBLIC_URL + /webhooks/calendar/cal_com.
# Verifies X-Cal-Signature-256 (HMAC-SHA256 vs CALCOM_WEBHOOK_SECRET),
# then enqueues CalendarSyncJob so the response stays a fast 200 OK.
# Docs: docs/CALENDAR.md, docs/WEBSOCKET.md
module Webhooks
  module Calendar
    class CalComController < ActionController::Base
      skip_before_action :verify_authenticity_token
      before_action :ensure_not_production_without_secret

      def create
        unless valid_signature?
          return render json: { errors: [ "Invalid signature" ] }, status: :unauthorized
        end

        CalendarSyncJob.perform_later(
          company_id: params[:company_id],
          payload: webhook_payload
        )

        head :ok
      end

      private

      def valid_signature?
        received = request.headers["X-Cal-Signature-256"].to_s
        return false if received.blank?

        # Dev fallback: plain shared secret (curl without HMAC).
        return true if ActiveSupport::SecurityUtils.secure_compare(received, CALCOM_WEBHOOK_SECRET)

        expected = OpenSSL::HMAC.hexdigest("SHA256", CALCOM_WEBHOOK_SECRET, request.raw_post)
        ActiveSupport::SecurityUtils.secure_compare(received, expected)
      rescue StandardError
        false
      end

      def webhook_payload
        params.permit!.to_h.slice("triggerEvent", "payload")
      end

      def ensure_not_production_without_secret
        return unless Rails.env.production?
        return if ENV["CALCOM_WEBHOOK_SECRET"].present?

        render json: { errors: [ "Calendar webhook not configured" ] }, status: :not_found
      end
    end
  end
end
