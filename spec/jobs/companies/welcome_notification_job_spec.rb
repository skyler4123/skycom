require "rails_helper"

RSpec.describe Companies::WelcomeNotificationJob, type: :job do
  around do |example|
    original = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    example.run
    ActiveJob::Base.queue_adapter = original
  end

  it "enqueues a delayed welcome when a company is created" do
    expect {
      create(:company)
    }.to have_enqueued_job(described_class)
  end

  it "welcomes a US company in English and only the owner sees it" do
    company = create(:company)
    company.update!(country: :us)
    owner = company.employees.find_by!(business_type: :owner)
    teammate = create(:employee, company: company)
    teammate.update!(business_type: :full_time)

    described_class.perform_now(company.id)

    notification = Notification.where(company: company).order(:created_at).last
    expect(notification.title).to eq(WELCOME_NOTIFICATION_CONTENT[:us][:title])
    expect(notification.body).to eq(WELCOME_NOTIFICATION_CONTENT[:us][:body])
    expect(Notifications::UnreadQuery.new(company: company, employee: owner.reload).count).to eq(1)
    expect(Notifications::UnreadQuery.new(company: company, employee: teammate.reload).count).to eq(0)
  end

  it "welcomes a VN company in Vietnamese regardless of business domain" do
    hotel = create(:company)
    hotel.update!(country: :vn, business_type: :hotel)
    retail = create(:company)
    retail.update!(country: :vn, business_type: :retail)

    described_class.perform_now(hotel.id)
    described_class.perform_now(retail.id)

    expect(Notification.where(company: hotel).order(:created_at).last.title)
      .to eq(WELCOME_NOTIFICATION_CONTENT[:vn][:title])
    expect(Notification.where(company: retail).order(:created_at).last.body)
      .to eq(WELCOME_NOTIFICATION_CONTENT[:vn][:body])
  end

  it "is idempotent on retry" do
    company = create(:company)
    company.update!(country: :us)

    described_class.perform_now(company.id)
    described_class.perform_now(company.id)

    expect(Notification.where(company: company).count).to eq(1)
  end

  it "no-ops when the company is gone" do
    expect {
      described_class.perform_now(SecureRandom.uuid)
    }.not_to raise_error
    expect(Notification.count).to eq(0)
  end

  it "creates nothing when the owner is missing" do
    company = create(:company)
    company.update!(country: :us)
    EmployeeRoleAppointment.where(company: company).delete_all
    company.employees.delete_all

    expect {
      described_class.perform_now(company.id)
    }.not_to raise_error
    expect(Notification.where(company: company).count).to eq(0)
  end
end
