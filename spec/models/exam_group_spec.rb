require 'rails_helper'

RSpec.describe ExamGroup, type: :model do
  it_behaves_like "property_mapping concern", ExamGroup
end
