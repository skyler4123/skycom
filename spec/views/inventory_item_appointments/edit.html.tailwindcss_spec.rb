require 'rails_helper'

RSpec.describe "inventory_item_appointments/edit", type: :view do
  let(:inventory_item_appointment) {
    InventoryItemAppointment.create!(
      inventory_item: nil,
      appoint_from: nil,
      appoint_to: nil,
      appoint_for: nil,
      appoint_by: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:inventory_item_appointment, inventory_item_appointment)
  end

  it "renders the edit inventory_item_appointment form" do
    render

    assert_select "form[action=?][method=?]", inventory_item_appointment_path(inventory_item_appointment), "post" do
      assert_select "input[name=?]", "inventory_item_appointment[inventory_item_id]"

      assert_select "input[name=?]", "inventory_item_appointment[appoint_from_id]"

      assert_select "input[name=?]", "inventory_item_appointment[appoint_to_id]"

      assert_select "input[name=?]", "inventory_item_appointment[appoint_for_id]"

      assert_select "input[name=?]", "inventory_item_appointment[appoint_by_id]"

      assert_select "input[name=?]", "inventory_item_appointment[name]"

      assert_select "input[name=?]", "inventory_item_appointment[description]"

      assert_select "input[name=?]", "inventory_item_appointment[code]"

      assert_select "input[name=?]", "inventory_item_appointment[status]"

      assert_select "input[name=?]", "inventory_item_appointment[business_type]"
    end
  end
end
