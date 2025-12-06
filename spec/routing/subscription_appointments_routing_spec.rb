require "rails_helper"

RSpec.describe SubscriptionAppointmentsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/subscription_appointments").to route_to("subscription_appointments#index")
    end

    it "routes to #new" do
      expect(get: "/subscription_appointments/new").to route_to("subscription_appointments#new")
    end

    it "routes to #show" do
      expect(get: "/subscription_appointments/1").to route_to("subscription_appointments#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/subscription_appointments/1/edit").to route_to("subscription_appointments#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/subscription_appointments").to route_to("subscription_appointments#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/subscription_appointments/1").to route_to("subscription_appointments#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/subscription_appointments/1").to route_to("subscription_appointments#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/subscription_appointments/1").to route_to("subscription_appointments#destroy", id: "1")
    end
  end
end
