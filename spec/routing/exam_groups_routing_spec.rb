require "rails_helper"

RSpec.describe ExamGroupsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/exam_groups").to route_to("exam_groups#index")
    end

    it "routes to #new" do
      expect(get: "/exam_groups/new").to route_to("exam_groups#new")
    end

    it "routes to #show" do
      expect(get: "/exam_groups/1").to route_to("exam_groups#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/exam_groups/1/edit").to route_to("exam_groups#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/exam_groups").to route_to("exam_groups#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/exam_groups/1").to route_to("exam_groups#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/exam_groups/1").to route_to("exam_groups#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/exam_groups/1").to route_to("exam_groups#destroy", id: "1")
    end
  end
end
