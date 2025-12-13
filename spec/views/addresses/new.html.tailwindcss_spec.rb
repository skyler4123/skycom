require 'rails_helper'

RSpec.describe "addresses/new", type: :view do
  before(:each) do
    assign(:address, Address.new(
      alpha2: "MyString",
      alpha3: "MyString",
      continent: "MyString",
      nationality: "MyString",
      region: "MyString",
      longitude: "9.99",
      latitude: "9.99",
      level_total: 1,
      level_1: "MyString",
      level_2: "MyString",
      level_3: "MyString",
      level_4: "MyString",
      level_5: "MyString",
      level_6: "MyString",
      level_7: "MyString",
      level_8: "MyString",
      level_9: "MyString",
      level_10: "MyString"
    ))
  end

  it "renders new address form" do
    render

    assert_select "form[action=?][method=?]", addresses_path, "post" do
      assert_select "input[name=?]", "address[alpha2]"

      assert_select "input[name=?]", "address[alpha3]"

      assert_select "input[name=?]", "address[continent]"

      assert_select "input[name=?]", "address[nationality]"

      assert_select "input[name=?]", "address[region]"

      assert_select "input[name=?]", "address[longitude]"

      assert_select "input[name=?]", "address[latitude]"

      assert_select "input[name=?]", "address[level_total]"

      assert_select "input[name=?]", "address[level_1]"

      assert_select "input[name=?]", "address[level_2]"

      assert_select "input[name=?]", "address[level_3]"

      assert_select "input[name=?]", "address[level_4]"

      assert_select "input[name=?]", "address[level_5]"

      assert_select "input[name=?]", "address[level_6]"

      assert_select "input[name=?]", "address[level_7]"

      assert_select "input[name=?]", "address[level_8]"

      assert_select "input[name=?]", "address[level_9]"

      assert_select "input[name=?]", "address[level_10]"
    end
  end
end
