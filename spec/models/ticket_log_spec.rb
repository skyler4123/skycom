require "rails_helper"

RSpec.describe TicketLog, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:ticket) }
    it { should belong_to(:actor).optional }
  end

  describe "validations" do
    it { should validate_presence_of(:action) }
  end
end