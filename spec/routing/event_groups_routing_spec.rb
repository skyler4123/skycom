require "rails_helper"

RSpec.describe EventGroupsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/event_groups").to route_to("event_groups#index")
    end

    it "routes to #new" do
      expect(get: "/event_groups/new").to route_to("event_groups#new")
    end

    it "routes to #show" do
      expect(get: "/event_groups/1").to route_to("event_groups#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/event_groups/1/edit").to route_to("event_groups#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/event_groups").to route_to("event_groups#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/event_groups/1").to route_to("event_groups#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/event_groups/1").to route_to("event_groups#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/event_groups/1").to route_to("event_groups#destroy", id: "1")
    end
  end
end
