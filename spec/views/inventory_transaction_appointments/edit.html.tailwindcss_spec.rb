require 'rails_helper'

RSpec.describe "inventory_transaction_appointments/edit", type: :view do
  let(:inventory_transaction_appointment) {
    InventoryTransactionAppointment.create!(
      inventory_transaction: nil,
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
    assign(:inventory_transaction_appointment, inventory_transaction_appointment)
  end

  it "renders the edit inventory_transaction_appointment form" do
    render

    assert_select "form[action=?][method=?]", inventory_transaction_appointment_path(inventory_transaction_appointment), "post" do

      assert_select "input[name=?]", "inventory_transaction_appointment[inventory_transaction_id]"

      assert_select "input[name=?]", "inventory_transaction_appointment[appoint_from_id]"

      assert_select "input[name=?]", "inventory_transaction_appointment[appoint_to_id]"

      assert_select "input[name=?]", "inventory_transaction_appointment[appoint_for_id]"

      assert_select "input[name=?]", "inventory_transaction_appointment[appoint_by_id]"

      assert_select "input[name=?]", "inventory_transaction_appointment[name]"

      assert_select "input[name=?]", "inventory_transaction_appointment[description]"

      assert_select "input[name=?]", "inventory_transaction_appointment[code]"

      assert_select "input[name=?]", "inventory_transaction_appointment[status]"

      assert_select "input[name=?]", "inventory_transaction_appointment[business_type]"
    end
  end
end
