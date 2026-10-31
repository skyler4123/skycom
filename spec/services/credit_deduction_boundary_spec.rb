# frozen_string_literal: true

require "rails_helper"

# Credit deduction is controller-only. Background jobs are free-credit: they may
# process suspended companies, grant credits, and drain usage counters, but must
# never call the deduction service or record usage. This mechanical guard keeps a
# future job/import from quietly charging a company.
RSpec.describe "Credit deduction boundary" do
  DEDUCTION_MARKERS = /CompanyCreditDeduction|deduct_company_credits_for|record_credit_usage!/

  def offending_files(glob)
    Dir[Rails.root.join(glob)].select { |path| File.read(path).match?(DEDUCTION_MARKERS) }
  end

  it "is never called from background jobs" do
    expect(offending_files("app/jobs/**/*.rb")).to be_empty
  end

  it "is never called from company migration/import code" do
    expect(offending_files("app/services/company_migrations/**/*.rb")).to be_empty
  end

  it "is never called from seed services (seeds may meter demo usage, never deduct)" do
    offenders = Dir[Rails.root.join("app/services/seed/**/*.rb")].select do |path|
      File.read(path).match?(/CompanyCreditDeduction|deduct_from!/)
    end

    expect(offenders).to be_empty
  end
end
