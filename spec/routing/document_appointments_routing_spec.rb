require "rails_helper"

RSpec.describe DocumentAppointmentsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/document_appointments").to route_to("document_appointments#index")
    end

    it "routes to #new" do
      expect(get: "/document_appointments/new").to route_to("document_appointments#new")
    end

    it "routes to #show" do
      expect(get: "/document_appointments/1").to route_to("document_appointments#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/document_appointments/1/edit").to route_to("document_appointments#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/document_appointments").to route_to("document_appointments#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/document_appointments/1").to route_to("document_appointments#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/document_appointments/1").to route_to("document_appointments#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/document_appointments/1").to route_to("document_appointments#destroy", id: "1")
    end
  end
end
