require "rails_helper"

RSpec.describe CustomerAppointmentsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/customer_appointments").to route_to("customer_appointments#index")
    end

    it "routes to #new" do
      expect(get: "/customer_appointments/new").to route_to("customer_appointments#new")
    end

    it "routes to #show" do
      expect(get: "/customer_appointments/1").to route_to("customer_appointments#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/customer_appointments/1/edit").to route_to("customer_appointments#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/customer_appointments").to route_to("customer_appointments#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/customer_appointments/1").to route_to("customer_appointments#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/customer_appointments/1").to route_to("customer_appointments#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/customer_appointments/1").to route_to("customer_appointments#destroy", id: "1")
    end
  end
end
