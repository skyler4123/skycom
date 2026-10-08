# app/controllers/companies/documents_controller.rb
#
# Documents dashboard API (Shell-First). index supports the same TableConfig-driven
# dynamic search/filter as Brands (?q= / ?filters[key]= → Meilisearch via
# Documents::SearchQueryService; plain DB path otherwise).
# Serves Stimulus: Companies_Documents_IndexController (index JSON incl. q/filters passthrough),
#                  Companies_Documents_NewController|ShowController|EditController
# Endpoints: GET /companies/:company_id/documents(.json) + nested CRUD — see config/routes.rb
# Docs: docs/DYNAMIC_TABLE.md §2.5, docs/MEILISEARCH.md
class Companies::DocumentsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.documents
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?

        search = Documents::SearchQueryService.new(company: current_company, params: params)
        scope = scope.where(id: search.record_ids).in_order_of(:id, search.record_ids) if search.active?

        @pagy, @documents_results = pagy(:offset, scope, jsonapi: true)

        render json: {
          documents: format_documents(@documents_results),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def show
    document = current_company.documents.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { document: format_document(document) } }
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: {} }
    end
  end

  def edit
    document = current_company.documents.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { document: format_document(document) } }
    end
  end

  def create
    document = current_company.documents.new(document_params)
    document.code ||= "DOC-#{SecureRandom.hex(4).upcase}"
    if document.save
      redirect_to company_document_path(current_company, document), notice: "Document created successfully"
    else
      redirect_to new_company_document_path(current_company),
        alert: document.errors.full_messages.to_sentence
    end
  end

  def update
    document = current_company.documents.find(params[:id])

    respond_to do |format|
      format.html do
        if document.update(document_params)
          redirect_to company_document_path(current_company, document), notice: "Document updated successfully."
        else
          redirect_to edit_company_document_path(current_company, document),
            alert: document.errors.full_messages.to_sentence
        end
      end
      format.json do
        if document.update(document_params)
          render json: { document: format_document(document), message: "Document updated successfully" }, status: :ok
        else
          render json: { errors: document.errors.full_messages }, status: :unprocessable_content
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    render json: { status: "error", message: "Document not found" }, status: :not_found
  end

  private

  def property_keys
    (1..10).map { |i| "property_string_#{i}" } +
      (1..20).map { |i| "property_integer_#{i}" } +
      (1..10).map { |i| "property_decimal_#{i}" } +
      (1..10).map { |i| "property_boolean_#{i}" } +
      (1..10).map { |i| "property_datetime_#{i}" }
  end

  def document_params
    params.require(:document).permit(
      :title,
      :body_markdown,
      :name,
      :description,
      :code,
      :business_type,
      :workflow_status,
      :category_id,
      :document_group_id,
      :branch_id,
      *property_keys,
      image_attachments: [],
      file_attachments: []
    )
  end

  def format_document(document)
    document.as_json(only: [
      :id, :title, :body_markdown, :name, :description, :code,
      :category_id, :document_group_id, :branch_id,
      :business_type, :lifecycle_status, :workflow_status,
      :created_at, :updated_at,
      :property_string_1, :property_string_2, :property_string_3, :property_string_4, :property_string_5,
      :property_string_6, :property_string_7, :property_string_8, :property_string_9, :property_string_10,
      :property_integer_1, :property_integer_2, :property_integer_3, :property_integer_4, :property_integer_5,
      :property_integer_6, :property_integer_7, :property_integer_8, :property_integer_9, :property_integer_10,
      :property_integer_11, :property_integer_12, :property_integer_13, :property_integer_14, :property_integer_15,
      :property_integer_16, :property_integer_17, :property_integer_18, :property_integer_19, :property_integer_20,
      :property_decimal_1, :property_decimal_2, :property_decimal_3, :property_decimal_4, :property_decimal_5,
      :property_decimal_6, :property_decimal_7, :property_decimal_8, :property_decimal_9, :property_decimal_10,
      :property_boolean_1, :property_boolean_2, :property_boolean_3, :property_boolean_4, :property_boolean_5,
      :property_boolean_6, :property_boolean_7, :property_boolean_8, :property_boolean_9, :property_boolean_10,
      :property_datetime_1, :property_datetime_2, :property_datetime_3, :property_datetime_4, :property_datetime_5,
      :property_datetime_6, :property_datetime_7, :property_datetime_8, :property_datetime_9, :property_datetime_10
    ]).merge(
      category: document.category&.as_json(only: [ :id, :name ]),
      document_group: document.document_group&.as_json(only: [ :id, :name ]),
      image_urls: document.image_urls,
      file_urls: document.file_urls
    )
  end

  def format_documents(documents)
    documents.map { |document| format_document(document) }
  end
end
