require "rails_helper"

RSpec.describe ProductAppointmentsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/product_appointments").to route_to("product_appointments#index")
    end

    it "routes to #new" do
      expect(get: "/product_appointments/new").to route_to("product_appointments#new")
    end

    it "routes to #show" do
      expect(get: "/product_appointments/1").to route_to("product_appointments#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/product_appointments/1/edit").to route_to("product_appointments#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/product_appointments").to route_to("product_appointments#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/product_appointments/1").to route_to("product_appointments#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/product_appointments/1").to route_to("product_appointments#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/product_appointments/1").to route_to("product_appointments#destroy", id: "1")
    end
  end
end
