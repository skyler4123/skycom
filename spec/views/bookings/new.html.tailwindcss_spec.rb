require 'rails_helper'

RSpec.describe "bookings/new", type: :view do
  before(:each) do
    assign(:booking, Booking.new(
      company: nil,
      appoint_from: nil,
      appoint_to: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new booking form" do
    render

    assert_select "form[action=?][method=?]", bookings_path, "post" do
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
