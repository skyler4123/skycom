RSpec.shared_examples "dynamic meilisearch model" do |model_class, builder|
  describe model_class.name do
    let(:company) { create(:company) }
    let(:record) { instance_exec(company, &builder) }
    let(:immutable) { record.class.ancestors.include?(ImmutableRecordConcern) }

    before { model_class.ms_clear_index! }
    after  { model_class.ms_clear_index! }

    it "is searchable by name/code and dynamic properties, scoped by company" do
      expect(record.company_id).to eq(company.id)

      search_term = "UniqueSearchTerm#{SecureRandom.hex(4)}"

      if model_class.column_names.include?("property_string_1") && !immutable
        record.update!(property_string_1: search_term)
      elsif model_class.column_names.include?("name")
        if immutable
          search_term = record.name
        else
          record.update!(name: search_term)
        end
      else
        skip "model has no searchable attribute"
      end

      record.ms_index!(true)

      hits = model_class.ms_raw_search(search_term, filter: "company_id = #{company.id}")["hits"]
      expect(hits.map { |h| h["id"] }).to include(record.id)

      other_hits = model_class.ms_raw_search(search_term, filter: "company_id = #{SecureRandom.uuid}")["hits"]
      expect(other_hits).to be_empty
    end

    it "supports numeric filter ranges on property_integer_1" do
      next unless model_class.column_names.include?("property_integer_1")
      next if immutable

      record.update!(property_integer_1: 37)
      record.ms_index!(true)

      hits = model_class.ms_raw_search("", filter: "company_id = #{company.id} AND property_integer_1 >= 30")["hits"]
      expect(hits.map { |h| h["id"] }).to include(record.id)
    end

    it "reflects updates after reindex" do
      next unless model_class.column_names.include?("property_string_1")
      next if immutable

      first_value = "FirstValue#{SecureRandom.hex(3)}"
      second_value = "SecondValue#{SecureRandom.hex(3)}"

      record.update!(property_string_1: first_value)
      record.ms_index!(true)
      record.update!(property_string_1: second_value)
      record.ms_index!(true)

      hits = model_class.ms_raw_search(second_value)["hits"]
      expect(hits.map { |h| h["id"] }).to include(record.id)
    end

    it "removes the document when the record is destroyed" do
      next if immutable

      record.ms_index!(true)
      id = record.id
      record.destroy!

      MeilisearchIndexJob.perform_now(model_class.name, id, true)

      expect(model_class.ms_raw_search("", filter: "company_id = #{company.id}")["hits"]).to be_empty
    end
  end
end
