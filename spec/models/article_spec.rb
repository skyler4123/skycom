# spec/models/article_spec.rb
require 'rails_helper'

RSpec.describe Article, type: :model do
  describe "associations" do
    it { should belong_to(:article_group) }
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should have_many(:article_tag_appointments).dependent(:destroy) }
    it { should have_many(:tags).through(:article_tag_appointments) }
  end
  it_behaves_like "property_mapping concern", Article
end
