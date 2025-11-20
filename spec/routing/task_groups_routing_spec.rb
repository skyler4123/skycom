require "rails_helper"

RSpec.describe TaskGroupsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/task_groups").to route_to("task_groups#index")
    end

    it "routes to #new" do
      expect(get: "/task_groups/new").to route_to("task_groups#new")
    end

    it "routes to #show" do
      expect(get: "/task_groups/1").to route_to("task_groups#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/task_groups/1/edit").to route_to("task_groups#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/task_groups").to route_to("task_groups#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/task_groups/1").to route_to("task_groups#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/task_groups/1").to route_to("task_groups#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/task_groups/1").to route_to("task_groups#destroy", id: "1")
    end
  end
end
