# frozen_string_literal: true

require "csv"

# app/controllers/companies/company_migrations_controller.rb
#
# Owner-only, config-driven CSV ingestion (Shell-First). One migration holds
# its mapping config, a migration-only folder with uploaded chunk files,
# counters, audit logs, and the approve → import / rollback workflow.
# Serves Stimulus: Companies_CompanyMigrations_IndexController (list + create modal + delete),
#                  Companies_CompanyMigrations_ShowController (upload/split, config editor, dry run, approve, rollback, progress),
#                  Companies_CompanyMigrations_NewModalController (create modal)
# Endpoints: GET/POST /companies/:company_id/company_migrations(.json) + member
#            POST chunks, PATCH config, POST dry_run, POST approve, POST rollback — see config/routes.rb
# Docs: docs/DATA_MIGRATION.md
class Companies::CompanyMigrationsController < Companies::ApplicationController
  rescue_from ActiveRecord::RecordNotFound do
    respond_to do |format|
      # Shell-First: the FE renders the error card from the .json 404.
      format.html { render html: "", layout: true, status: :not_found }
      format.json { render json: { errors: [ "Migration not found" ] }, status: :not_found }
    end
  end

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        migrations = current_company.company_migrations.order(created_at: :desc)
        render json: { company_migrations: migrations.map { |migration| format_summary(migration) } }
      end
    end
  end

  def show
    migration = find_migration

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { company_migration: format_migration(migration) } }
    end
  end

  def create
    migration = CompanyMigrations::SetupService.call(
      company: current_company,
      name: migration_params[:name],
      source_filename: migration_params[:source_filename],
      source_file_size: migration_params[:source_file_size]
    )

    render json: { company_migration: format_summary(migration), message: "Migration created" }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
  end

  def chunks
    migration = find_migration
    errors = chunk_errors(migration)
    return render_errors(errors) if errors.any?

    content = params[:file].read.force_encoding(Encoding::UTF_8)
    clean = content.sub(/\A\uFEFF/, "")

    begin
      header = CSV.parse_line(clean.lines.first)

      if migration.source_header.present? && header.to_json != migration.source_header
        return render_errors([ "chunk header does not match the first chunk" ])
      end

      rows = CSV.parse(clean, headers: true).size
    rescue CSV::MalformedCSVError
      return render_errors([ "file is not valid CSV" ])
    end
    stored_file = nil

    CompanyMigration.transaction do
      stored_file = migration.stored_files.new(
        company: current_company,
        folder: migration.folder,
        name: format("part-%03d.csv", migration.total_chunks),
        metadata: { "chunk_index" => migration.total_chunks, "row_count" => rows, "import_status" => "uploaded" }
      )
      stored_file.file.attach(io: StringIO.new(content), filename: stored_file.name, content_type: "text/csv")
      stored_file.save!

      migration.source_header = header.to_json if migration.source_header.blank?
      migration.save!
      migration.recompute_counters!
    end

    render json: {
      stored_file: format_chunk(stored_file),
      company_migration: format_summary(migration)
    }, status: :created
  end

  def update_config
    migration = find_migration
    return render_errors([ "config is locked" ]) if config_locked?(migration)

    raw = params.dig(:company_migration, :migration_mapping_config)
    return render_errors([ "config is required" ]) if raw.blank?

    raw = raw.to_unsafe_h
    parsed = CompanyMigrations::Config.new(raw)
    return render_errors(parsed.errors) unless parsed.valid?

    migration.update!(
      migration_mapping_config: raw,
      dry_run_result: nil,
      target_resource: parsed.targets.first&.dig("resource")
    )

    render json: { company_migration: format_summary(migration), message: "Config saved" }
  end

  def dry_run
    migration = find_migration
    result = CompanyMigrations::DryRunService.call(company_migration: migration)

    if result[:success]
      render json: { dry_run_result: result[:result], message: "Dry run passed" }
    else
      errors = result[:errors].presence || [ "Dry run failed — check the row errors" ]
      render json: { errors: errors, dry_run_result: result[:result] }, status: :unprocessable_content
    end
  end

  def approve
    migration = find_migration
    return render_errors([ "Migration is not ready to approve" ]) unless migration.approvable?

    migration.update!(workflow_status: :approved, approved_at: Time.current)
    CompanyMigrations::ImportJob.perform_later(migration.id)

    render json: { message: "Migration approved and queued" }
  end

  def rollback
    migration = find_migration
    return render_errors([ "This migration cannot be rolled back" ]) unless migration.rollbackable?

    migration.update!(workflow_status: :rolling_back)
    CompanyMigrations::RollbackJob.perform_later(migration.id)

    render json: { message: "Rollback queued" }
  end

  def destroy
    migration = find_migration
    return render_errors([ "Only draft migrations can be deleted" ]) unless migration.workflow_status_draft?

    folder = migration.folder

    CompanyMigration.transaction do
      migration.stored_files.each(&:destroy!)
      migration.destroy!
      folder.destroy!
    end

    render json: { message: "Migration deleted" }
  end

  private

  def find_migration
    current_company.company_migrations.find(params[:id])
  end

  def migration_params
    params.require(:company_migration).permit(:name, :source_filename, :source_file_size)
  end

  def chunk_errors(migration)
    file = params[:file]
    errors = []

    errors << "migration is not editable" unless migration.workflow_status_draft?
    errors << "file is required" if file.blank?

    if file.present?
      errors << "file is too big (max #{MIGRATION_CHUNK_MAX_BYTES / 1.kilobyte}KB per chunk)" if file.size > MIGRATION_CHUNK_MAX_BYTES
      errors << "file must be a CSV" unless csv_file?(file)
    end

    errors << "chunks must be uploaded in order (next index #{migration.total_chunks})" if params[:chunk_index].to_i != migration.total_chunks

    errors
  end

  def csv_file?(file)
    file.content_type.to_s.include?("csv") || File.extname(file.original_filename.to_s).downcase == ".csv"
  end

  def config_locked?(migration)
    !(migration.workflow_status_draft? || migration.workflow_status_failed?)
  end

  def format_migration(migration)
    {
      id: migration.id,
      name: migration.name,
      workflow_status: migration.workflow_status,
      source_filename: migration.source_filename,
      source_file_size: migration.source_file_size,
      target_resource: migration.target_resource,
      total_chunks: migration.total_chunks,
      total_rows: migration.total_rows,
      processed_rows: migration.processed_rows,
      created_rows: migration.created_rows,
      updated_rows: migration.updated_rows,
      failed_rows: migration.failed_rows,
      chunk_max_bytes: MIGRATION_CHUNK_MAX_BYTES,
      migration_mapping_config: migration.migration_mapping_config,
      dry_run_result: migration.dry_run_result,
      error_samples: migration.error_samples,
      config_locked: config_locked?(migration),
      can_approve: migration.approvable?,
      can_rollback: migration.rollbackable?,
      chunks: migration.ordered_chunks.map { |chunk| format_chunk(chunk) },
      preview: CompanyMigrations::PreviewReader.call(company_migration: migration)
    }
  end

  def format_summary(migration)
    {
      id: migration.id,
      name: migration.name,
      workflow_status: migration.workflow_status,
      target_resource: migration.target_resource,
      total_chunks: migration.total_chunks,
      total_rows: migration.total_rows,
      processed_rows: migration.processed_rows,
      created_rows: migration.created_rows,
      updated_rows: migration.updated_rows,
      failed_rows: migration.failed_rows,
      created_at: migration.created_at,
      updated_at: migration.updated_at
    }
  end

  def format_chunk(chunk)
    {
      id: chunk.id,
      name: chunk.name,
      chunk_index: chunk.chunk_index,
      row_count: chunk.row_count,
      import_status: chunk.import_status,
      file_size: chunk.file_size
    }
  end

  def render_errors(errors)
    render json: { errors: errors }, status: :unprocessable_content
  end
end
