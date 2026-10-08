# app/controllers/companies/notification_configs_controller.rb
#
# Companies::NotificationConfigsController — singular per-employee config (Shell-First).
# Placeholder in v1: preferences persist but have no delivery effect.
# Serves Stimulus: Companies_NotificationConfigs_ShowController
# Endpoints: GET/PATCH /companies/:company_id/notification_config(.json)
# Docs: docs/superpowers/plans/2026-10-07-notification.md
class Companies::NotificationConfigsController < Companies::ApplicationController
  def show
    config = NotificationConfig.for_employee!(current_employee)

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { notification_config: format_config(config) } }
    end
  end

  def update
    config = NotificationConfig.for_employee!(current_employee)

    respond_to do |format|
      if config.update(config_params)
        format.html do
          redirect_to company_notification_config_path(current_company),
            notice: "Notification preferences updated successfully."
        end
        format.json { render json: { notification_config: format_config(config) } }
      else
        format.html do
          redirect_to company_notification_config_path(current_company),
            alert: config.errors.full_messages.to_sentence
        end
        format.json { render json: { errors: config.errors.full_messages }, status: :unprocessable_content }
      end
    end
  end

  private

  def config_params
    params.require(:notification_config).permit(preferences: {})
  end

  def format_config(config)
    config.as_json(only: [ :id, :last_read_all_at, :preferences ])
  end
end
