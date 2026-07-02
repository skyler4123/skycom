# frozen_string_literal: true

module DynamicValidationConcern
  extend ActiveSupport::Concern

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

      value = send(key)

      validates_hash.each do |validator_name, options|
        case validator_name
        when "presence"
          errors.add(key, "can't be blank") if value.blank?
        when "numericality"
          apply_numericality_validation(key, value, options)
        when "inclusion"
          apply_inclusion_validation(key, value, options)
        when "format"
          apply_format_validation(key, value, options)
        when "length"
          apply_length_validation(key, value, options)
        end
      end
    end
  end

  def apply_numericality_validation(key, value, options)
    return if value.nil?

    opts = options.is_a?(Hash) ? options : {}

    if opts["only_integer"] && !value.is_a?(Integer) && !(value.is_a?(String) && value.match?(/\A-?\d+\z/))
      errors.add(key, "must be an integer")
    end

    numeric_value = value.to_f

    if opts.key?("greater_than_or_equal_to") && numeric_value < opts["greater_than_or_equal_to"].to_f
      errors.add(key, "must be greater than or equal to #{opts['greater_than_or_equal_to']}")
    end

    if opts.key?("greater_than") && numeric_value <= opts["greater_than"].to_f
      errors.add(key, "must be greater than #{opts['greater_than']}")
    end

    if opts.key?("less_than_or_equal_to") && numeric_value > opts["less_than_or_equal_to"].to_f
      errors.add(key, "must be less than or equal to #{opts['less_than_or_equal_to']}")
    end

    if opts.key?("less_than") && numeric_value >= opts["less_than"].to_f
      errors.add(key, "must be less than #{opts['less_than']}")
    end
  end

  def apply_inclusion_validation(key, value, options)
    allowed = options.is_a?(Hash) ? options["in"] : nil
    return unless allowed

    errors.add(key, "is not included in the list") unless allowed.include?(value)
  end

  def apply_format_validation(key, value, options)
    return if value.nil?

    opts = options.is_a?(Hash) ? options : {}

    if opts["with"].present?
      regex = Regexp.new(opts["with"])
      errors.add(key, "is invalid") unless value.match?(regex)
    end

    if opts["without"].present?
      regex = Regexp.new(opts["without"])
      errors.add(key, "is invalid") if value.match?(regex)
    end
  end

  def apply_length_validation(key, value, options)
    return if value.nil?

    opts = options.is_a?(Hash) ? options : {}
    str_value = value.to_s

    if opts.key?("minimum") && str_value.length < opts["minimum"].to_i
      errors.add(key, "is too short (minimum is #{opts['minimum']} characters)")
    end

    if opts.key?("maximum") && str_value.length > opts["maximum"].to_i
      errors.add(key, "is too long (maximum is #{opts['maximum']} characters)")
    end
  end
end
