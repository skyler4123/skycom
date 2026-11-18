require "rails_helper"

# Covers the only non-glue part of the Capybara/Chrome 158 workaround:
# turning a Capybara server base URL into a CDP-acceptable origin.
RSpec.describe CapybaraStorageReset do
  describe ".origin" do
    it "reduces a server base url to its origin" do
      expect(described_class.origin("http://127.0.0.1:41234/")).to eq("http://127.0.0.1:41234")
    end

    it "keeps an explicit port" do
      expect(described_class.origin("https://app.example.test:8443")).to eq("https://app.example.test:8443")
    end

    it "falls back to the default port when the url omits it" do
      expect(described_class.origin("http://app.example.test")).to eq("http://app.example.test:80")
    end

    it "returns nil when there is no base url" do
      expect(described_class.origin(nil)).to be_nil
      expect(described_class.origin("")).to be_nil
    end

    it "returns nil for an unparseable url" do
      expect(described_class.origin("http://exa mple.test:80")).to be_nil
    end
  end
end
