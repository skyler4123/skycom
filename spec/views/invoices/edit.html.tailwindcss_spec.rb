require 'rails_helper'

RSpec.describe "invoices/edit", type: :view do
  let(:invoice) {
    Invoice.create!(
      order: nil,
      name: "MyString",
      description: "MyString",
      currency: "MyString",
      number: "MyString",
      total: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:invoice, invoice)
  end

  it "renders the edit invoice form" do
    render

    assert_select "form[action=?][method=?]", invoice_path(invoice), "post" do

      assert_select "input[name=?]", "invoice[order_id]"

      assert_select "input[name=?]", "invoice[name]"

      assert_select "input[name=?]", "invoice[description]"

      assert_select "input[name=?]", "invoice[currency]"

      assert_select "input[name=?]", "invoice[number]"

      assert_select "input[name=?]", "invoice[total]"

      assert_select "input[name=?]", "invoice[status]"

      assert_select "input[name=?]", "invoice[business_type]"
    end
  end
end
