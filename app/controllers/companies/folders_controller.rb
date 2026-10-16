# app/controllers/companies/folders_controller.rb
#
# Storage buckets API (Shell-First). Roots act as buckets; files live only
# inside folders. Show returns subfolders + files + breadcrumbs for the
# S3-like browser.
# Serves Stimulus: Companies_Folders_IndexController (roots),
#                  Companies_Folders_ShowController (detail + browser + upload + delete),
#                  Companies_Folders_NewModalController (create)
# Endpoints: GET /companies/:company_id/folders(.json) + CRUD — see config/routes.rb
# Docs: docs/STORAGE.md
class Companies::FoldersController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        current_folder = find_current_folder
        folders = current_folder ? current_folder.children.order(:name) : current_company.folders.where(parent_id: nil).order(:name)
        folders = folders.includes(stored_files: { file_attachment: :blob })

        render json: {
          folders: folders.map { |f| format_folder(f) },
          current_folder: current_folder ? format_folder(current_folder) : nil,
          breadcrumbs: current_folder ? breadcrumbs_for(current_folder) : []
        }
      end
    end
  end

  def show
    folder = current_company.folders.includes(children: {}, stored_files: { file_attachment: :blob }).find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          folder: format_folder(folder),
          subfolders: folder.children.order(:name).map { |f| format_folder(f) },
          files: folder.stored_files.order(:name).map { |sf| format_file(sf) },
          breadcrumbs: breadcrumbs_for(folder)
        }
      end
    end
  rescue ActiveRecord::RecordNotFound
    render json: { errors: [ "Folder not found" ] }, status: :not_found
  end

  def create
    folder = current_company.folders.new(folder_params)

    if folder.save
      render json: { folder: format_folder(folder), message: "Folder created successfully" }, status: :created
    else
      render json: { errors: folder.errors.full_messages }, status: :unprocessable_content
    end
  end

  def update
    folder = current_company.folders.find(params[:id])

    if folder.update(folder_params)
      render json: { folder: format_folder(folder), message: "Folder updated successfully" }, status: :ok
    else
      render json: { errors: folder.errors.full_messages }, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotFound
    render json: { errors: [ "Folder not found" ] }, status: :not_found
  end

  def destroy
    folder = current_company.folders.find(params[:id])

    if folder.destroy
      render json: { message: "Folder deleted successfully" }, status: :ok
    else
      render json: { errors: folder.errors.full_messages }, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotFound
    render json: { errors: [ "Folder not found" ] }, status: :not_found
  end

  private

  def folder_params
    params.require(:folder).permit(:name, :parent_id)
  end

  def find_current_folder
    return nil if params[:parent_id].blank?

    current_company.folders.find(params[:parent_id])
  end

  def breadcrumbs_for(folder)
    chain = []
    current = folder
    while current
      chain.unshift(format_folder(current))
      current = current.parent
    end
    chain
  end

  def format_folder(folder)
    folder.as_json(only: [ :id, :name, :parent_id, :company_id, :created_at, :updated_at ])
  end

  def format_file(stored_file)
    stored_file.as_json(only: [ :id, :name, :folder_id, :company_id, :file_size, :extension, :content_type, :attachable_type, :attachable_id, :created_at ])
      .merge("download_url" => stored_file.download_url)
  end
end
