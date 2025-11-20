require "rails_helper"

RSpec.describe CustomerGroupsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/customer_groups").to route_to("customer_groups#index")
    end

    it "routes to #new" do
      expect(get: "/customer_groups/new").to route_to("customer_groups#new")
    end

    it "routes to #show" do
      expect(get: "/customer_groups/1").to route_to("customer_groups#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/customer_groups/1/edit").to route_to("customer_groups#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/customer_groups").to route_to("customer_groups#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/customer_groups/1").to route_to("customer_groups#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/customer_groups/1").to route_to("customer_groups#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/customer_groups/1").to route_to("customer_groups#destroy", id: "1")
    end
  end
end
