# app/controllers/companies/stock_imports_controller.rb

class Companies::StockImportsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.stock_imports.includes(:product, :branch)
        scope = scope.where(business_type: params[:business_type]) if params[:business_type].present?
        scope = scope.where(workflow_status: params[:workflow_status]) if params[:workflow_status].present?

        if params[:search].present?
          scope = scope.where("code ILIKE ?", "%#{params[:search]}%")
        end

        @pagy, @imports_results = pagy(:offset, scope, jsonapi: true)

        render json: {
          stock_imports: format_stock_imports(@imports_results),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  private

  def format_stock_import(import)
    import.as_json(only: [
      :id, :name, :code, :quantity,
      :business_type, :lifecycle_status, :workflow_status,
      :created_at, :updated_at
    ]).merge(
      product_name: import.product&.name,
      branch_name: import.branch&.name,
      from_name: format_polymorphic_name(import.appoint_from),
      to_name: format_polymorphic_name(import.appoint_to)
    )
  end

  def format_stock_imports(imports)
    imports.map { |i| format_stock_import(i) }
  end

  def format_polymorphic_name(obj)
    return nil unless obj
    obj.try(:name) || obj.try(:title) || "#{obj.class.name}##{obj.id}"
  end
end
