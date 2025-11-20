require "rails_helper"

RSpec.describe ServiceGroupsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/service_groups").to route_to("service_groups#index")
    end

    it "routes to #new" do
      expect(get: "/service_groups/new").to route_to("service_groups#new")
    end

    it "routes to #show" do
      expect(get: "/service_groups/1").to route_to("service_groups#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/service_groups/1/edit").to route_to("service_groups#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/service_groups").to route_to("service_groups#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/service_groups/1").to route_to("service_groups#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/service_groups/1").to route_to("service_groups#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/service_groups/1").to route_to("service_groups#destroy", id: "1")
    end
  end
end
