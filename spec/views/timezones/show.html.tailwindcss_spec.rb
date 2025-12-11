require 'rails_helper'

RSpec.describe "timezones/show", type: :view do
  before(:each) do
    assign(:timezone, Timezone.create!(
      name: "Name",
      description: "Description",
      utc_offset: 2
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Description/)
    expect(rendered).to match(/2/)
  end
end
