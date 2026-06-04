require 'rails_helper'

RSpec.describe Question, type: :model do
  it_behaves_like "property_mapping concern", Question
end
