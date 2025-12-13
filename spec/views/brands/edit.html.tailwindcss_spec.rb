require 'rails_helper'

RSpec.describe "brands/edit", type: :view do
  let(:brand) {
    Brand.create!(
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:brand, brand)
  end

  it "renders the edit brand form" do
    render

    assert_select "form[action=?][method=?]", brand_path(brand), "post" do
      assert_select "input[name=?]", "brand[name]"

      assert_select "input[name=?]", "brand[description]"

      assert_select "input[name=?]", "brand[code]"

      assert_select "input[name=?]", "brand[status]"

      assert_select "input[name=?]", "brand[business_type]"
    end
  end
end
