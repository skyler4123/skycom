require 'rails_helper'

RSpec.describe TaskGroup, type: :model do
  it_behaves_like "property_mapping concern", TaskGroup
end
