# spec/models/category_spec.rb
require 'rails_helper'

RSpec.describe Category, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should have_many(:employee_groups).dependent(:nullify) }
    it { should have_many(:employees).dependent(:nullify) }
    it { should have_many(:departments).dependent(:nullify) }
  end
end
