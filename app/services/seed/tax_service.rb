# frozen_string_literal: true

# Seed::TaxService — seeds tax codes for new and demo companies.
#
# Why it exists: every company needs at least a neutral zero-rate code, and the
# development seed should show different product/service tax profiles per
# business type and country without asking the owner to type them first.
# How it works: init creates only NO_TAX. Enrich creates the profile codes,
# assigns them to items that have no code yet, and sets the default only when
# the company has none. Existing codes, assignments, and defaults are never
# overwritten. Orders and invoices are intentionally not recalculated.
# Main associations: reads Company, TaxCode, Product, Service, and TaxConfig.
class Seed::TaxService
  NEUTRAL_CODE = "NO_TAX"

  PROFILES = {
    [ "retail", "us" ] => {
      product: { code: "SALES_825", name: "Sales tax 8.25%", kind: :sales, rate_bp: 825, is_inclusive: false },
      service: { code: "SALES_0_SERVICE", name: "Sales tax 0% (services)", kind: :sales, rate_bp: 0, is_inclusive: false }
    },
    [ "retail", "vn" ] => {
      product: { code: "VAT_10", name: "VAT 10%", kind: :vat, rate_bp: 1_000, is_inclusive: true },
      service: { code: "VAT_8", name: "VAT 8%", kind: :vat, rate_bp: 800, is_inclusive: true }
    },
    [ "hospital", "vn" ] => {
      product: { code: "VAT_5_PHARMACY", name: "VAT 5% (pharmacy)", kind: :vat, rate_bp: 500, is_inclusive: true },
      service: { code: "VAT_0_MEDICAL", name: "VAT 0% (medical services)", kind: :vat, rate_bp: 0, is_inclusive: true }
    },
    [ "hotel", "vn" ] => {
      product: { code: "VAT_10_MINIBAR", name: "VAT 10% (minibar)", kind: :vat, rate_bp: 1_000, is_inclusive: true },
      service: { code: "VAT_5_ACCOMMODATION", name: "VAT 5% (accommodation & services)", kind: :vat, rate_bp: 500, is_inclusive: true }
    }
  }.freeze

  def self.ensure_neutral_code!(company:)
    return if company.nil? || company.system_company?

    code = company.tax_codes.find_or_initialize_by(code: NEUTRAL_CODE)
    return code unless code.new_record?

    code.assign_attributes(
      name: "No tax",
      kind: neutral_kind(company),
      rate_bp: 0,
      is_inclusive: false,
      description: "Neutral zero-rate code seeded for every company. Not the default.",
      metadata: { "seeded" => true, "purpose" => "neutral" }
    )
    code.save!
    code
  end

  def self.enrich!(company:)
    return nil if company.nil? || company.system_company?

    ensure_neutral_code!(company: company)
    profile = profile_for(company)
    unless profile
      return {
        profile: nil, product_code: nil, service_code: nil,
        products_updated: 0, services_updated: 0, default_set: false
      }
    end

    key = profile_key(company)
    product_code = ensure_code!(company, profile[:product], profile_key: key)
    service_code = ensure_code!(company, profile[:service], profile_key: key)

    {
      profile: key,
      product_code: product_code&.code,
      service_code: service_code&.code,
      products_updated: assign_products(company, product_code),
      services_updated: assign_services(company, service_code),
      default_set: set_default(company, product_code)
    }
  end

  def self.enrich_all!
    Company.find_each.filter_map do |company|
      enrich!(company: company) unless company.system_company?
    end
  end

  def self.profile_for(company)
    PROFILES[profile_key(company)]
  end

  def self.profile_key(company)
    [ company.business_type.to_s, company.country.to_s ]
  end
  private_class_method :profile_key

  def self.neutral_kind(company)
    company.country.to_s == "vn" ? :vat : :sales
  end
  private_class_method :neutral_kind

  def self.ensure_code!(company, attrs, profile_key:)
    code = company.tax_codes.find_or_initialize_by(code: attrs[:code])
    return nil if code.persisted? && code.discarded?
    return code if code.persisted?

    code.assign_attributes(
      name: attrs[:name],
      kind: attrs[:kind],
      rate_bp: attrs[:rate_bp],
      is_inclusive: attrs[:is_inclusive],
      description: "Seeded demo tax profile. Review before production use.",
      metadata: { "seeded" => true, "profile" => profile_key.join("_") }
    )
    code.save!
    code
  end
  private_class_method :ensure_code!

  def self.assign_products(company, code)
    return 0 unless code

    company.products.where(tax_code_id: nil).update_all(tax_code_id: code.id)
  end
  private_class_method :assign_products

  def self.assign_services(company, code)
    return 0 unless code

    company.services.where(tax_code_id: nil).update_all(tax_code_id: code.id)
  end
  private_class_method :assign_services

  def self.set_default(company, code)
    return false unless code

    config = TaxConfig.for_company!(company)
    return false if config.default_tax_code_id.present?

    config.update!(default_tax_code_id: code.id)
    true
  end
  private_class_method :set_default
end
