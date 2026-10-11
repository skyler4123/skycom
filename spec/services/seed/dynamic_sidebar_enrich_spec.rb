require "rails_helper"

RSpec.describe "enrich seeds demo Quick Links for every company" do
  around do |example|
    Company.skip_init = false
    example.run
  ensure
    Company.skip_init = true
  end

  def run_sidebar_samples(service_class, company)
    service = service_class.allocate
    service.instance_variable_set(:@company, company)
    service.instance_variable_set(:@retail, company) if service_class == Seed::RetailEnrichService
    service.send(:create_dynamic_sidebar_samples)
  end

  describe "hospital enrich" do
    let(:company) { create(:company, business_type: :hospital) }

    it "fills the empty init record with demo Quick Links" do
      expect(Setting.find_by(company: company, code: DYNAMIC_SIDEBAR_CODE).sidebar_groups).to eq([])

      run_sidebar_samples(Seed::HospitalEnrichService, company)

      groups = Setting.find_by(company: company, code: DYNAMIC_SIDEBAR_CODE).reload.sidebar_groups
      expect(groups.size).to eq(1)
      expect(groups.first["name"]).to eq("Quick Links")
      names = groups.first["items"].map { |i| i["name"] }
      expect(names).to contain_exactly("Pending Orders", "All Stocks")
      urls = groups.first["items"].map { |i| i["url"] }
      expect(urls).to all(start_with("/companies/#{company.id}/"))
    end

    it "never clobbers existing groups" do
      record = Setting.find_by(company: company, code: DYNAMIC_SIDEBAR_CODE)
      record.update!(sidebar_groups: [ { "key" => "kept", "name" => "Kept", "items" => [] } ])

      run_sidebar_samples(Seed::HospitalEnrichService, company)

      expect(record.reload.sidebar_groups.map { |g| g["name"] }).to eq([ "Kept" ])
    end
  end

  describe "hotel enrich" do
    let(:company) { create(:company, business_type: :hotel) }

    it "fills the empty init record with demo Quick Links" do
      expect(Setting.find_by(company: company, code: DYNAMIC_SIDEBAR_CODE).sidebar_groups).to eq([])

      run_sidebar_samples(Seed::HotelEnrichService, company)

      groups = Setting.find_by(company: company, code: DYNAMIC_SIDEBAR_CODE).reload.sidebar_groups
      expect(groups.size).to eq(1)
      expect(groups.first["name"]).to eq("Quick Links")
      names = groups.first["items"].map { |i| i["name"] }
      expect(names).to contain_exactly("Pending Orders", "All Stocks")
    end

    it "never clobbers existing groups" do
      record = Setting.find_by(company: company, code: DYNAMIC_SIDEBAR_CODE)
      record.update!(sidebar_groups: [ { "key" => "kept", "name" => "Kept", "items" => [] } ])

      run_sidebar_samples(Seed::HotelEnrichService, company)

      expect(record.reload.sidebar_groups.map { |g| g["name"] }).to eq([ "Kept" ])
    end
  end
end
