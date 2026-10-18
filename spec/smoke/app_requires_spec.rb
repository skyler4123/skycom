# frozen_string_literal: true

require "rails_helper"

# `csv` is a bundled gem — Rails does not auto-require it (and it leaves Ruby's
# default gems in 3.5). A missing require is invisible to the spec suite when
# any support file requires csv first (it defines CSV globally for the whole
# process) but crashes at runtime in development/production. This guard checks
# the source directly so the suite can never mask the bug class again.
RSpec.describe "app files that use CSV" do
  Dir[Rails.root.join("app/**/*.rb")].sort.each do |path|
    next unless File.read(path).match?(/\bCSV\./)

    relative = path.sub("#{Rails.root}/", "")

    it "requires csv in #{relative}" do
      expect(File.read(path)).to match(/^require "csv"$/)
    end
  end
end
