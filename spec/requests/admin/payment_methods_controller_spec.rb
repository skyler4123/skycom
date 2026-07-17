require "rails_helper"

RSpec.describe "Admin::PaymentMethods", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:company_owner) { create(:user, :company_owner) }
  let!(:payment_method1) { create(:payment_method, business_type: :b2c, country: 840) }
  let!(:payment_method2) { create(:payment_method, business_type: :b2b, country: 704) }

  let(:json_headers) { { "ACCEPT" => "application/json" } }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET /admin/payment_methods" do
    context "when signed in as admin" do
      before do
        get sign_in_for_test_path(email: admin.email)
      end

      it "returns 200 with JSON array of payment methods" do
        get "/admin/payment_methods", headers: json_headers

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["payment_methods"]).to be_an(Array)
        expect(body["payment_methods"].length).to be >= 2
      end

      it "includes pagination data" do
        get "/admin/payment_methods", headers: json_headers

        body = JSON.parse(response.body)
        expect(body["pagination"]).to be_present
      end

      it "returns payment method fields" do
        get "/admin/payment_methods", headers: json_headers

        body = JSON.parse(response.body)
        pm = body["payment_methods"].find { |p| p["id"] == payment_method1.id }
        expect(pm).to be_present
        expect(pm).to have_key("name")
        expect(pm).to have_key("code")
        expect(pm).to have_key("business_type")
        expect(pm).to have_key("country")
        expect(pm).to have_key("lifecycle_status")
      end
    end

    context "when signed in as non-admin" do
      before do
        get sign_in_for_test_path(email: company_owner.email)
      end

      it "redirects to root" do
        get "/admin/payment_methods"

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(root_path)
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        get "/admin/payment_methods"

        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "GET /admin/payment_methods/new" do
    context "when signed in as admin" do
      before do
        get sign_in_for_test_path(email: admin.email)
      end

      it "returns 200" do
        get "/admin/payment_methods/new", headers: json_headers

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /admin/payment_methods" do
    context "when signed in as admin" do
      before do
        get sign_in_for_test_path(email: admin.email)
      end

      it "creates a new payment method and redirects to index" do
        post "/admin/payment_methods", params: {
          payment_method: {
            name: "Test Method",
            code: "TEST_METHOD",
            business_type: "b2c",
            country: "us",
            payment_mode: "redirect",
            gateway_url: "http://localhost:4000/api/v1/bank/redirect-session"
          }
        }

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(admin_payment_methods_path)
        expect(PaymentMethod.find_by(code: "TEST_METHOD")).to be_present
      end

      it "fails with validation errors and redirects with alert" do
        post "/admin/payment_methods", params: {
          payment_method: {
            name: "",
            code: "",
            business_type: "b2c",
            country: "us",
            payment_mode: ""
          }
        }

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_admin_payment_method_path)
      end
    end
  end

  describe "GET /admin/payment_methods/:id/edit" do
    context "when signed in as admin" do
      before do
        get sign_in_for_test_path(email: admin.email)
      end

      it "returns 200 with payment method JSON" do
        get "/admin/payment_methods/#{payment_method1.id}/edit", headers: json_headers

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["payment_method"]).to be_present
        expect(body["payment_method"]["id"]).to eq(payment_method1.id)
        expect(body["payment_method"]["name"]).to eq(payment_method1.name)
      end

      it "returns 404 for non-existent payment method" do
        get "/admin/payment_methods/non-existent-id/edit", headers: json_headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /admin/payment_methods/:id" do
    context "when signed in as admin" do
      before do
        get sign_in_for_test_path(email: admin.email)
      end

      it "updates the payment method and redirects to index" do
        patch "/admin/payment_methods/#{payment_method1.id}", params: {
          payment_method: { name: "Updated Name" }
        }

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(admin_payment_methods_path)
        expect(payment_method1.reload.name).to eq("Updated Name")
      end

      it "fails with validation errors and redirects with alert" do
        patch "/admin/payment_methods/#{payment_method1.id}", params: {
          payment_method: { name: "" }
        }

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(edit_admin_payment_method_path(payment_method1))
      end
    end
  end
end
