require "rails_helper"

RSpec.describe RoleAppointmentsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/role_appointments").to route_to("role_appointments#index")
    end

    it "routes to #new" do
      expect(get: "/role_appointments/new").to route_to("role_appointments#new")
    end

    it "routes to #show" do
      expect(get: "/role_appointments/1").to route_to("role_appointments#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/role_appointments/1/edit").to route_to("role_appointments#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/role_appointments").to route_to("role_appointments#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/role_appointments/1").to route_to("role_appointments#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/role_appointments/1").to route_to("role_appointments#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/role_appointments/1").to route_to("role_appointments#destroy", id: "1")
    end
  end
end
