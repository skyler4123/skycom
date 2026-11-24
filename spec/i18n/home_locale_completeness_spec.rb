require "rails_helper"

RSpec.describe "Homepage locale completeness" do
  def leaf_keys(node, prefix = nil)
    node.flat_map do |key, value|
      path = [ prefix, key ].compact.join(".")
      value.is_a?(Hash) ? leaf_keys(value, path) : path
    end
  end

  it "keeps the locale allowlists in sync" do
    expect(I18n.available_locales).to match_array(PUBLISHED_LOCALES)
    expect(LANGUAGE_NAMES.keys).to match_array(PUBLISHED_LOCALES)
    expect(OG_LOCALES.keys).to match_array(PUBLISHED_LOCALES)
  end

  it "has the same homepage keys in English and Vietnamese" do
    english = I18n.t("home", locale: :en)
    vietnamese = I18n.t("home", locale: :vi)

    expect(leaf_keys(vietnamese)).to match_array(leaf_keys(english))
  end

  it "has a non-blank Vietnamese value for every homepage key" do
    vietnamese = I18n.t("home", locale: :vi)

    leaf_keys(vietnamese).each do |key|
      value = key.split(".").reduce(vietnamese) { |node, segment| node.fetch(segment.to_sym) }

      expect(value.to_s.strip).not_to be_empty, "expected home.#{key} to be present"
    end
  end
end
