# spec/models/article_employee_appointment_spec.rb
require "rails_helper"

RSpec.describe ArticleEmployeeAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:article) }
    it { should belong_to(:employee) }
  end
end
