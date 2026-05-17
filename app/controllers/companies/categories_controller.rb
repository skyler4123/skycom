# app/controllers/companies/categories_controller.rb

class Companies::CategoriesController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.categories
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
    category = current_company.categories.find(params[:id])

    respond_to do |format|
      format.json do
        if category.update(category_params)
          render json: { category: format_category(category) }, status: :created
        else
          render json: { errors: category.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    render json: { status: "error", message: "Category not found" }, status: :not_found
  end

  def show
    category = current_company.categories.find(params[:id])

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
    params.require(:category).permit(
      :name,
      :description,
      :resource_name,
      :property_string_1,
      :property_string_2,
      :property_string_3,
      :property_string_4,
      :property_string_5,
      :property_string_6,
      :property_string_7,
      :property_string_8,
      :property_string_9,
      :property_string_10,
      :property_string_11,
      :property_string_12,
      :property_string_13,
      :property_string_14,
      :property_string_15,
      :property_string_16,
      :property_string_17,
      :property_string_18,
      :property_string_19,
      :property_string_20,
      :property_text_1,
      :property_text_2,
      :property_text_3,
      :property_text_4,
      :property_text_5,
      :property_integer_1,
      :property_integer_2,
      :property_integer_3,
      :property_integer_4,
      :property_integer_5,
      :property_integer_6,
      :property_integer_7,
      :property_integer_8,
      :property_integer_9,
      :property_integer_10,
      :property_integer_11,
      :property_integer_12,
      :property_integer_13,
      :property_integer_14,
      :property_integer_15,
      :property_integer_16,
      :property_integer_17,
      :property_integer_18,
      :property_integer_19,
      :property_integer_20,
      :property_decimal_1,
      :property_decimal_2,
      :property_decimal_3,
      :property_decimal_4,
      :property_decimal_5,
      :property_decimal_6,
      :property_decimal_7,
      :property_decimal_8,
      :property_decimal_9,
      :property_decimal_10,
      :property_boolean_1,
      :property_boolean_2,
      :property_boolean_3,
      :property_boolean_4,
      :property_boolean_5,
      :property_boolean_6,
      :property_boolean_7,
      :property_boolean_8,
      :property_boolean_9,
      :property_boolean_10,
      :property_boolean_11,
      :property_boolean_12,
      :property_boolean_13,
      :property_boolean_14,
      :property_boolean_15,
      :property_boolean_16,
      :property_boolean_17,
      :property_boolean_18,
      :property_boolean_19,
      :property_boolean_20,
      :property_datetime_1,
      :property_datetime_2,
      :property_datetime_3,
      :property_datetime_4,
      :property_datetime_5,
      :property_datetime_6,
      :property_datetime_7,
      :property_datetime_8,
      :property_datetime_9,
      :property_datetime_10
    )
  end

  def format_category(category)
    category.as_json(only: [
      :id, :name, :description, :resource_name,
      :property_string_1, :property_string_2, :property_string_3, :property_string_4, :property_string_5,
      :property_string_6, :property_string_7, :property_string_8, :property_string_9, :property_string_10,
      :property_string_11, :property_string_12, :property_string_13, :property_string_14, :property_string_15,
      :property_string_16, :property_string_17, :property_string_18, :property_string_19, :property_string_20,
      :property_text_1, :property_text_2, :property_text_3, :property_text_4, :property_text_5,
      :property_integer_1, :property_integer_2, :property_integer_3, :property_integer_4, :property_integer_5,
      :property_integer_6, :property_integer_7, :property_integer_8, :property_integer_9, :property_integer_10,
      :property_integer_11, :property_integer_12, :property_integer_13, :property_integer_14, :property_integer_15,
      :property_integer_16, :property_integer_17, :property_integer_18, :property_integer_19, :property_integer_20,
      :property_decimal_1, :property_decimal_2, :property_decimal_3, :property_decimal_4, :property_decimal_5,
      :property_decimal_6, :property_decimal_7, :property_decimal_8, :property_decimal_9, :property_decimal_10,
      :property_boolean_1, :property_boolean_2, :property_boolean_3, :property_boolean_4, :property_boolean_5,
      :property_boolean_6, :property_boolean_7, :property_boolean_8, :property_boolean_9, :property_boolean_10,
      :property_boolean_11, :property_boolean_12, :property_boolean_13, :property_boolean_14, :property_boolean_15,
      :property_boolean_16, :property_boolean_17, :property_boolean_18, :property_boolean_19, :property_boolean_20,
      :property_datetime_1, :property_datetime_2, :property_datetime_3, :property_datetime_4, :property_datetime_5,
      :property_datetime_6, :property_datetime_7, :property_datetime_8, :property_datetime_9, :property_datetime_10,
      :created_at, :updated_at
    ])
  end

  def format_categories(categories)
    categories.map { |category| format_category(category) }
  end
end
