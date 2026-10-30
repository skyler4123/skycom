# spec/services/cache_key_service_spec.rb
require "rails_helper"

RSpec.describe CacheKeyService do
  let(:employee) do
    instance_double(
      Employee,
      id: 12,
      cache_version: "20261030120000000000",
      model_name: Employee.model_name
    )
  end
  let(:company) do
    instance_double(
      Company,
      id: 3,
      cache_version: "20261030120000000000"
    )
  end
  let(:customer) do
    instance_double(
      Customer,
      id: 9,
      cache_version: "20261030120000000000"
    )
  end

  describe "record caches" do
    it "builds the session key" do
      expect(described_class.session(12)).to eq("session:12")
    end

    it "builds the user record key" do
      expect(described_class.user(7)).to eq("user:7:record:v2")
    end

    it "builds the company record key" do
      expect(described_class.company(3)).to eq("company:3:record:v2")
    end

    it "builds the employee record key from user and company ids" do
      expect(described_class.employee_record(user_id: 7, company_id: 3))
        .to eq("employee:user:7:company:3:record:v2")
    end

    it "builds the companies max updated_at key" do
      expect(described_class.user_companies_max_updated_at(7))
        .to eq("user:7:companies_max_updated_at")
    end
  end

  describe "aggregate caches" do
    it "builds the manager ids key" do
      expect(described_class.employee_manager_ids(12)).to eq("employee:12:manager_ids")
    end

    it "builds the company open ticket count key" do
      expect(described_class.company_open_ticket_count(3))
        .to eq("company:3:tickets:open_count")
    end

    it "builds the admin open ticket count key" do
      expect(described_class.admin_open_ticket_count)
        .to eq("company_ticket:admin:open_count")
    end

    it "builds the unread notifications key" do
      expect(described_class.employee_unread_notifications(12))
        .to eq("employee:12:notifications:unread")
    end

    it "builds the analytics key" do
      expect(described_class.company_analytics(3, "this_month"))
        .to eq("company:3:analytics:this_month")
    end

    it "sanitizes an unsafe analytics period" do
      expect(described_class.company_analytics(3, "this month!"))
        .to eq("company:3:analytics:this_month")
    end

    it "falls back to unknown for a blank analytics period" do
      expect(described_class.company_analytics(3, "")).to eq("company:3:analytics:unknown")
    end

    it "builds the storage statistics key" do
      expect(described_class.company_storage_statistics(3))
        .to eq("company:3:storage_statistics")
    end
  end

  describe "versioned caches" do
    it "builds the employee owner role key" do
      expect(described_class.employee_owner_role(employee))
        .to eq("employee:12:20261030120000000000:owner_role")
    end

    it "builds the employee permissions key" do
      expect(described_class.employee_permissions(employee))
        .to eq("employee:12:20261030120000000000:permissions")
    end

    it "builds the employee permissions_by_role key" do
      expect(described_class.employee_permissions_by_role(employee))
        .to eq("employee:12:20261030120000000000:permissions_by_role")
    end

    it "builds the company permissions key" do
      expect(described_class.company_permissions(company))
        .to eq("company:3:20261030120000000000:permissions")
    end

    it "builds the company permissions_by_role key" do
      expect(described_class.company_permissions_by_role(company))
        .to eq("company:3:20261030120000000000:permissions_by_role")
    end

    it "builds the company permissions_by_resource key" do
      expect(described_class.company_permissions_by_resource(company))
        .to eq("company:3:20261030120000000000:permissions_by_resource")
    end

    it "builds the current address key from the owner type" do
      expect(described_class.current_address(employee))
        .to eq("employee:12:20261030120000000000:current_address")
    end

    it "builds the customer current membership key" do
      expect(described_class.customer_current_membership(customer))
        .to eq("customer:9:20261030120000000000:current_membership")
    end

    it "builds the customer membership of type key" do
      expect(described_class.customer_membership_of_type(customer, :primary))
        .to eq("customer:9:20261030120000000000:membership:primary")
    end

    it "changes when the record is touched" do
      user = create(:user)

      before_key = described_class.current_address(user)
      user.touch
      after_key = described_class.current_address(user)

      expect(after_key).not_to eq(before_key)
    end
  end

  describe "Kredis keys (data-bearing, exact strings)" do
    it "keeps the stock available counter key" do
      expect(described_class.stock_available(5)).to eq("stock:5:available")
    end

    it "keeps the company credit usage counter key" do
      expect(described_class.company_credit_usage(3)).to eq("companies:3:credit_usage")
    end
  end

  describe "key format" do
    it "returns colon-separated keys with no whitespace" do
      keys = [
        described_class.session(1),
        described_class.user(1),
        described_class.company(1),
        described_class.employee_record(user_id: 1, company_id: 2),
        described_class.employee_manager_ids(1),
        described_class.employee_owner_role(employee),
        described_class.company_permissions_by_resource(company),
        described_class.current_address(employee),
        described_class.customer_membership_of_type(customer, :primary),
        described_class.company_analytics(1, "last_6_months"),
        described_class.admin_open_ticket_count,
        described_class.stock_available(1)
      ]

      keys.each do |key|
        expect(key).to match(/\A[a-z][a-z0-9_]*(:[a-z0-9_-]+)+\z/), "bad key format: #{key.inspect}"
      end
      expect(keys.uniq.length).to eq(keys.length)
    end
  end

  describe "documentation contract" do
    it "documents every key builder with Pattern/Purpose/Store/TTL/Written by/Cleared by" do
      source = File.readlines(Rails.root.join("app/services/cache_key_service.rb"))
      method_indexes = source.each_index.select { |index| source[index] =~ /^\s+def self\./ }

      expect(method_indexes).not_to be_empty

      labels = [ "Pattern:", "Purpose:", "Store:", "TTL:", "Written by:", "Cleared by:" ]

      method_indexes.each do |index|
        comment_block = []
        cursor = index - 1

        while cursor >= 0 && source[cursor].strip.start_with?("#")
          comment_block.unshift(source[cursor].strip)
          cursor -= 1
        end

        labels.each do |label|
          expect(comment_block.join("\n")).to include(label),
            "missing #{label} above #{source[index].strip}"
        end
      end
    end
  end
end
