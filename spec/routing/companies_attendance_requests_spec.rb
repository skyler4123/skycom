# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::AttendanceRequests routes", type: :routing do
  let(:company_id) { "01a11c12-7229-76d1-85ae-2f45037df89c" }
  let(:id) { "01a11c12-73a8-7768-bfa0-bee15b5ee278" }

  it "routes index/show/new/create + approve/reject only" do
    expect(get: "/companies/#{company_id}/attendance_requests").to be_routable
    expect(get: "/companies/#{company_id}/attendance_requests/#{id}").to be_routable
    expect(post: "/companies/#{company_id}/attendance_requests/#{id}/approve").to be_routable
    expect(post: "/companies/#{company_id}/attendance_requests/#{id}/reject").to be_routable
  end

  it "does not route edit/update/destroy" do
    expect(get: "/companies/#{company_id}/attendance_requests/#{id}/edit").not_to be_routable
    expect(patch: "/companies/#{company_id}/attendance_requests/#{id}").not_to be_routable
    expect(delete: "/companies/#{company_id}/attendance_requests/#{id}").not_to be_routable
  end
end
