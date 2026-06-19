# app/controllers/companies/stock_exports_controller.rb

class Companies::StockExportsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.stock_exports.includes(:product, :branch, :category)
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?

        @pagy, @exports_results = pagy(:offset, scope, jsonapi: true)

        render json: {
          stock_exports: format_stock_exports(@exports_results),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  private

  def format_stock_export(export)
    export.as_json(only: [
      :id, :name, :code, :quantity,
      :business_type, :lifecycle_status, :workflow_status,
      :created_at, :updated_at
    ]).merge(
      product_name: export.product&.name,
      branch_name: export.branch&.name,
      category_name: export.category&.name,
      from_name: format_polymorphic_name(export.appoint_from),
      to_name: format_polymorphic_name(export.appoint_to)
    )
  end

  def format_stock_exports(exports)
    exports.map { |e| format_stock_export(e) }
  end

  def format_polymorphic_name(obj)
    return nil unless obj
    obj.try(:name) || obj.try(:title) || "#{obj.class.name}##{obj.id}"
  end
end
