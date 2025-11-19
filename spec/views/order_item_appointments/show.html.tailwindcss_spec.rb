require 'rails_helper'

RSpec.describe "order_item_appointments/show", type: :view do
  before(:each) do
    assign(:order_item_appointment, OrderItemAppointment.create!(
      order: nil,
      appoint_to: nil,
      unit_price: "9.99",
      quantity: 2,
      total_price: "9.99",
      name: "Name",
      description: "Description",
      status: 3,
      business_type: 4
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Description/)
    expect(rendered).to match(/3/)
    expect(rendered).to match(/4/)
  end
end
