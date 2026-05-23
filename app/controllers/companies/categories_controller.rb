# app/controllers/companies/categories_controller.rb

class Companies::CategoriesController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.categories.includes(:property_mapping)
        scope = scope.where(resource_name: params[:resource_name]) if params[:resource_name].present?

        @pagy, @categories = pagy(:offset, scope, jsonapi: true)

        render json: {
          categories: format_categories(@categories),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def create
    category = current_company.categories.new(category_params)

    respond_to do |format|
      format.json do
        if category.save
          render json: { category: format_category(category) }, status: :created
        else
          render json: { errors: category.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end

  def update
    category = current_company.categories.includes(:property_mapping).find(params[:id])

    respond_to do |format|
      format.json do
        if category.update(category_params)
          render json: { category: format_category(category) }
        else
          render json: { errors: category.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    render json: { status: "error", message: "Category not found" }, status: :not_found
  end

  def show
    category = current_company.categories.includes(:property_mapping).find(params[:id])

    respond_to do |format|
      format.json do
        render json: { category: format_category(category) }
      end
    end
  rescue ActiveRecord::RecordNotFound
    render json: { status: "error", message: "Category not found" }, status: :not_found
  end

  private

  def category_params
    params.require(:category).permit(:name, :description, :resource_name)
  end

  def format_category(category)
    category.as_json(
      only: [ :id, :name, :description, :resource_name, :created_at, :updated_at ],
      include: :property_mapping
    )
  end

  def format_categories(categories)
    categories.map { |category| format_category(category) }
  end
end
