require 'rails_helper'

RSpec.describe "bookings/edit", type: :view do
  let(:booking) {
    Booking.create!(
      company: nil,
      appoint_from: nil,
      appoint_to: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:booking, booking)
  end

  it "renders the edit booking form" do
    render

    assert_select "form[action=?][method=?]", booking_path(booking), "post" do

      assert_select "input[name=?]", "booking[company_id]"

      assert_select "input[name=?]", "booking[appoint_from_id]"

      assert_select "input[name=?]", "booking[appoint_to_id]"

      assert_select "input[name=?]", "booking[name]"

      assert_select "input[name=?]", "booking[description]"

      assert_select "input[name=?]", "booking[code]"

      assert_select "input[name=?]", "booking[status]"

      assert_select "input[name=?]", "booking[business_type]"
    end
  end
end
