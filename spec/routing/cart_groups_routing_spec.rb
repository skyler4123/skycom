require "rails_helper"

RSpec.describe CartGroupsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/cart_groups").to route_to("cart_groups#index")
    end

    it "routes to #new" do
      expect(get: "/cart_groups/new").to route_to("cart_groups#new")
    end

    it "routes to #show" do
      expect(get: "/cart_groups/1").to route_to("cart_groups#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/cart_groups/1/edit").to route_to("cart_groups#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/cart_groups").to route_to("cart_groups#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/cart_groups/1").to route_to("cart_groups#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/cart_groups/1").to route_to("cart_groups#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/cart_groups/1").to route_to("cart_groups#destroy", id: "1")
    end
  end
end
