# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::Operations::Reception", type: :feature, js: true do
  let(:company_user) { create(:user, :company_owner) }
  let(:company) { Seed::CompanyService.new(user: company_user, country: :us, business_type: :education).tap(&:save!) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company) }
  let(:operation_record) { create(:operation, company: company, branch: branch, operation_type: :reception) }
  let(:reception_path) { "/companies/#{company.id}/operations/reception/#{operation_record.id}?branch_id=#{branch.id}" }
  let(:event_category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "events") }
  let(:host) { create(:employee, company: company, branch: branch, name: "Eleanor Vance") }
  let(:second_host) { create(:employee, company: company, branch: branch, name: "David Chen") }
  let(:room) { create(:facility, company: company, branch: branch, name: "Boardroom Orion") }
  let(:quiet_room) { create(:facility, company: company, branch: branch, name: "Aurora Pod 1") }

  let!(:lobby_visit) do
    create_visit(customer_name: "Arthur Pendelton", status: :confirmed,
      start_at: 10.minutes.ago, host: host, facility: room, code: "VIS-ARTHUR")
  end
  let!(:second_lobby_visit) do
    create_visit(customer_name: "Camila Gomez", status: :confirmed,
      start_at: 4.minutes.ago, host: second_host, code: "VIS-CAMILA")
  end
  let!(:active_visit) do
    create_visit(customer_name: "Maya Lindqvist", status: :in_progress,
      start_at: 30.minutes.ago, host: second_host, facility: quiet_room, code: "VIS-MAYA")
  end
  let!(:upcoming_visit) do
    create_visit(customer_name: "Sarah Miller", status: :pending,
      start_at: 30.minutes.from_now, host: host, code: "VIS-SARAH")
  end

  before { sign_in(owner) }

  def create_visit(customer_name:, status:, start_at:, host:, facility: nil, code:)
    customer = create(:customer, company: company, name: customer_name,
      description: "Vanguard Global Capital")
    event = create(:event, company: company, branch: branch, category: event_category,
      name: "Visit · #{customer_name}", code: code, start_at: start_at,
      end_at: start_at + 1.hour, workflow_status: status)
    CustomerEventAppointment.create!(company: company, event: event, customer: customer)
    EmployeeEventAppointment.create!(company: company, event: event, employee: host)
    EventFacilityAppointment.create!(company: company, event: event, facility: facility) if facility
    event
  end

  scenario "loads the real visitor queue and KPIs from today's events" do
    visit reception_path

    expect(page).to have_content("Reception Operations Console", wait: 10)
    expect(page).to have_content("Arthur Pendelton")
    expect(page).to have_content("Camila Gomez")
    expect(page).to have_content("Vanguard Global Capital")
    expect(page).to have_content("Inside Building")
    expect(page).to have_content("Lobby Waiting")
    expect(page).to have_content("Boardroom Orion")
  end

  scenario "filters the lobby queue by search" do
    visit reception_path
    expect(page).to have_content("Arthur Pendelton", wait: 10)

    fill_in "reception-filter-input", with: "Arthur"

    expect(page).to have_content("Arthur Pendelton")
    expect(page).not_to have_content("Camila Gomez")
  end

  scenario "switches to the visitors currently inside the building" do
    visit reception_path
    expect(page).to have_content("Arthur Pendelton", wait: 10)

    find("button", text: /Active in Bldg/).click

    expect(page).to have_content("Maya Lindqvist", wait: 5)
    expect(page).not_to have_content("Arthur Pendelton")
  end

  scenario "checks in a walk-in guest and persists the Customer and Event" do
    visit reception_path
    expect(page).to have_content("Reception Operations Console", wait: 10)

    click_button "Quick Walk-In Check-In"
    expect(page).to have_content("Instant Walk-In Guest Badge Station", wait: 5)

    find('input[name="visitor[name]"]').set("Jessica Tan")
    find('input[name="visitor[company]"]').set("Deloitte Consulting")
    find('select[name="visitor[host_id]"]').find("option[value='#{host.id}']").select_option
    click_button "Check-In & Print Badge"

    expect(page).to have_content("Walk-in check-in complete for Jessica Tan", wait: 5)
    expect(page).to have_content("Jessica Tan")

    customer = Customer.find_by(company: company, name: "Jessica Tan")
    event = Event.where(company: company).order(:created_at).to_a
      .find { |candidate| candidate.name.start_with?("Walk-in · Jessica Tan") }

    expect(customer).to be_present
    expect(customer.description).to eq("Deloitte Consulting")
    expect(event).to be_present
    expect(event.workflow_status).to eq("confirmed")
    expect(event.customer_event_appointments.first.customer).to eq(customer)
    expect(event.employee_event_appointments.first.employee).to eq(host)
  end

  scenario "logs a parcel and persists it as a reception Event" do
    visit reception_path
    expect(page).to have_content("Couriers & Deliveries", wait: 10)

    click_button "Log Delivery"
    expect(page).to have_content("Item summary", wait: 5)

    find('input[name="parcel[carrier]"]').set("UPS")
    find('select[name="parcel[employee_id]"]').find("option[value='#{host.id}']").select_option
    find('input[name="parcel[item]"]').set("Passport envelope")
    click_button "Log package"

    expect(page).to have_content("Parcel logged for #{host.name}", wait: 5)
    expect(page).to have_content("Passport envelope")

    parcel = Event.where(company: company).where("metadata ->> 'reception_kind' = ?", "parcel").last
    expect(parcel).to be_present
    expect(parcel.metadata["item"]).to eq("Passport envelope")
    expect(parcel.employee_event_appointments.first.employee).to eq(host)
  end

  scenario "checks out an active visitor and completes the Event" do
    visit reception_path
    expect(page).to have_content("Reception Operations Console", wait: 10)

    find("button", text: /Active in Bldg/).click
    expect(page).to have_content("Maya Lindqvist", wait: 5)

    click_button "Complete Check-Out"

    expect(page).to have_content("Maya Lindqvist checked out", wait: 5)
    expect(active_visit.reload.workflow_status).to eq("completed")
  end

  scenario "notifies the host and stamps the visit metadata" do
    visit reception_path
    expect(page).to have_content("Arthur Pendelton", wait: 10)

    within(find("[data-reception-visitor]", text: "Arthur Pendelton")) do
      click_button "Re-Notify Host"
    end

    expect(page).to have_content("Host notification logged for Arthur Pendelton", wait: 5)
    expect(lobby_visit.reload.metadata["host_notified_at"]).to be_present
  end

  scenario "marks a held parcel as picked up" do
    parcel = create(:event, company: company, branch: branch, category: event_category,
      name: "Parcel TEST", code: "PKG-TEST", start_at: Time.current,
      workflow_status: :received,
      metadata: { "reception_kind" => "parcel", "carrier" => "DHL",
                  "item" => "Legal documents", "recipient_name" => host.name })
    EmployeeEventAppointment.create!(company: company, event: parcel, employee: host)

    visit reception_path
    expect(page).to have_content("Legal documents", wait: 10)

    find("button[title='Mark picked up']").click

    expect(page).to have_content("Parcel marked as picked up", wait: 5)
    expect(parcel.reload.workflow_status).to eq("completed")
    expect(parcel.metadata["picked_up_at"]).to be_present
  end
end
