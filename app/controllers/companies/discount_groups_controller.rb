# app/controllers/companies/discount_groups_controller.rb
#
# Companies::DiscountGroupsController — discount campaign CRUD (BE-only Shell-First).
# A DiscountGroup owns the calculation config (fixed_amount | percentage), the
# budget (total_budget_cents / current_spent_cents) and the validity window.
# Codes are never created here — generate_codes bulk-inserts single-use codes
# via Discounts::BatchGenerator. current_spent_cents is service-owned and never
# permitted through create/update.
# Serves Stimulus: Companies_DiscountGroups_IndexController|NewController|ShowController|EditController
# Endpoints: GET/POST/PATCH/DELETE /companies/:company_id/discount_groups(.json),
#            POST /companies/:company_id/discount_groups/:id/generate_codes
# Docs: docs/DISCOUNTS.md
class Companies::DiscountGroupsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.discount_groups.includes(:discounts)
        @pagy, @discount_groups_results = pagy(:offset, scope, jsonapi: true)
        render json: { discount_groups: format_groups(@discount_groups_results), pagination: @pagy.data_hash }
      end
    end
  end

  def show
    group = current_company.discount_groups.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { discount_group: format_group(group) } }
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: {} }
    end
  end

  def edit
    group = current_company.discount_groups.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { discount_group: format_group(group) } }
    end
  end

  def create
    group = current_company.discount_groups.new(discount_group_params)

    respond_to do |format|
      if group.save
        format.html do
          redirect_to company_discount_group_path(current_company, group),
            notice: "Discount group created successfully"
        end
        format.json { render json: { discount_group: format_group(group) }, status: :created }
      else
        format.html do
          redirect_to new_company_discount_group_path(current_company),
            alert: group.errors.full_messages.to_sentence
        end
        format.json { render json: { errors: group.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def update
    group = current_company.discount_groups.find(params[:id])

    respond_to do |format|
      if group.update(discount_group_params)
        format.html do
          redirect_to company_discount_group_path(current_company, group),
            notice: "Discount group updated successfully."
        end
        format.json { render json: { discount_group: format_group(group) } }
      else
        format.html do
          redirect_to edit_company_discount_group_path(current_company, group),
            alert: group.errors.full_messages.to_sentence
        end
        format.json { render json: { errors: group.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    group = current_company.discount_groups.find(params[:id])
    group.destroy!
    redirect_to company_discount_groups_path(current_company), notice: "Discount group deleted."
  end

  # Bulk-generates single-use codes for the group (Discounts::BatchGenerator).
  def generate_codes
    group = current_company.discount_groups.find(params[:id])
    result = Discounts::BatchGenerator.call(
      discount_group: group,
      quantity: params[:quantity],
      code_length: params[:code_length].presence
    )

    if result[:success]
      render json: { message: "#{result[:generated]} discount codes generated", group: format_group(group.reload) }
    else
      render json: { errors: result[:errors] }, status: :unprocessable_entity
    end
  end

  private

  # current_spent_cents deliberately NOT permitted — owned by
  # Discounts::ApplyService/Discount#consume! (docs/DISCOUNTS.md §5).
  def discount_group_params
    params.require(:discount_group).permit(
      :name, :description, :prefix, :discount_type, :amount_cents, :percentage,
      :max_amount_cents, :total_budget_cents, :start_at, :end_at, :currency,
      :campaign_status
    )
  end

  def format_group(group)
    group.as_json(only: [
      :id, :name, :description, :code, :prefix, :discount_type,
      :amount_cents, :percentage, :max_amount_cents,
      :total_budget_cents, :current_spent_cents, :campaign_status,
      :start_at, :end_at, :currency,
      :lifecycle_status, :business_type, :created_at, :updated_at
    ]).merge(generated_codes_count: group.discounts.size)
  end

  def format_groups(groups)
    groups.map { |group| format_group(group) }
  end
end
