# frozen_string_literal: true

# app/controllers/companies/imports_controller.rb
#
# Owner-only, user-prepared CSV ingestion (Shell-First). One import holds the
# target table + one category, a folder-backed source CSV, the resolved header
# contract, a full-file dry run, and the approve → run / rollback workflow.
# Deliberately isolated from Companies::CompanyMigrationsController — see
# docs/IMPORT.md.
# Serves Stimulus: Companies_Imports_IndexController (list + create modal + delete),
#                  Companies_Imports_ShowController (setup, sample, upload, dry run, approve, rollback, progress),
#                  Companies_Imports_NewModalController (create modal)
# Endpoints: GET/POST /companies/:company_id/imports(.json) + member
#            POST source_file, POST dry_run, POST approve, POST rollback — see config/routes.rb
# Docs: docs/IMPORT.md
class Companies::ImportsController < Companies::ApplicationController
  rescue_from ActiveRecord::RecordNotFound do
    respond_to do |format|
      # Shell-First: the FE renders the error card from the .json 404.
      format.html { render html: "", layout: true, status: :not_found }
      format.json { render json: { errors: [ "Import not found" ] }, status: :not_found }
    end
  end

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        imports = current_company.imports.includes(:category).recent
        render json: { imports: imports.map { |import| format_summary(import) } }
      end
    end
  end

  def show
    import = find_import

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { import: format_import(import) } }
    end
  end

  def create
    import = Imports::SetupService.call(
      company: current_company,
      creator: current_employee,
      name: import_params[:name],
      description: import_params[:description]
    )

    render json: { import: format_summary(import), message: "Import created" }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render_errors(e.record.errors.full_messages)
  end

  def update
    import = find_import
    return render_errors([ "Only draft imports can be edited" ]) unless import.workflow_status_draft?

    attributes = import_params.slice(:name, :description)
    selection_changed = false

    if import_params[:target_table].present? || import_params[:category_id].present?
      target_table = import_params[:target_table].presence || import.target_table
      category = current_company.categories.find_by(id: import_params[:category_id].presence || import.category_id)

      resolved = Imports::SchemaResolver.call(company: current_company, target_table: target_table, category: category)
      return render_errors(resolved[:errors]) unless resolved[:success]

      attributes[:target_table] = resolved[:schema]["target_table"]
      attributes[:target_model] = resolved[:schema]["target_model"]
      attributes[:category_id] = resolved[:schema]["category_id"]
      selection_changed = attributes[:target_table] != import.target_table || attributes[:category_id] != import.category_id
    end

    if selection_changed
      attributes[:dry_run_result] = nil
      attributes[:schema_snapshot] = {}
      attributes[:error_samples] = []
    end

    import.update!(attributes)
    render json: { import: format_import(import), message: "Import setup saved" }
  rescue ActiveRecord::RecordInvalid => e
    render_errors(e.record.errors.full_messages)
  end

  def destroy
    import = find_import
    return render_errors([ "Only draft imports can be deleted" ]) unless import.workflow_status_draft?

    folder = import.folder

    Import.transaction do
      import.destroy!
      folder.destroy!
    end

    render json: { message: "Import deleted" }
  rescue ActiveRecord::RecordNotDestroyed => e
    render_errors([ e.message ])
  end

  def source_file
    import = find_import
    result = Imports::FileIngestService.call(import: import, file: params[:file], company: current_company)

    if result[:success]
      render json: {
        import: format_summary(import.reload),
        message: "CSV uploaded",
        row_count: result[:row_count]
      }, status: :created
    else
      render_errors(result[:errors])
    end
  end

  def dry_run
    import = find_import
    result = Imports::DryRunService.call(import: import)

    if result[:success]
      render json: { dry_run_result: result[:result], import: format_import(import.reload), message: "Dry run passed" }
    else
      errors = result[:errors].presence || [ "Dry run failed" ]
      render json: {
        errors: errors,
        dry_run_result: result[:result],
        import: format_import(import.reload)
      }, status: :unprocessable_content
    end
  end

  def approve
    import = find_import
    return render_errors([ "Import is not ready to approve" ]) unless import.approvable?

    import.update!(workflow_status: :approved, approved_at: Time.current)
    Imports::RunJob.perform_later(import.id)

    render json: { message: "Import approved and queued" }
  end

  def rollback
    import = find_import
    return render_errors([ "This import cannot be rolled back" ]) unless import.rollbackable?

    import.update!(
      workflow_status: :rolling_back,
      metadata: import.metadata.merge(
        "rollback_previous_status" => import.workflow_status,
        "rollback_total" => import.import_logs.count,
        "rollback_processed" => 0
      )
    )
    Imports::RollbackJob.perform_later(import.id)

    render json: { message: "Rollback queued" }
  end

  private

  def find_import
    current_company.imports.includes(:category).find(params[:id])
  end

  def import_params
    params.require(:import).permit(:name, :description, :target_table, :category_id)
  end

  def format_summary(import)
    {
      id: import.id,
      name: import.name,
      description: import.description,
      target_table: import.target_table,
      target_model: import.target_model,
      category_name: import.category&.name,
      workflow_status: import.workflow_status,
      source_filename: import.source_filename,
      source_file_size: import.source_file_size,
      total_rows: import.total_rows,
      processed_rows: import.processed_rows,
      created_rows: import.created_rows,
      failed_rows: import.failed_rows,
      created_at: import.created_at,
      updated_at: import.updated_at
    }
  end

  def format_import(import)
    resolved = resolve_schema(import)

    format_summary(import).merge(
      category_id: import.category_id,
      dry_run_result: import.dry_run_result,
      error_samples: import.error_samples,
      setup_locked: import.setup_locked?,
      can_approve: import.approvable?,
      can_rollback: import.rollbackable?,
      max_file_bytes: IMPORT_MAX_FILE_BYTES,
      max_rows: IMPORT_MAX_ROWS,
      importable_resources: importable_resources_payload,
      categories: categories_payload,
      schema: resolved ? resolved[:schema] : nil,
      sample: resolved ? sample_payload(resolved) : empty_sample
    )
  end

  def resolve_schema(import)
    return nil if import.target_table.blank? || import.category.nil?

    result = Imports::SchemaResolver.call(
      company: current_company,
      target_table: import.target_table,
      category: import.category
    )
    result[:success] ? result : nil
  end

  def sample_payload(resolved)
    Imports::SampleService.call(
      company: current_company,
      schema: resolved[:schema],
      model: resolved[:model],
      category: resolved[:category]
    )
  end

  def empty_sample
    { "headers" => [], "rows" => [], "total_records" => 0 }
  end

  def importable_resources_payload
    IMPORTABLE_RESOURCES.map do |table_name, model_name|
      {
        table_name: table_name,
        model_name: model_name,
        label: model_name.underscore.humanize
      }
    end
  end

  def categories_payload
    current_company.categories.order(:name).map do |category|
      {
        id: category.id,
        name: category.name,
        resource_name: category.resource_name
      }
    end
  end

  def render_errors(errors)
    render json: { errors: Array(errors) }, status: :unprocessable_content
  end
end
