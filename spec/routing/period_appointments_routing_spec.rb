require "rails_helper"

RSpec.describe PeriodAppointmentsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/period_appointments").to route_to("period_appointments#index")
    end

    it "routes to #new" do
      expect(get: "/period_appointments/new").to route_to("period_appointments#new")
    end

    it "routes to #show" do
      expect(get: "/period_appointments/1").to route_to("period_appointments#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/period_appointments/1/edit").to route_to("period_appointments#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/period_appointments").to route_to("period_appointments#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/period_appointments/1").to route_to("period_appointments#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/period_appointments/1").to route_to("period_appointments#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/period_appointments/1").to route_to("period_appointments#destroy", id: "1")
    end
  end
end
