require "rails_helper"

RSpec.describe OrderGroupsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/order_groups").to route_to("order_groups#index")
    end

    it "routes to #new" do
      expect(get: "/order_groups/new").to route_to("order_groups#new")
    end

    it "routes to #show" do
      expect(get: "/order_groups/1").to route_to("order_groups#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/order_groups/1/edit").to route_to("order_groups#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/order_groups").to route_to("order_groups#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/order_groups/1").to route_to("order_groups#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/order_groups/1").to route_to("order_groups#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/order_groups/1").to route_to("order_groups#destroy", id: "1")
    end
  end
end
