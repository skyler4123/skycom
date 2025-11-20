require 'rails_helper'

RSpec.describe "cart_groups/edit", type: :view do
  let(:cart_group) {
    CartGroup.create!(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:cart_group, cart_group)
  end

  it "renders the edit cart_group form" do
    render

    assert_select "form[action=?][method=?]", cart_group_path(cart_group), "post" do

      assert_select "input[name=?]", "cart_group[company_id]"

      assert_select "input[name=?]", "cart_group[name]"

      assert_select "input[name=?]", "cart_group[description]"

      assert_select "input[name=?]", "cart_group[code]"

      assert_select "input[name=?]", "cart_group[status]"

      assert_select "input[name=?]", "cart_group[business_type]"
    end
  end
end
