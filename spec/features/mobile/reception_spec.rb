# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Mobile Reception", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:user) { company.user }
  let(:branch) { create(:branch, company: company, name: "Downtown Branch") }
  let!(:operation_record) do
    create(:operation, company: company, branch: branch, name: "Front Desk", operation_type: :reception)
  end
  let(:event_category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "events") }
  let(:host) { create(:employee, company: company, branch: branch, name: "Eleanor Vance") }
  let(:room) { create(:facility, company: company, branch: branch, name: "Boardroom Orion") }
  let(:reception_path) do
    "/mobile/companies/#{company.id}/operations/reception/#{operation_record.id}?branch_id=#{branch.id}"
  end

  before { sign_in(user) }

  def create_visit(customer_name:, status:, start_at:, facility: nil, code:)
    customer = create(:customer, company: company, name: customer_name, description: "Vanguard Global Capital")
    event = create(:event, company: company, branch: branch, category: event_category,
      name: "Visit · #{customer_name}", code: code, start_at: start_at,
      end_at: start_at + 1.hour, workflow_status: status)
    CustomerEventAppointment.create!(company: company, event: event, customer: customer)
    EmployeeEventAppointment.create!(company: company, event: event, employee: host)
    EventFacilityAppointment.create!(company: company, event: event, facility: facility) if facility
    event
  end

  scenario "loads the reception console in the mobile shell" do
    create_visit(customer_name: "Arthur Pendelton", status: :confirmed,
      start_at: 10.minutes.ago, facility: room, code: "VIS-ARTHUR")

    visit reception_path

    expect(page).to have_content("Reception Operations Console", wait: 10)
    expect(page).to have_content("Arthur Pendelton")
    expect(page).to have_content("Vanguard Global Capital")
    expect(page).to have_button("Quick Walk-In Check-In")
  end

  scenario "opens reception from the mobile operations list" do
    visit mobile_company_operations_path(company)

    click_link "Open Reception"

    expect(page).to have_current_path(reception_path, wait: 10)
    expect(page).to have_content("Reception Operations Console", wait: 10)
  end

  scenario "stacks the coordination panels under the queue in portrait" do
    create_visit(customer_name: "Arthur Pendelton", status: :confirmed,
      start_at: 10.minutes.ago, facility: room, code: "VIS-ARTHUR")

    page.driver.browser.manage.window.resize_to(768, 1024)
    visit reception_path

    expect(page).to have_content("Reception Operations Console", wait: 10)
    queue = find("section", text: /Active Lobby Queue/i)
    panels = find("aside")

    expect(panels.native.rect.y).to be > queue.native.rect.y
  ensure
    page.driver.browser.manage.window.resize_to(1400, 900)
  end

  scenario "shows the coordination panels beside the queue on a landscape tablet" do
    create_visit(customer_name: "Arthur Pendelton", status: :confirmed,
      start_at: 10.minutes.ago, facility: room, code: "VIS-ARTHUR")

    page.driver.browser.manage.window.resize_to(1280, 800)
    visit reception_path

    expect(page).to have_content("Reception Operations Console", wait: 10)
    queue = find("section", text: /Active Lobby Queue/i)
    panels = find("aside")

    expect(panels.native.rect.x).to be > queue.native.rect.x
  ensure
    page.driver.browser.manage.window.resize_to(1400, 900)
  end

  scenario "renders the console on a phone in portrait" do
    create_visit(customer_name: "Arthur Pendelton", status: :confirmed,
      start_at: 10.minutes.ago, facility: room, code: "VIS-ARTHUR")

    page.driver.browser.manage.window.resize_to(390, 844)
    visit reception_path

    expect(page).to have_content("Reception Operations Console", wait: 10)
    expect(page).to have_content("Arthur Pendelton")
    expect(page).to have_button("Quick Walk-In Check-In")
  ensure
    page.driver.browser.manage.window.resize_to(1400, 900)
  end

  scenario "checks in a walk-in guest from the mobile console" do
    host
    visit reception_path
    expect(page).to have_content("Reception Operations Console", wait: 10)

    click_button "Quick Walk-In Check-In"
    find('input[name="visitor[name]"]').set("Jessica Tan")
    find('input[name="visitor[company]"]').set("Deloitte Consulting")
    find('select[name="visitor[host_id]"]').find("option[value='#{host.id}']").select_option
    click_button "Check-In & Print Badge"

    expect(page).to have_content("Walk-in check-in complete for Jessica Tan", wait: 5)
    expect(page).to have_content("Jessica Tan")

    expect(Customer.find_by(company: company, name: "Jessica Tan")).to be_present
    expect(
      Event.where(company: company).order(:created_at).to_a
        .find { |event| event.name.start_with?("Walk-in · Jessica Tan") }
    ).to be_present
  end

  scenario "does not show Open Reception for non-reception operations" do
    create(:operation, company: company, branch: branch, name: "Booking Desk", operation_type: :booking)

    visit mobile_company_operations_path(company)

    within("section", text: "Booking Desk") do
      expect(page).not_to have_link("Open Reception")
    end
  end
end
