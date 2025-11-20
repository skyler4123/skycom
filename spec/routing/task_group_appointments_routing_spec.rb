require "rails_helper"

RSpec.describe TaskGroupAppointmentsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/task_group_appointments").to route_to("task_group_appointments#index")
    end

    it "routes to #new" do
      expect(get: "/task_group_appointments/new").to route_to("task_group_appointments#new")
    end

    it "routes to #show" do
      expect(get: "/task_group_appointments/1").to route_to("task_group_appointments#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/task_group_appointments/1/edit").to route_to("task_group_appointments#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/task_group_appointments").to route_to("task_group_appointments#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/task_group_appointments/1").to route_to("task_group_appointments#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/task_group_appointments/1").to route_to("task_group_appointments#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/task_group_appointments/1").to route_to("task_group_appointments#destroy", id: "1")
    end
  end
end
