# frozen_string_literal: true

# Maps a Page purpose to its operation route and appends the appointment's
# location parameter. Adding a page type means adding one route plus one entry
# here.
class PageLaunchService
  ROUTES = {
    "pos" => :pos_company_pages_path,
    "booking" => :booking_company_pages_path,
    "inventory" => :inventory_company_pages_path,
    "reception" => :reception_company_pages_path,
    "kitchen" => :kitchen_company_pages_path,
    "housekeeping" => :housekeeping_company_pages_path,
    "store_manager" => :store_manager_company_pages_path
  }.freeze

  def self.call(company:, page:, appointment:)
    helper = ROUTES.fetch(page.page_type)
    location = if appointment.is_a?(BranchPageAppointment)
      { branch_id: appointment.branch_id }
    else
      { warehouse_id: appointment.warehouse_id }
    end

    Rails.application.routes.url_helpers.public_send(helper, company, page, **location)
  end
end
