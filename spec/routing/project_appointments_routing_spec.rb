require "rails_helper"

RSpec.describe ProjectAppointmentsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/project_appointments").to route_to("project_appointments#index")
    end

    it "routes to #new" do
      expect(get: "/project_appointments/new").to route_to("project_appointments#new")
    end

    it "routes to #show" do
      expect(get: "/project_appointments/1").to route_to("project_appointments#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/project_appointments/1/edit").to route_to("project_appointments#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/project_appointments").to route_to("project_appointments#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/project_appointments/1").to route_to("project_appointments#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/project_appointments/1").to route_to("project_appointments#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/project_appointments/1").to route_to("project_appointments#destroy", id: "1")
    end
  end
end
