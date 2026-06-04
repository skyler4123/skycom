require 'rails_helper'

RSpec.describe Answer, type: :model do
  it_behaves_like "property_mapping concern", Answer
end
