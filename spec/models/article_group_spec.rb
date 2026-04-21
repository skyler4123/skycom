# spec/models/article_group_spec.rb
require 'rails_helper'

RSpec.describe ArticleGroup, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should have_many(:tag_appointments).dependent(:destroy) }
    it { should have_many(:tags).through(:tag_appointments) }
  end
end
