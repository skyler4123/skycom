RSpec.shared_examples "property_mapping concern" do |model_class|
  describe "category and property_mapping consistency" do
    let(:company) { create(:company) }
    let(:category) { create(:category, name: "Test Category #{SecureRandom.uuid}", company: company) }
    let(:property_mapping) { category.property_mapping }
    let(:other_category) { create(:category, name: "Other Category #{SecureRandom.uuid}", company: company) }
    let(:other_property_mapping) { create(:property_mapping, company: company, category: other_category) }

    it "does not error when category matches property_mapping's category" do
      record = model_class.new(company: company, category: category, property_mapping: property_mapping)
      record.valid?
      expect(record.errors[:property_mapping]).to be_blank
    end

    it "errors when property_mapping belongs to a different category" do
      record = model_class.new(
        company: company,
        category: category,
        property_mapping: other_property_mapping
      )
      record.valid?
      expect(record.errors[:property_mapping]).to be_present
    end
  end
end
