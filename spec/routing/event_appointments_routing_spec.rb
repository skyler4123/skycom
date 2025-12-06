require "rails_helper"

RSpec.describe EventAppointmentsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/event_appointments").to route_to("event_appointments#index")
    end

    it "routes to #new" do
      expect(get: "/event_appointments/new").to route_to("event_appointments#new")
    end

    it "routes to #show" do
      expect(get: "/event_appointments/1").to route_to("event_appointments#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/event_appointments/1/edit").to route_to("event_appointments#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/event_appointments").to route_to("event_appointments#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/event_appointments/1").to route_to("event_appointments#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/event_appointments/1").to route_to("event_appointments#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/event_appointments/1").to route_to("event_appointments#destroy", id: "1")
    end
  end
end
