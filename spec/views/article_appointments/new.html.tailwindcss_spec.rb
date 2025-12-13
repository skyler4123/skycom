require 'rails_helper'

RSpec.describe "article_appointments/new", type: :view do
  before(:each) do
    assign(:article_appointment, ArticleAppointment.new(
      article: nil,
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

  it "renders new article_appointment form" do
    render

    assert_select "form[action=?][method=?]", article_appointments_path, "post" do
      assert_select "input[name=?]", "article_appointment[article_id]"

      assert_select "input[name=?]", "article_appointment[appoint_from_id]"

      assert_select "input[name=?]", "article_appointment[appoint_to_id]"

      assert_select "input[name=?]", "article_appointment[appoint_for_id]"

      assert_select "input[name=?]", "article_appointment[appoint_by_id]"

      assert_select "input[name=?]", "article_appointment[name]"

      assert_select "input[name=?]", "article_appointment[description]"

      assert_select "input[name=?]", "article_appointment[code]"

      assert_select "input[name=?]", "article_appointment[status]"

      assert_select "input[name=?]", "article_appointment[business_type]"
    end
  end
end
