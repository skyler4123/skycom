# app/controllers/companies/stock_transfers_controller.rb

class Companies::StockTransfersController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.stock_transfers.includes(:product, :branch, :category)
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?

        @pagy, @transfers_results = pagy(:offset, scope, jsonapi: true)

        render json: {
          stock_transfers: format_stock_transfers(@transfers_results),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  private

  def format_stock_transfer(transfer)
    transfer.as_json(only: [
      :id, :name, :code, :quantity,
      :business_type, :lifecycle_status, :workflow_status,
      :created_at, :updated_at
    ]).merge(
      product_name: transfer.product&.name,
      branch_name: transfer.branch&.name,
      category_name: transfer.category&.name,
      from_name: format_polymorphic_name(transfer.appoint_from),
      to_name: format_polymorphic_name(transfer.appoint_to)
    )
  end

  def format_stock_transfers(transfers)
    transfers.map { |t| format_stock_transfer(t) }
  end

  def format_polymorphic_name(obj)
    return nil unless obj
    obj.try(:name) || obj.try(:title) || "#{obj.class.name}##{obj.id}"
  end
end
