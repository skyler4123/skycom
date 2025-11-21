require "rails_helper"

RSpec.describe NotificationAppointmentsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/notification_appointments").to route_to("notification_appointments#index")
    end

    it "routes to #new" do
      expect(get: "/notification_appointments/new").to route_to("notification_appointments#new")
    end

    it "routes to #show" do
      expect(get: "/notification_appointments/1").to route_to("notification_appointments#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/notification_appointments/1/edit").to route_to("notification_appointments#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/notification_appointments").to route_to("notification_appointments#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/notification_appointments/1").to route_to("notification_appointments#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/notification_appointments/1").to route_to("notification_appointments#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/notification_appointments/1").to route_to("notification_appointments#destroy", id: "1")
    end
  end
end
