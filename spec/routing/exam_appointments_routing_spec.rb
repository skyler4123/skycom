require "rails_helper"

RSpec.describe ExamAppointmentsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/exam_appointments").to route_to("exam_appointments#index")
    end

    it "routes to #new" do
      expect(get: "/exam_appointments/new").to route_to("exam_appointments#new")
    end

    it "routes to #show" do
      expect(get: "/exam_appointments/1").to route_to("exam_appointments#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/exam_appointments/1/edit").to route_to("exam_appointments#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/exam_appointments").to route_to("exam_appointments#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/exam_appointments/1").to route_to("exam_appointments#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/exam_appointments/1").to route_to("exam_appointments#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/exam_appointments/1").to route_to("exam_appointments#destroy", id: "1")
    end
  end
end
