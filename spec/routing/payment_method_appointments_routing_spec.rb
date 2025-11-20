require "rails_helper"

RSpec.describe PaymentMethodAppointmentsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/payment_method_appointments").to route_to("payment_method_appointments#index")
    end

    it "routes to #new" do
      expect(get: "/payment_method_appointments/new").to route_to("payment_method_appointments#new")
    end

    it "routes to #show" do
      expect(get: "/payment_method_appointments/1").to route_to("payment_method_appointments#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/payment_method_appointments/1/edit").to route_to("payment_method_appointments#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/payment_method_appointments").to route_to("payment_method_appointments#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/payment_method_appointments/1").to route_to("payment_method_appointments#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/payment_method_appointments/1").to route_to("payment_method_appointments#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/payment_method_appointments/1").to route_to("payment_method_appointments#destroy", id: "1")
    end
  end
end
