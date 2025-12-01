require "rails_helper"

RSpec.describe SettingAppointmentsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/setting_appointments").to route_to("setting_appointments#index")
    end

    it "routes to #new" do
      expect(get: "/setting_appointments/new").to route_to("setting_appointments#new")
    end

    it "routes to #show" do
      expect(get: "/setting_appointments/1").to route_to("setting_appointments#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/setting_appointments/1/edit").to route_to("setting_appointments#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/setting_appointments").to route_to("setting_appointments#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/setting_appointments/1").to route_to("setting_appointments#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/setting_appointments/1").to route_to("setting_appointments#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/setting_appointments/1").to route_to("setting_appointments#destroy", id: "1")
    end
  end
end
