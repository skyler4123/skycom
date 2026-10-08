require "rails_helper"

RSpec.describe Seed::AttendanceRequestService do
  let(:company_user) { create(:user, :company_owner) }
  let(:company) { Seed::CompanyService.new(user: company_user, country: :us, business_type: :retail).tap(&:save!) }

  around do |example|
    Company.skip_init = false
    example.run
  ensure
    Company.skip_init = true
  end

  let!(:cashier) do
    create(:employee, user: create(:user), company: company).tap do |e|
      e.attach_role("Cashier")
      e.save!
      e.clear_permissions_cache
      company.clear_permissions_cache
      e.reload
    end
  end

  it "creates pending/approved/rejected samples with linked days" do
    expect { described_class.create_samples(company: company, employees: [ cashier ]) }
      .to change(AttendanceRequest, :count).by(3)

    expect(company.attendance_requests.status_pending.count).to be >= 1
    expect(company.attendance_requests.status_approved.count).to eq(1)
    expect(company.attendance_requests.status_rejected.count).to eq(1)
    expect(AttendanceDay.where(company: company, recorded_method: "request").count).to eq(1)
  end

  it "only files for employees holding create permission" do
    stranger = create(:employee, company: company)

    expect { described_class.create_samples(company: company, employees: [ stranger ]) }
      .not_to change(AttendanceRequest, :count)
  end
end
