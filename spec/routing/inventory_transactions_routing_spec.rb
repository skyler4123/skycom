require "rails_helper"

RSpec.describe InventoryTransactionsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/inventory_transactions").to route_to("inventory_transactions#index")
    end

    it "routes to #new" do
      expect(get: "/inventory_transactions/new").to route_to("inventory_transactions#new")
    end

    it "routes to #show" do
      expect(get: "/inventory_transactions/1").to route_to("inventory_transactions#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/inventory_transactions/1/edit").to route_to("inventory_transactions#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/inventory_transactions").to route_to("inventory_transactions#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/inventory_transactions/1").to route_to("inventory_transactions#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/inventory_transactions/1").to route_to("inventory_transactions#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/inventory_transactions/1").to route_to("inventory_transactions#destroy", id: "1")
    end
  end
end
