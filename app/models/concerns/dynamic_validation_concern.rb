# frozen_string_literal: true

# DynamicValidationConcern — Atomic purpose: turns a PropertyMapping's
# validation metadata into ActiveModel validations at runtime.
#
# Why it exists: categories define validators as data (presence, numericality,
# inclusion, format, length), so records need a generic runtime validator
# instead of generated code.
# How it works: the included validation reads property_mapping.properties and
# instantiates the matching ActiveModel validator per key;
# auto_populate_property_fields seeds empty property slots through
# Seed::PropertyPopulator.
# Main associations: none directly; requires the includer to respond to
# :property_mapping and the property_* columns.
module DynamicValidationConcern
  extend ActiveSupport::Concern

  ALLOWED_VALIDATORS = %w[presence numericality inclusion format length].freeze

  included do
    # Import sets this flag so a CSV row with blank property cells cannot be
    # silently filled with random seed data. Default off — normal record
    # creation keeps the existing behavior.
    attr_accessor :skip_property_auto_population

    validate :dynamic_property_validations
  end

  private

  def auto_populate_property_fields
    return if skip_property_auto_population
    return unless respond_to?(:property_mapping) && property_mapping.present?

    metadata = property_mapping.properties || []
    property_keys = metadata.map { |e| e["key"] }.compact
    return if property_keys.empty?
    return unless property_keys.any? { |k| respond_to?(k) }
    return if property_keys.any? { |k| respond_to?(k) && send(k).present? }

    Seed::PropertyPopulator.populate(self)
  end

  def dynamic_property_validations
    mapping = respond_to?(:property_mapping) ? property_mapping : nil
    return unless mapping

    (mapping.properties || []).each do |entry|
      key = entry["key"]
      validates_hash = entry["validates"]
      next if validates_hash.blank?
      next unless respond_to?(key)

      validates_hash.each do |validator_name, options|
        next unless ALLOWED_VALIDATORS.include?(validator_name)
        next if options == false

        klass = find_validator_class(validator_name)
        next unless klass

        validator_options = build_validator_options(key, validator_name, options)
        klass.new(validator_options).validate(self)
      end
    end
  end

  def find_validator_class(name)
    "ActiveModel::Validations::#{name.camelize}Validator".constantize
  rescue NameError
    nil
  end

  def build_validator_options(key, validator_name, options)
    opts = { attributes: [ key.to_sym ] }

    return opts unless options.is_a?(Hash)

    symbolized = options.deep_symbolize_keys

    if validator_name == "format"
      if symbolized[:with].is_a?(String)
        symbolized[:with] = Regexp.new(symbolized[:with])
        symbolized[:multiline] = true
      end
      if symbolized[:without].is_a?(String)
        symbolized[:without] = Regexp.new(symbolized[:without])
        symbolized[:multiline] = true
      end
    end

    opts.merge!(symbolized)
  end
end
