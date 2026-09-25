# spec/models/article_group_employee_appointment_spec.rb
require "rails_helper"

RSpec.describe ArticleGroupEmployeeAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:article_group) }
    it { should belong_to(:employee) }
  end
end
