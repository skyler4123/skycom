require 'rails_helper'

RSpec.describe Membership, type: :model do
  it_behaves_like "property_mapping concern", Membership
end
