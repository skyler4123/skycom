# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanyMigrations::ImportService do
  let!(:company) { create(:company) }

  let(:fixture) { Rails.root.join("faker/files/customers-10.csv") }

  let(:websocket_events) { [] }

  before do
    allow(WEBSOCKET).to receive(:publish_event) { |**kwargs| websocket_events << kwargs }
  end

  def import(migration)
    described_class.call(company_migration: migration)
  end

  # Minimal config whose category only requires property_string_1 (External Code).
  def typed_config(name: "Typed Customers")
    config = customers_migration_config
    config["targets"][0]["category"] = {
      "mode" => "create_or_reuse",
      "name" => name,
      "properties" => { "property_string_1" => "External Code" }
    }
    config["targets"][0]["columns"] = {
      "First Name" => { "target" => "name" },
      "Customer Id" => { "target" => "property_string_1" },
      "Index" => { "target" => "property_integer_1" }
    }
    config
  end

  describe "a successful run" do
    it "imports customers-10 as new customers with external_id and counters" do
      migration = create_migration_with_chunks(company: company, chunks: [ fixture ], config: customers_migration_config)

      result = import(migration)

      expect(result[:success]).to be(true)
      expect(result[:errors]).to be_empty
      expect(company.customers.count).to eq(10)

      customer = company.customers.find_by(external_id: "dE014d010c7ab0c")
      expect(customer.name).to eq("Andrew")
      expect(customer.email).to eq("marieyates@gomez-spencer.info")
      expect(customer.property_string_1).to eq("Stewart-Flynn")
      expect(customer.metadata["website"]).to eq("http://www.shea.biz/")

      migration.reload
      expect(migration.total_rows).to eq(10)
      expect(migration.processed_rows).to eq(10)
      expect(migration.created_rows).to eq(10)
      expect(migration.updated_rows).to eq(0)
      expect(migration.failed_rows).to eq(0)
      expect(migration.ordered_chunks.first.import_status).to eq("completed")
    end

    it "updates existing rows by [company_id, external_id] and logs previous values" do
      customer = create(:customer, company: company, external_id: "dE014d010c7ab0c")
      customer.update_columns(name: "Old Name")
      migration = create_migration_with_chunks(company: company, chunks: [ fixture ], config: customers_migration_config)

      result = import(migration)

      expect(result[:success]).to be(true)
      expect(customer.reload.name).to eq("Andrew")

      log = migration.company_migration_logs.find_by(record_id: customer.id)
      expect(log).to be_present
      expect(log.action_updated?).to be(true)
      expect(log.previous_state).to include("name" => "Old Name")
      expect(log.resource).to eq("customers")

      migration.reload
      expect(migration.created_rows).to eq(9)
      expect(migration.updated_rows).to eq(1)
    end

    it "keeps existing values when a mapped value is blank on update" do
      customer = create(:customer, company: company, external_id: "ext-1")
      customer.update_columns(name: "Keep Me", phone_number: "555-1111")
      chunk = "Index,Customer Id,First Name,Phone 1\n1,ext-1,Keep Me,\n"
      migration = create_migration_with_chunks(company: company, chunks: [ chunk ], config: customers_migration_config)

      result = import(migration)

      expect(result[:success]).to be(true)
      expect(customer.reload.phone_number).to eq("555-1111")
      expect(migration.company_migration_logs.count).to eq(0)
      expect(migration.reload.updated_rows).to eq(0)
      expect(migration.processed_rows).to eq(1)
    end

    it "does not duplicate logs when a row repeats in a run" do
      chunk = "Index,Customer Id,First Name\n1,ext-1,Alice\n2,ext-1,Alicia\n"
      migration = create_migration_with_chunks(company: company, chunks: [ chunk ], config: typed_config)

      result = import(migration)

      expect(result[:success]).to be(true)
      expect(company.customers.where(external_id: "ext-1").count).to eq(1)
      expect(company.customers.find_by(external_id: "ext-1").name).to eq("Alicia")
      expect(migration.company_migration_logs.count).to eq(1)
      expect(migration.company_migration_logs.first.action_created?).to be(true)
    end

    it "counts invalid rows as failed, keeps other rows, and caps error samples" do
      bad_rows = Array.new(25) { |i| "bad-#{i},ext-bad-#{i},Person #{i}" }
      good_row = "999,ext-good,Good Person"
      chunk = ([ "Index,Customer Id,First Name" ] + bad_rows + [ good_row ]).join("\n") + "\n"
      migration = create_migration_with_chunks(company: company, chunks: [ chunk ], config: typed_config)

      result = import(migration)

      expect(result[:success]).to be(true)
      expect(company.customers.count).to eq(1)
      expect(company.customers.first.name).to eq("Good Person")

      migration.reload
      expect(migration.failed_rows).to eq(25)
      expect(migration.processed_rows).to eq(26)
      expect(migration.created_rows).to eq(1)
      expect(migration.error_samples.size).to eq(MIGRATION_ERROR_SAMPLES_LIMIT)
      expect(migration.error_samples.first["errors"].first).to match(/cannot parse/)
    end

    it "counts rows with a blank identity as failed" do
      chunk = "Index,Customer Id,First Name\n1,,Nobody\n"
      migration = create_migration_with_chunks(company: company, chunks: [ chunk ], config: typed_config)

      result = import(migration)

      expect(result[:success]).to be(true)
      expect(company.customers.count).to eq(0)
      expect(migration.reload.failed_rows).to eq(1)
      expect(migration.error_samples.first["errors"].first).to match(/identity value is required/)
    end

    it "resumes by skipping completed chunks without double counting" do
      migration = create_migration_with_chunks(company: company, chunks: [ fixture ], config: customers_migration_config)
      import(migration)
      expect(migration.reload.created_rows).to eq(10)

      result = import(migration)

      expect(result[:success]).to be(true)
      migration.reload
      expect(migration.processed_rows).to eq(10)
      expect(migration.created_rows).to eq(10)
      expect(company.customers.count).to eq(10)
    end

    it "recomputes migration counters from chunk counters across chunks" do
      chunk2 = "Index,Customer Id,First Name,Email,Company,City\n11,ext-11,Alice,alice@example.com,Acme,Springfield\n"
      migration = create_migration_with_chunks(company: company, chunks: [ fixture, chunk2 ], config: customers_migration_config)

      result = import(migration)

      expect(result[:success]).to be(true)
      migration.reload
      expect(migration.total_rows).to eq(11)
      expect(migration.total_chunks).to eq(2)
      expect(migration.processed_rows).to eq(11)
      expect(migration.created_rows).to eq(11)
    end

    it "publishes progress per batch and a finished payload" do
      migration = create_migration_with_chunks(company: company, chunks: [ fixture ], config: customers_migration_config)

      import(migration)

      expect(websocket_events.map { |event| event[:event_key] }).to include(:company_migration_progress)

      CompanyMigrations::ProgressPublisher.publish_finished(company_migration: migration)

      expect(websocket_events.map { |event| event[:event_key] }).to include(:company_migration_finished)
    end
  end

  describe "a failing run" do
    it "returns failure with errors when the identity index is missing" do
      config = customers_migration_config
      target = config["targets"][0]
      target["resource"] = "services"
      target["category"] = { "mode" => "create_or_reuse", "name" => "Imported Services" }
      target["columns"] = { "First Name" => { "target" => "name" } }
      migration = create_migration_with_chunks(company: company, chunks: [ fixture ], config: config)

      result = import(migration)

      expect(result[:success]).to be(false)
      expect(result[:errors].join).to match(/missing a unique index/)
      expect(company.services.count).to eq(0)
    end

    it "refuses to silently ignore a multi-target config" do
      config = customers_migration_config
      config["targets"] << config["targets"].first.merge(
        "category" => { "mode" => "create_or_reuse", "name" => "Second Customers" }
      )
      migration = create_migration_with_chunks(company: company, chunks: [ fixture ], config: config)

      result = import(migration)

      expect(result[:success]).to be(false)
      expect(result[:errors].join).to match(/multiple targets/)
      expect(company.customers.count).to eq(0)
    end
  end
end
