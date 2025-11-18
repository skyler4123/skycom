require "rails_helper"

RSpec.describe ProductBrandsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/product_brands").to route_to("product_brands#index")
    end

    it "routes to #new" do
      expect(get: "/product_brands/new").to route_to("product_brands#new")
    end

    it "routes to #show" do
      expect(get: "/product_brands/1").to route_to("product_brands#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/product_brands/1/edit").to route_to("product_brands#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/product_brands").to route_to("product_brands#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/product_brands/1").to route_to("product_brands#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/product_brands/1").to route_to("product_brands#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/product_brands/1").to route_to("product_brands#destroy", id: "1")
    end
  end
end
