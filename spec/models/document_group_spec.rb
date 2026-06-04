require 'rails_helper'

RSpec.describe DocumentGroup, type: :model do
  it_behaves_like "property_mapping concern", DocumentGroup
end
