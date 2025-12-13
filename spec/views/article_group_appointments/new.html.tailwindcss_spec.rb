require 'rails_helper'

RSpec.describe "article_group_appointments/new", type: :view do
  before(:each) do
    assign(:article_group_appointment, ArticleGroupAppointment.new(
      article_group: nil,
      appoint_from: nil,
      appoint_to: nil,
      appoint_for: nil,
      appoint_by: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new article_group_appointment form" do
    render

    assert_select "form[action=?][method=?]", article_group_appointments_path, "post" do
      assert_select "input[name=?]", "article_group_appointment[article_group_id]"

      assert_select "input[name=?]", "article_group_appointment[appoint_from_id]"

      assert_select "input[name=?]", "article_group_appointment[appoint_to_id]"

      assert_select "input[name=?]", "article_group_appointment[appoint_for_id]"

      assert_select "input[name=?]", "article_group_appointment[appoint_by_id]"

      assert_select "input[name=?]", "article_group_appointment[name]"

      assert_select "input[name=?]", "article_group_appointment[description]"

      assert_select "input[name=?]", "article_group_appointment[code]"

      assert_select "input[name=?]", "article_group_appointment[status]"

      assert_select "input[name=?]", "article_group_appointment[business_type]"
    end
  end
end
