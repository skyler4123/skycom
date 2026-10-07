# app/controllers/companies/notifications_controller.rb
#
# Companies::NotificationsController — system-generated broadcasts (Shell-First).
# Notifications are created by Notifications::CreateService (never human-composed
# in v1); employees read only their subscribed tags. Show auto-marks read.
# Serves Stimulus: Companies_Notifications_IndexController|ShowController
# Endpoints: GET /companies/:company_id/notifications(.json),
#            GET /companies/:company_id/notifications/:id(.json),
#            POST /companies/:company_id/notifications/:id/mark_read,
#            POST /companies/:company_id/notifications/mark_all_read,
#            GET /companies/:company_id/notifications/unread_count
# Docs: docs/superpowers/plans/2026-10-07-notification.md
class Companies::NotificationsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        # Materialize distinct ids first: DISTINCT + ORDER BY in one query is
        # rejected by Postgres and breaks pagy counting.
        ids = Notification.subscribed_for(current_employee, current_company).pluck(:id)
        scope = Notification.where(id: ids).includes(:notification_tags).order(created_at: :desc)
        if params[:tag_id].present?
          tag = current_company.notification_tags.find(params[:tag_id])
          scope = scope.joins(:notification_tag_appointments)
            .where(notification_tag_appointments: { notification_tag_id: tag.id })
        end
        if params[:unread] == "true"
          scope = Notifications::UnreadQuery.new(company: current_company, employee: current_employee)
            .scope.where(id: scope.select(:id))
        end
        @pagy, @results = pagy(:offset, scope, jsonapi: true)
        @read_ids = EmployeeNotificationRead.where(employee: current_employee, notification: @results)
          .pluck(:notification_id).to_set
        render json: { notifications: @results.map { |n| format_notification(n) }, pagination: @pagy.data_hash }
      end
    end
  end

  def show
    notification = Notification.subscribed_for(current_employee, current_company).find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        Notifications::MarkReadService.call(employee: current_employee, notification: notification)
        render json: { notification: format_notification(notification) }
      end
    end
  end

  def mark_read
    notification = Notification.subscribed_for(current_employee, current_company).find(params[:id])
    result = Notifications::MarkReadService.call(employee: current_employee, notification: notification)

    if result[:success]
      render json: { success: true, created: result[:created] }
    else
      render json: { errors: result[:errors] }, status: :unprocessable_content
    end
  end

  def mark_all_read
    result = Notifications::MarkAllReadService.call(employee: current_employee)

    if result[:success]
      render json: { success: true, marked: result[:marked] }
    else
      render json: { errors: result[:errors] }, status: :unprocessable_content
    end
  end

  def unread_count
    count = Notifications::UnreadQuery.new(company: current_company, employee: current_employee).count
    render json: { unread_count: count }
  end

  private

  def format_notification(notification)
    read = @read_ids.include?(notification.id)
    notification.as_json(only: [ :id, :title, :body, :severity, :url, :created_at ]).merge(
      "tags" => notification.notification_tags.map { |t| t.as_json(only: [ :id, :name ]) },
      "read" => read
    )
  end
end
