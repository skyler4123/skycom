# frozen_string_literal: true

require "rails_helper"

# System canary for the image-processing stack (image_processing gem +
# ImageMagick `convert` binary). The cashier page 500'd with
# `MiniMagick::Error (executable not found: "convert")` when the binary was
# missing from the Rails runtime env — this spec goes red with that same
# error instead of letting it surface as a 500 in a request path.
RSpec.describe "Image processing stack" do
  let(:seed_image_path) { Rails.root.join("faker/images/randoms", "567-500x1000.jpg") }

  it "has the ImageMagick binary on PATH" do
    expect(MiniMagick.cli_version).to be_present
  end

  it "processes the cashier thumb variant on a seed image" do
    ActiveStorage::Current.url_options = { host: "http://localhost:3000" }
    product = create(:product)
    product.image_attachments.attach(
      io: File.open(seed_image_path),
      filename: "567-500x1000.jpg",
      content_type: "image/jpeg"
    )

    variant = product.image_attachments.first.variant(:thumb).processed

    expect(variant.url).to be_present
  end
end
