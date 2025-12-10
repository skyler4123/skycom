require "rails_helper"

RSpec.describe ArticleGroupsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/article_groups").to route_to("article_groups#index")
    end

    it "routes to #new" do
      expect(get: "/article_groups/new").to route_to("article_groups#new")
    end

    it "routes to #show" do
      expect(get: "/article_groups/1").to route_to("article_groups#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/article_groups/1/edit").to route_to("article_groups#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/article_groups").to route_to("article_groups#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/article_groups/1").to route_to("article_groups#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/article_groups/1").to route_to("article_groups#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/article_groups/1").to route_to("article_groups#destroy", id: "1")
    end
  end
end
