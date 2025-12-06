require "rails_helper"

RSpec.describe SettingGroupsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/setting_groups").to route_to("setting_groups#index")
    end

    it "routes to #new" do
      expect(get: "/setting_groups/new").to route_to("setting_groups#new")
    end

    it "routes to #show" do
      expect(get: "/setting_groups/1").to route_to("setting_groups#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/setting_groups/1/edit").to route_to("setting_groups#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/setting_groups").to route_to("setting_groups#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/setting_groups/1").to route_to("setting_groups#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/setting_groups/1").to route_to("setting_groups#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/setting_groups/1").to route_to("setting_groups#destroy", id: "1")
    end
  end
end
