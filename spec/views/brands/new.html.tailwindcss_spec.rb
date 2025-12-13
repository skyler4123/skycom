require 'rails_helper'

RSpec.describe "brands/new", type: :view do
  before(:each) do
    assign(:brand, Brand.new(
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new brand form" do
    render

    assert_select "form[action=?][method=?]", brands_path, "post" do
      assert_select "input[name=?]", "brand[name]"

      assert_select "input[name=?]", "brand[description]"

      assert_select "input[name=?]", "brand[code]"

      assert_select "input[name=?]", "brand[status]"

      assert_select "input[name=?]", "brand[business_type]"
    end
  end
end
