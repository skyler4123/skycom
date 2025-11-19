require 'rails_helper'

RSpec.describe "customers/edit", type: :view do
  let(:customer) {
    Customer.create!(
      company: nil,
      name: "MyString",
      description: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:customer, customer)
  end

  it "renders the edit customer form" do
    render

    assert_select "form[action=?][method=?]", customer_path(customer), "post" do

      assert_select "input[name=?]", "customer[company_id]"

      assert_select "input[name=?]", "customer[name]"

      assert_select "input[name=?]", "customer[description]"

      assert_select "input[name=?]", "customer[status]"

      assert_select "input[name=?]", "customer[business_type]"
    end
  end
end
