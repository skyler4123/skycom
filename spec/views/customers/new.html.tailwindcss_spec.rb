require 'rails_helper'

RSpec.describe "customers/new", type: :view do
  before(:each) do
    assign(:customer, Customer.new(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new customer form" do
    render

    assert_select "form[action=?][method=?]", customers_path, "post" do
      assert_select "input[name=?]", "customer[company_id]"

      assert_select "input[name=?]", "customer[name]"

      assert_select "input[name=?]", "customer[description]"

      assert_select "input[name=?]", "customer[code]"

      assert_select "input[name=?]", "customer[status]"

      assert_select "input[name=?]", "customer[business_type]"
    end
  end
end
