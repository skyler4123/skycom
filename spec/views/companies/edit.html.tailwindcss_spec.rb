require 'rails_helper'

RSpec.describe "companies/edit", type: :view do
  let(:company) {
    Company.create!(
      user: nil,
      parent_company: nil,
      name: "MyString",
      description: "MyString",
      status: 1,
      kind: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:company, company)
  end

  it "renders the edit company form" do
    render

    assert_select "form[action=?][method=?]", company_path(company), "post" do

      assert_select "input[name=?]", "company[user_id]"

      assert_select "input[name=?]", "company[parent_company_id]"

      assert_select "input[name=?]", "company[name]"

      assert_select "input[name=?]", "company[description]"

      assert_select "input[name=?]", "company[status]"

      assert_select "input[name=?]", "company[kind]"

      assert_select "input[name=?]", "company[business_type]"
    end
  end
end
