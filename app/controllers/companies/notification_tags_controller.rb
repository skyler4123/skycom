# app/controllers/companies/notification_tags_controller.rb
#
# NotificationTag dashboard API (Shell-First). User-managed broadcast tags:
# custom tags are fully CRUD-able, system tags (All Company, Promotion,
# All <Role>) are read-only in the UI and destroy-blocked at the model.
# Serves Stimulus: Companies_NotificationTags_IndexController,
#                  Companies_NotificationTags_NewController|ShowController|EditController
# Endpoints: GET /companies/:company_id/notification_tags(.json) + nested CRUD — see config/routes.rb
# Docs: docs/MODEL_CALLBACKS.md (NotificationTag row)
class Companies::NotificationTagsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        @pagy, @results = pagy(:offset, current_company.notification_tags.order(:name), jsonapi: true)
        render json: { notification_tags: @results.map { |t| format_tag(t) }, pagination: @pagy.data_hash }
      end
    end
  end

  def show
    tag = current_company.notification_tags.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { notification_tag: format_tag(tag) } }
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: {} }
    end
  end

  def edit
    tag = current_company.notification_tags.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { notification_tag: format_tag(tag) } }
    end
  end

  def create
    tag = current_company.notification_tags.new(tag_params)
    tag.business_type = :custom
    if tag.save
      redirect_to company_notification_tag_path(current_company, tag), notice: "Notification tag created successfully"
    else
      redirect_to new_company_notification_tag_path(current_company),
        alert: tag.errors.full_messages.to_sentence
    end
  end

  def update
    tag = current_company.notification_tags.find(params[:id])
    if tag.update(tag_params)
      redirect_to company_notification_tag_path(current_company, tag), notice: "Notification tag updated successfully."
    else
      redirect_to edit_company_notification_tag_path(current_company, tag),
        alert: tag.errors.full_messages.to_sentence
    end
  end

  def destroy
    tag = current_company.notification_tags.find(params[:id])
    tag.destroy!
    redirect_to company_notification_tags_path(current_company), notice: "Notification tag deleted."
  rescue ActiveRecord::ReadOnlyRecord => e
    redirect_to company_notification_tag_path(current_company, tag),
      alert: e.message
  end

  private

  def tag_params
    params.require(:notification_tag).permit(:name, :description)
  end

  def format_tag(tag)
    tag.as_json(only: [
      :id, :name, :description, :business_type,
      :lifecycle_status, :workflow_status,
      :created_at, :updated_at
    ])
  end
end
