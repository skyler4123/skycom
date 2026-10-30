# spec/services/cache_key_literals_spec.rb
require "rails_helper"

# Guards the "no hardcoded cache keys" rule (docs/CACHE.md §7):
# every application cache key must come from CacheKeyService.
RSpec.describe "Cache key literals" do
  APP_ROOT = Rails.root.join("app")

  def offending_lines(pattern)
    Dir.glob(APP_ROOT.join("**/*.rb")).flat_map do |path|
      File.readlines(path).each_with_index.filter_map do |line, index|
        "#{path}:#{index + 1}: #{line.strip}" if line.match?(pattern)
      end
    end
  end

  it "never calls a cache store with an inline string key" do
    offenses = offending_lines(
      /Rails\.(sync_cache|ram_cache|local_cache|global_cache)\.(fetch|read|write|delete)\(?\s*["']/
    )

    expect(offenses).to be_empty,
      "build the key with CacheKeyService (docs/CACHE.md §7). Offenders:\n#{offenses.join("\n")}"
  end

  it "never assigns an inline cache key to a local variable" do
    offenses = offending_lines(/cache_key\s*=\s*["']/)

    expect(offenses).to be_empty,
      "build the key with CacheKeyService (docs/CACHE.md §7). Offenders:\n#{offenses.join("\n")}"
  end

  it "never calls Rails.cache directly in the application" do
    offenses = offending_lines(/Rails\.cache\.(fetch|read|write|delete)/)

    expect(offenses).to be_empty,
      "use Rails.sync_cache through CacheKeyService (docs/CACHE.md §7). Offenders:\n#{offenses.join("\n")}"
  end

  it "never builds a versioned key outside CacheKeyService" do
    offenses = offending_lines(/cache_key_with_version/)

    expect(offenses).to be_empty,
      "use CacheKeyService (docs/CACHE.md §7). Offenders:\n#{offenses.join("\n")}"
  end
end
