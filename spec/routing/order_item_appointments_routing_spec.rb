require "rails_helper"

RSpec.describe OrderItemAppointmentsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/order_item_appointments").to route_to("order_item_appointments#index")
    end

    it "routes to #new" do
      expect(get: "/order_item_appointments/new").to route_to("order_item_appointments#new")
    end

    it "routes to #show" do
      expect(get: "/order_item_appointments/1").to route_to("order_item_appointments#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/order_item_appointments/1/edit").to route_to("order_item_appointments#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/order_item_appointments").to route_to("order_item_appointments#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/order_item_appointments/1").to route_to("order_item_appointments#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/order_item_appointments/1").to route_to("order_item_appointments#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/order_item_appointments/1").to route_to("order_item_appointments#destroy", id: "1")
    end
  end
end
