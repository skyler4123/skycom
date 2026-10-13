# app/controllers/admin/promo_campaigns_controller.rb
#
# Admin promo-credit campaigns (Shell-First). Global scope — there is NO
# current_company here; Admin::ApplicationController gates on
# super_admin/admin instead of Pundit. Create/update follow the HTML-redirect
# pattern (Admin precedent: payment_methods); run_now/cancel return JSON
# (Admin precedent: company_tickets member actions).
# Serves Stimulus: Admin_PromoCampaigns_IndexController (list JSON),
#                  Admin_PromoCampaigns_NewController (create form),
#                  Admin_PromoCampaigns_ShowController (detail + grants JSON),
#                  Admin_PromoCampaigns_EditController (edit form)
# Endpoints: GET /admin/promo_campaigns(.json),
#            GET /admin/promo_campaigns/:id(.json),
#            POST /admin/promo_campaigns(.json), PATCH /admin/promo_campaigns/:id(.json),
#            POST /admin/promo_campaigns/:id/run_now(.json),
#            POST /admin/promo_campaigns/:id/cancel(.json)
# Docs: docs/superpowers/specs/2026-10-12-admin-promo-credits-design.md
class Admin::PromoCampaignsController < Admin::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = PromoCampaign.order(created_at: :desc)
        scope = scope.where(status: params[:status]) if params[:status].present?
        @pagy, @results = pagy(:offset, scope, jsonapi: true)
        render json: {
          promo_campaigns: @results.map { |c| format_campaign(c) },
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def show
    campaign = PromoCampaign.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          promo_campaign: format_campaign(campaign),
          promo_grants: campaign.promo_grants.includes(:company).map { |g|
            g.as_json(only: [ :id, :company_id, :granted_amount, :promo_before, :promo_after, :created_at ])
              .merge(company_name: g.company&.name)
          }
        }
      end
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: {} }
    end
  end

  def edit
    campaign = PromoCampaign.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { promo_campaign: format_campaign(campaign) } }
    end
  end

  def create
    campaign = PromoCampaign.new(campaign_params)
    campaign.status = :scheduled

    respond_to do |format|
      if campaign.save
        schedule_job(campaign)
        format.html { redirect_to admin_promo_campaign_path(campaign), notice: "Promotion campaign created successfully" }
        format.json { render json: { promo_campaign: format_campaign(campaign) }, status: :created }
      else
        format.html { redirect_to new_admin_promo_campaign_path, alert: campaign.errors.full_messages.to_sentence }
        format.json { render json: { errors: campaign.errors.full_messages }, status: :unprocessable_content }
      end
    end
  end

  def update
    campaign = PromoCampaign.find(params[:id])

    respond_to do |format|
      if campaign.status_completed? || campaign.status_processing?
        format.html { redirect_to admin_promo_campaign_path(campaign), alert: "Campaign already processed" }
        format.json { render json: { errors: [ "Campaign already processed" ] }, status: :unprocessable_content }
      elsif campaign.update(campaign_params)
        schedule_job(campaign) if campaign.status_scheduled?
        format.html { redirect_to admin_promo_campaign_path(campaign), notice: "Promotion campaign updated successfully" }
        format.json { render json: { promo_campaign: format_campaign(campaign.reload) } }
      else
        format.html { redirect_to edit_admin_promo_campaign_path(campaign), alert: campaign.errors.full_messages.to_sentence }
        format.json { render json: { errors: campaign.errors.full_messages }, status: :unprocessable_content }
      end
    end
  end

  def run_now
    campaign = PromoCampaign.find(params[:id])
    result = PromoCampaigns::ExecuteService.call(campaign: campaign)

    if result[:success]
      render json: { promo_campaign: format_campaign(campaign.reload), stats: result.slice(:matched, :granted, :skipped, :failed) }
    else
      render json: { errors: result[:errors] }, status: :unprocessable_content
    end
  end

  def cancel
    campaign = PromoCampaign.find(params[:id])

    if campaign.status_draft? || campaign.status_scheduled?
      campaign.update!(status: :failed, stats: { "cancelled" => true })
      render json: { promo_campaign: format_campaign(campaign.reload) }
    else
      render json: { errors: [ "Campaign already processed" ] }, status: :unprocessable_content
    end
  end

  private

  def format_campaign(campaign)
    campaign.as_json(only: [
      :id, :name, :description, :amount, :max_cap, :conditions,
      :scheduled_at, :status, :processed_at, :stats, :created_at, :updated_at
    ])
  end

  def campaign_params
    base = params.require(:promo_campaign).permit(:name, :description, :amount, :max_cap, :scheduled_at)
    base[:conditions] = normalize_conditions(params[:promo_campaign][:conditions])
    base
  end

  def normalize_conditions(raw)
    return {} if raw.blank?

    hash = raw.to_unsafe_h
    out = {}
    # Pass unknown keys through verbatim so model validation rejects them
    # instead of silently dropping them.
    hash.each do |key, value|
      case key.to_s
      when "country"
        list = Array(value).flat_map { |v| v.to_s.split(",") }.map(&:strip).reject(&:blank?)
        out["country"] = list if value.present?
      when "business_type"
        list = Array(value).flat_map { |v| v.to_s.split(",") }.map(&:strip).reject(&:blank?)
        out["business_type"] = list if value.present?
      when "employee_count_min", "employee_count_max", "promo_balance_min", "promo_balance_max"
        out[key.to_s] = value.to_i if value.present?
      when "created_after", "created_before"
        out[key.to_s] = value.to_s if value.present?
      else
        out[key.to_s] = value
      end
    end
    out
  end

  def schedule_job(campaign)
    if campaign.scheduled_at.present? && campaign.scheduled_at > Time.current
      PromoCampaignJob.set(wait_until: campaign.scheduled_at).perform_later(campaign.id)
    else
      PromoCampaignJob.perform_later(campaign.id)
    end
  end
end
