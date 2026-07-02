# frozen_string_literal: true

module DynamicValidationConcern
  extend ActiveSupport::Concern

  ALLOWED_VALIDATORS = %w[presence numericality inclusion format length].freeze

  included do
    validate :dynamic_property_validations
  end

  private

  def dynamic_property_validations
    mapping = respond_to?(:property_mapping) ? property_mapping : nil
    return unless mapping

    (mapping.property_metadata || []).each do |entry|
      key = entry["key"]
      validates_hash = entry["validates"]
      next if validates_hash.blank?

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
