require 'rails_helper'

RSpec.describe "addresses/show", type: :view do
  before(:each) do
    assign(:address, Address.create!(
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
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Alpha2/)
    expect(rendered).to match(/Alpha3/)
    expect(rendered).to match(/Continent/)
    expect(rendered).to match(/Nationality/)
    expect(rendered).to match(/Region/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/Level 1/)
    expect(rendered).to match(/Level 2/)
    expect(rendered).to match(/Level 3/)
    expect(rendered).to match(/Level 4/)
    expect(rendered).to match(/Level 5/)
    expect(rendered).to match(/Level 6/)
    expect(rendered).to match(/Level 7/)
    expect(rendered).to match(/Level 8/)
    expect(rendered).to match(/Level 9/)
    expect(rendered).to match(/Level 10/)
  end
end
