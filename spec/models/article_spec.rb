# spec/models/article_spec.rb
require 'rails_helper'

RSpec.describe Article, type: :model do
  describe "associations" do
    it { should belong_to(:article_group) }
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should have_many(:tag_appointments).dependent(:destroy) }
    it { should have_many(:tags).through(:tag_appointments) }
  end
end