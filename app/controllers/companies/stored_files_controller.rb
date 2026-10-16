# app/controllers/companies/stored_files_controller.rb
#
# Metered file API (Shell-First). Files live only inside folders; each row
# wraps one Active Storage blob with audit columns for future charging.
# Serves Stimulus: Companies_Folders_IndexController (create/download/destroy),
#                  Companies_StoredFiles_NewModalController (create)
# Endpoints: POST /companies/:company_id/stored_files + download/destroy — see config/routes.rb
# Docs: docs/STORAGE.md
class Companies::StoredFilesController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.stored_files.includes(file_attachment: :blob).order(:name)
        scope = scope.where(folder_id: params[:folder_id]) if params[:folder_id].present?

        render json: { stored_files: scope.map { |sf| format_file(sf) } }
      end
    end
  end

  def show
    stored_file = current_company.stored_files.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { stored_file: format_file(stored_file) } }
    end
  rescue ActiveRecord::RecordNotFound
    render json: { errors: [ "File not found" ] }, status: :not_found
  end

  def create
    stored_file = current_company.stored_files.new(stored_file_params.except(:file))
    stored_file.file.attach(stored_file_params[:file]) if stored_file_params[:file].present?

    if stored_file.save
      render json: { stored_file: format_file(stored_file), message: "File uploaded successfully" }, status: :created
    else
      render json: { errors: stored_file.errors.full_messages }, status: :unprocessable_content
    end
  end

  def download
    stored_file = current_company.stored_files.find(params[:id])

    unless stored_file.file.attached?
      return render json: { errors: [ "File has no attachment" ] }, status: :not_found
    end

    redirect_to Rails.application.routes.url_helpers.rails_blob_path(
      stored_file.file, disposition: "attachment", only_path: true
    )
  rescue ActiveRecord::RecordNotFound
    render json: { errors: [ "File not found" ] }, status: :not_found
  end

  def destroy
    stored_file = current_company.stored_files.find(params[:id])
    stored_file.destroy!

    render json: { message: "File deleted successfully" }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { errors: [ "File not found" ] }, status: :not_found
  end

  private

  def stored_file_params
    params.require(:stored_file).permit(:name, :folder_id, :attachable_type, :attachable_id, :file)
  end

  def format_file(stored_file)
    stored_file.as_json(only: [ :id, :name, :folder_id, :company_id, :file_size, :extension, :content_type, :attachable_type, :attachable_id, :created_at, :updated_at ])
      .merge("download_url" => stored_file.download_url)
  end
end
