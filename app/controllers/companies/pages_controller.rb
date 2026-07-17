# app/controllers/companies/pages_controller.rb

class Companies::PagesController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.pages.includes(:branch)
        scope = scope.where(branch_id: params[:branch_id]) if params[:branch_id].present?

        render json: {
          pages: format_pages(scope),
          branches: current_company.branches.select(:id, :name).as_json
        }
      end
    end
  end

  def show
    page = current_company.pages.includes(:branch).find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { page: format_page(page) } }
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { branches: current_company.branches.select(:id, :name).as_json } }
    end
  end

  def retail_cashier
    page = current_company.pages.includes(:branch).find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        warehouse_ids = page.branch.warehouse_ids
        products = current_company.products.where(branch_id: page.branch_id).limit(50).map { |p|
          price = p.price
          stock = Stock.find_by(product_id: p.id, warehouse_id: warehouse_ids)
          { id: p.id, name: p.name, code: p.code, stock_id: stock&.id, price: price&.to_f || 0, currency: price&.currency.iso_code || "USD", image_url: p.image_attachments.first&.variant(:thumb)&.processed&.url }
        }
        services = current_company.services.where(branch_id: page.branch_id).limit(50).map { |s|
          { id: s.id, name: s.name, code: s.code, price: 0, currency: "usd", image_url: s.image_attachments.first&.variant(:thumb)&.processed&.url }
        }

        render json: {
          page: format_page(page),
          products: products,
          services: services
        }
      end
    end
  end

  def edit
    page = current_company.pages.includes(:branch).find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { page: format_page(page) } }
    end
  end

  def create
    page = current_company.pages.new(page_params)
    page.permission_resource_name = "Page"

    if page.save
      redirect_to company_page_path(current_company, page), notice: "Page created successfully."
    else
      redirect_to new_company_page_path(current_company),
        alert: page.errors.full_messages.to_sentence
    end
  end

  def update
    page = current_company.pages.find(params[:id])

    if page.update(page_params)
      redirect_to company_page_path(current_company, page), notice: "Page updated successfully."
    else
      redirect_to edit_company_page_path(current_company, page),
        alert: page.errors.full_messages.to_sentence
    end
  end

  private

  def page_params
    params.require(:page).permit(
      :name, :description, :branch_id, :target_role, :target_resolution,
      :business_type, :lifecycle_status, :workflow_status, metadata: {}
    )
  end

  def format_page(page)
    page.as_json(only: %i[
      id name code description target_role target_resolution
      business_type lifecycle_status workflow_status metadata
    ]).merge(
      branch: { id: page.branch_id, name: page.branch.name }
    )
  end

  def format_pages(pages)
    pages.map { |page| format_page(page) }
  end
end
