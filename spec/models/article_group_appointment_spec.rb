# spec/models/article_group_appointment_spec.rb
require 'rails_helper'

RSpec.describe ArticleGroupAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:article_group) }
    it { should belong_to(:appoint_from) }
    it { should belong_to(:appoint_to) }
    it { should belong_to(:appoint_for) }
    it { should belong_to(:appoint_by) }
  end
end