require 'rails_helper'

RSpec.describe "purchases/edit", type: :view do
  let(:purchase) {
    Purchase.create!(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:purchase, purchase)
  end

  it "renders the edit purchase form" do
    render

    assert_select "form[action=?][method=?]", purchase_path(purchase), "post" do
      assert_select "input[name=?]", "purchase[company_id]"

      assert_select "input[name=?]", "purchase[name]"

      assert_select "input[name=?]", "purchase[description]"

      assert_select "input[name=?]", "purchase[code]"

      assert_select "input[name=?]", "purchase[status]"

      assert_select "input[name=?]", "purchase[business_type]"
    end
  end
end
