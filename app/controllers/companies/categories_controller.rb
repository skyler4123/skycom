class Companies::CategoriesController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.categories.includes(:property_mappings)
        scope = scope.where(resource_name: params[:resource_name]) if params[:resource_name].present?

        @pagy, @categories = pagy(:offset, scope, jsonapi: true)

        render json: {
          categories: format_categories(@categories),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def show
    category = current_company.categories.includes(:property_mappings).find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { category: format_category(category) } }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.json { render json: { status: "error", message: "Category not found" }, status: :not_found }
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: {} }
    end
  end

  def edit
    category = current_company.categories.includes(:property_mappings).find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { category: format_category(category) } }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.json { render json: { status: "error", message: "Category not found" }, status: :not_found }
    end
  end

  def create
    category = current_company.categories.new(category_params)

    if category.save
      redirect_to company_category_path(current_company, category), notice: "Category created successfully."
    else
      redirect_to new_company_category_path(current_company),
        alert: category.errors.full_messages.to_sentence
    end
  end

  def update
    category = current_company.categories.includes(:property_mappings).find(params[:id])

    if category.update(category_params)
      redirect_to company_category_path(current_company, category), notice: "Category updated successfully."
    else
      redirect_to edit_company_category_path(current_company, category),
        alert: category.errors.full_messages.to_sentence
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
      include: :property_mappings
    )
  end

  def format_categories(categories)
    categories.map { |category| format_category(category) }
  end
end
