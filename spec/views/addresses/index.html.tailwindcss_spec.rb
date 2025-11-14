require 'rails_helper'

RSpec.describe "addresses/index", type: :view do
  before(:each) do
    assign(:addresses, [
      Address.create!(
        alpha2: "Alpha2",
        alpha3: "Alpha3",
        continent: "Continent",
        nationality: "Nationality",
        region: "Region",
        longitude: "9.99",
        latitude: "9.99",
        level_total: 2,
        level_1: "Level 1",
        level_2: "Level 2",
        level_3: "Level 3",
        level_4: "Level 4",
        level_5: "Level 5",
        level_6: "Level 6",
        level_7: "Level 7",
        level_8: "Level 8",
        level_9: "Level 9",
        level_10: "Level 10"
      ),
      Address.create!(
        alpha2: "Alpha2",
        alpha3: "Alpha3",
        continent: "Continent",
        nationality: "Nationality",
        region: "Region",
        longitude: "9.99",
        latitude: "9.99",
        level_total: 2,
        level_1: "Level 1",
        level_2: "Level 2",
        level_3: "Level 3",
        level_4: "Level 4",
        level_5: "Level 5",
        level_6: "Level 6",
        level_7: "Level 7",
        level_8: "Level 8",
        level_9: "Level 9",
        level_10: "Level 10"
      )
    ])
  end

  it "renders a list of addresses" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Alpha2".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Alpha3".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Continent".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Nationality".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Region".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Level 1".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Level 2".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Level 3".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Level 4".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Level 5".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Level 6".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Level 7".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Level 8".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Level 9".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Level 10".to_s), count: 2
  end
end
