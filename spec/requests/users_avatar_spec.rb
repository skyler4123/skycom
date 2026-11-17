require "rails_helper"

RSpec.describe "Users avatar (PATCH /users/update_avatar)", type: :request do
  let(:user) { create(:user) }
  let(:jpeg_path) { Rails.root.join("faker/images/randoms/685-200x200.jpg").to_s }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  before do
    get sign_in_for_test_path(email: user.email)
  end

  it "attaches the avatar and returns the processed url" do
    patch update_avatar_users_path, params: {
      user: { avatar_attachment: Rack::Test::UploadedFile.new(jpeg_path, "image/jpeg") }
    }

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["url"]).to include("/rails/active_storage/")
    expect(body["message"]).to eq("Avatar updated!")
    expect(user.reload.avatar).to include("/rails/active_storage/")
  end

  it "rejects an oversized file with an errors array and keeps the old avatar" do
    file = Tempfile.new([ "oversized_avatar", ".jpg" ])
    file.write("a" * 600.kilobytes)
    file.rewind

    patch update_avatar_users_path, params: {
      user: { avatar_attachment: Rack::Test::UploadedFile.new(file.path, "image/jpeg") }
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(JSON.parse(response.body)).to have_key("errors")
    expect(user.reload.avatar).to be_nil
  ensure
    file&.close!
  end

  it "rejects a non JPEG/PNG file with an errors array and keeps the old avatar" do
    patch update_avatar_users_path, params: {
      user: {
        avatar_attachment: Rack::Test::UploadedFile.new(
          Rails.root.join("faker/files/Untitled document.txt").to_s,
          "text/plain"
        )
      }
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(JSON.parse(response.body)).to have_key("errors")
    expect(user.reload.avatar).to be_nil
  end
end
