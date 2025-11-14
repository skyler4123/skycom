require "rails_helper"

RSpec.describe EmployeeGroupsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/employee_groups").to route_to("employee_groups#index")
    end

    it "routes to #new" do
      expect(get: "/employee_groups/new").to route_to("employee_groups#new")
    end

    it "routes to #show" do
      expect(get: "/employee_groups/1").to route_to("employee_groups#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/employee_groups/1/edit").to route_to("employee_groups#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/employee_groups").to route_to("employee_groups#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/employee_groups/1").to route_to("employee_groups#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/employee_groups/1").to route_to("employee_groups#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/employee_groups/1").to route_to("employee_groups#destroy", id: "1")
    end
  end
end
