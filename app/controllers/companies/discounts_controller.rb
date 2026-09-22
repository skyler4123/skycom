# app/controllers/companies/discounts_controller.rb
#
# Companies::DiscountsController — single-use discount code ledger (read-only BE API).
# Codes are created by Discounts::BatchGenerator (via DiscountGroups#generate_codes)
# and only their state moves through Discounts::ApplyService / Discount#consume! /
# #release! / #revert! — this controller has no mutations.
# Serves Stimulus: (embedded ledger in) Companies_DiscountGroups_ShowController
# Endpoints: GET /companies/:company_id/discounts(.json), GET .../discounts/:id(.json)
# Docs: docs/DISCOUNTS.md
class Companies::DiscountsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.discounts.includes(:discount_group, :order, :invoice, :customer)
        scope = scope.where(discount_group_id: params[:discount_group_id]) if params[:discount_group_id].present?
        scope = scope.where(status: params[:status]) if params[:status].present?

        @pagy, @discounts_results = pagy(:offset, scope, jsonapi: true)
        render json: { discounts: format_discounts(@discounts_results), pagination: @pagy.data_hash }
      end
    end
  end

  def show
    discount = current_company.discounts.includes(:discount_group, :order, :invoice, :customer).find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { discount: format_discount(discount) } }
    end
  end

  private

  def format_discount(discount)
    discount.as_json(only: [
      :id, :code, :status, :amount_cents, :used_at,
      :discount_group_id, :order_id, :invoice_id, :customer_id, :employee_id,
      :created_at, :updated_at
    ]).merge(
      discount_group: discount.discount_group&.as_json(only: [ :id, :name, :prefix, :discount_type ]),
      customer: discount.customer&.as_json(only: [ :id, :name ])
    )
  end

  def format_discounts(discounts)
    discounts.map { |discount| format_discount(discount) }
  end
end
