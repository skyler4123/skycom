require "rails_helper"

RSpec.describe TimezonesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/timezones").to route_to("timezones#index")
    end

    it "routes to #new" do
      expect(get: "/timezones/new").to route_to("timezones#new")
    end

    it "routes to #show" do
      expect(get: "/timezones/1").to route_to("timezones#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/timezones/1/edit").to route_to("timezones#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/timezones").to route_to("timezones#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/timezones/1").to route_to("timezones#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/timezones/1").to route_to("timezones#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/timezones/1").to route_to("timezones#destroy", id: "1")
    end
  end
end
