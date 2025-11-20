require "rails_helper"

RSpec.describe PeriodsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/periods").to route_to("periods#index")
    end

    it "routes to #new" do
      expect(get: "/periods/new").to route_to("periods#new")
    end

    it "routes to #show" do
      expect(get: "/periods/1").to route_to("periods#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/periods/1/edit").to route_to("periods#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/periods").to route_to("periods#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/periods/1").to route_to("periods#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/periods/1").to route_to("periods#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/periods/1").to route_to("periods#destroy", id: "1")
    end
  end
end
