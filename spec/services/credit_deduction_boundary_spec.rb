# frozen_string_literal: true

require "rails_helper"

# Credit OUT has one write path: CompanyCreditDeduction::DeductionService.
# Controllers, models, jobs, and mailers may call the service, but nothing
# outside the deduction service (and the wallet primitive it uses) should call
# CompanyWallet#deduct_from! directly.
RSpec.describe "Credit deduction boundary" do
  def direct_deduction_files(glob)
    Dir[Rails.root.join(glob)].select do |path|
      File.readlines(path).any? do |line|
        !line.lstrip.start_with?("#") && line.match?(/\.deduct_from!/)
      end
    end
  end

  it "only the deduction service calls the wallet deduct primitive" do
    files = direct_deduction_files("app/**/*.rb").reject do |path|
      path.end_with?("app/models/company_wallet.rb") ||
        path.include?("app/services/company_credit_deduction/")
    end

    expect(files).to be_empty
  end
end
