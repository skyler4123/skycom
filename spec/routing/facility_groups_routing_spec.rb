require "rails_helper"

RSpec.describe FacilityGroupsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/facility_groups").to route_to("facility_groups#index")
    end

    it "routes to #new" do
      expect(get: "/facility_groups/new").to route_to("facility_groups#new")
    end

    it "routes to #show" do
      expect(get: "/facility_groups/1").to route_to("facility_groups#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/facility_groups/1/edit").to route_to("facility_groups#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/facility_groups").to route_to("facility_groups#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/facility_groups/1").to route_to("facility_groups#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/facility_groups/1").to route_to("facility_groups#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/facility_groups/1").to route_to("facility_groups#destroy", id: "1")
    end
  end
end
