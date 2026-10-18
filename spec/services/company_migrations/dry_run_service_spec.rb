# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanyMigrations::DryRunService do
  let!(:company) { create(:company) }

  let(:fixture) { Rails.root.join("faker/files/customers-10.csv") }

  def dry_run(migration)
    described_class.call(company_migration: migration)
  end

  describe "a passing run" do
    it "passes for customers-10 with the normative config" do
      migration = create_migration_with_chunks(company: company, chunks: [ fixture ], config: customers_migration_config)

      result = dry_run(migration)

      expect(result[:success]).to be(true)
      dry_run_result = result[:result]
      expect(dry_run_result["passed"]).to be(true)
      expect(dry_run_result["sample_size"]).to eq(10)
      expect(dry_run_result["created"]).to eq(10)
      expect(dry_run_result["updated"]).to eq(0)
      expect(dry_run_result["rows"].size).to eq(10)
      expect(dry_run_result["rows"].flat_map { |row| row["errors"] }).to be_empty
      expect(dry_run_result["rows"].first["values"]).to include(
        "name" => "Andrew",
        "email" => "marieyates@gomez-spencer.info"
      )
    end

    it "does not write customers" do
      migration = create_migration_with_chunks(company: company, chunks: [ fixture ], config: customers_migration_config)

      expect { dry_run(migration) }.not_to change { company.customers.count }
    end

    it "classifies rows matching existing external_ids as updates" do
      create(:customer, company: company, external_id: "dE014d010c7ab0c")
      migration = create_migration_with_chunks(company: company, chunks: [ fixture ], config: customers_migration_config)

      result = dry_run(migration)

      expect(result[:result]["rows"].first["action"]).to eq("update")
      expect(result[:result]["updated"]).to eq(1)
      expect(result[:result]["created"]).to eq(9)
    end

    it "stores the result and the config digest on the record" do
      migration = create_migration_with_chunks(company: company, chunks: [ fixture ], config: customers_migration_config)

      result = dry_run(migration)

      expect(migration.reload.dry_run_result).to eq(result[:result])
      expect(migration.dry_run_result["config_digest"]).to eq(migration.config.digest)
    end
  end

  describe "a failing run" do
    it "fails without an identity mapping" do
      config = customers_migration_config
      config["targets"][0]["identity"] = {}
      migration = create_migration_with_chunks(company: company, chunks: [ fixture ], config: config)

      result = dry_run(migration)

      expect(result[:success]).to be(false)
      expect(result[:errors].join).to match(/identity/)
      expect(result[:result]["passed"]).to be(false)
      expect(migration.reload.dry_run_result["passed"]).to be(false)
    end

    it "fails when the target table lacks the identity index" do
      config = customers_migration_config
      target = config["targets"][0]
      target["resource"] = "services"
      target["category"] = { "mode" => "create_or_reuse", "name" => "Imported Services" }
      target["columns"] = { "First Name" => { "target" => "name" } }
      migration = create_migration_with_chunks(company: company, chunks: [ fixture ], config: config)

      result = dry_run(migration)

      expect(result[:success]).to be(false)
      expect(result[:errors].join).to match(/missing a unique index/)
      expect(result[:result]["passed"]).to be(false)
    end

    it "reports per-row errors for an unparseable typed value" do
      config = customers_migration_config
      config["targets"][0]["category"] = {
        "mode" => "create_or_reuse",
        "name" => "Typed Customers",
        "properties" => { "property_string_1" => "External Code" }
      }
      config["targets"][0]["columns"] = {
        "First Name" => { "target" => "name" },
        "Customer Id" => { "target" => "property_string_1" },
        "Index" => { "target" => "property_integer_1" }
      }
      chunk = "Index,Customer Id,First Name\nnot-a-number,ext-1,Andrew\n"
      migration = create_migration_with_chunks(company: company, chunks: [ chunk ], config: config)

      result = dry_run(migration)

      expect(result[:success]).to be(false)
      expect(result[:result]["rows"].first["errors"].join).to match(/property_integer_1: cannot parse/)
      expect(result[:result]["passed"]).to be(false)
    end
  end
end
