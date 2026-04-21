# spec/models/invoice_spec.rb
require 'rails_helper'

RSpec.describe Invoice, type: :model do
  describe "enums" do
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }
  end
end
