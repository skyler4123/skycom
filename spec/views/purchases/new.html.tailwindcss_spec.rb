require 'rails_helper'

RSpec.describe "purchases/new", type: :view do
  before(:each) do
    assign(:purchase, Purchase.new(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new purchase form" do
    render

    assert_select "form[action=?][method=?]", purchases_path, "post" do
      assert_select "input[name=?]", "purchase[company_id]"

      assert_select "input[name=?]", "purchase[name]"

      assert_select "input[name=?]", "purchase[description]"

      assert_select "input[name=?]", "purchase[code]"

      assert_select "input[name=?]", "purchase[status]"

      assert_select "input[name=?]", "purchase[business_type]"
    end
  end
end
