require 'rails_helper'

RSpec.describe Purchase, type: :model do
  it_behaves_like "property_mapping concern", Purchase
end
