require "rails_helper"

RSpec.describe CartAppointmentsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/cart_appointments").to route_to("cart_appointments#index")
    end

    it "routes to #new" do
      expect(get: "/cart_appointments/new").to route_to("cart_appointments#new")
    end

    it "routes to #show" do
      expect(get: "/cart_appointments/1").to route_to("cart_appointments#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/cart_appointments/1/edit").to route_to("cart_appointments#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/cart_appointments").to route_to("cart_appointments#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/cart_appointments/1").to route_to("cart_appointments#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/cart_appointments/1").to route_to("cart_appointments#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/cart_appointments/1").to route_to("cart_appointments#destroy", id: "1")
    end
  end
end
