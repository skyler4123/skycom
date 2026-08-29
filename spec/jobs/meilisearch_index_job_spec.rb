require "rails_helper"

RSpec.describe MeilisearchIndexJob do
  let(:company) { create(:company) }
  let!(:product) { create(:product, company: company, name: "Meili Widget #{SecureRandom.hex(4)}", property_string_1: "Oily Skin", property_integer_1: 42) }

  before { Product.ms_clear_index! }
  after  { Product.ms_clear_index! }

  it "indexes a record via the enqueue proc path" do
    product.ms_enqueue_index!(false)
    expect { MeilisearchIndexJob.perform_now("Product", product.id, false) }.not_to raise_error

    hits = Product.ms_raw_search("Meili Widget")["hits"]
    expect(hits.first).to include("name" => product.name, "property_string_1" => "Oily Skin", "property_integer_1" => 42)
  end

  it "removes a destroyed record from the index" do
    product.ms_index!
    id = product.id
    product.destroy!

    MeilisearchIndexJob.perform_now("Product", id, true)

    expect(Product.ms_raw_search("Meili Widget")["hits"]).to be_empty
  end

  it "rejects unknown model names" do
    expect { MeilisearchIndexJob.perform_now("NotAModel", 1, false) }.to raise_error(ArgumentError)
  end
end