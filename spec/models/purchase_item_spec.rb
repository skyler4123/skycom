require 'rails_helper'

RSpec.describe PurchaseItem, type: :model do
  it_behaves_like "property_mapping concern", PurchaseItem
end
