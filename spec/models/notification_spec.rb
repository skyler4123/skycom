require "rails_helper"

RSpec.describe Notification do
  let(:company) { create(:company) }

  it "belongs to company" do
    expect(Notification.new(company: company, title: "t")).to be_valid
  end
end
