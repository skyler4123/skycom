require 'rails_helper'

RSpec.describe "companies/edit", type: :view do
  let(:company) {
    Company.create!(
      name: "MyString",
      user: nil,
      parent_company: nil
    )
  }

  before(:each) do
    assign(:company, company)
  end

  it "renders the edit company form" do
    render

    assert_select "form[action=?][method=?]", company_path(company), "post" do

      assert_select "input[name=?]", "company[name]"

      assert_select "input[name=?]", "company[user_id]"

      assert_select "input[name=?]", "company[parent_company_id]"
    end
  end
end
