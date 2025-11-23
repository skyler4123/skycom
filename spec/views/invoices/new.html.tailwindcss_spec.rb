require 'rails_helper'

RSpec.describe "invoices/new", type: :view do
  before(:each) do
    assign(:invoice, Invoice.new(
      order: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      currency: 1,
      duration: 1,
      number: "MyString",
      total: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new invoice form" do
    render

    assert_select "form[action=?][method=?]", invoices_path, "post" do

      assert_select "input[name=?]", "invoice[order_id]"

      assert_select "input[name=?]", "invoice[name]"

      assert_select "input[name=?]", "invoice[description]"

      assert_select "input[name=?]", "invoice[code]"

      assert_select "input[name=?]", "invoice[currency]"

      assert_select "input[name=?]", "invoice[duration]"

      assert_select "input[name=?]", "invoice[number]"

      assert_select "input[name=?]", "invoice[total]"

      assert_select "input[name=?]", "invoice[status]"

      assert_select "input[name=?]", "invoice[business_type]"
    end
  end
end
