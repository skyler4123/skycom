# frozen_string_literal: true

# PropertySlotValidationConcern — Atomic purpose: validates every configured
# property_* slot against the limits of its real database column.
#
# Why it exists: category-specific values live in fixed typed columns, so the
# database column is the source of truth for what a slot can hold. Users do not
# define custom validations; the system enforces the column's maximum instead.
# How it works: reads property_mapping.properties, looks up each key in the
# model's columns_hash, and applies the matching type rule (length, integer
# range, decimal precision/scale, boolean inclusion, datetime validity).
# Main associations: none directly; requires the includer to respond to
# :property_mapping and the property_* columns.
require "bigdecimal/util"

module PropertySlotValidationConcern
  extend ActiveSupport::Concern

  included do
    validate :property_slot_type_validations
  end

  private

  def property_slot_type_validations
    mapping = respond_to?(:property_mapping) ? property_mapping : nil
    return unless mapping

    (mapping.properties || []).each do |entry|
      key = entry["key"].to_s
      next if key.blank?
      next unless respond_to?(key)

      column = self.class.columns_hash[key]
      next unless column

      value = send(key)

      case column.type
      when :string
        validate_string_slot(key, value, column)
      when :integer
        validate_integer_slot(key, value, column)
      when :decimal
        validate_decimal_slot(key, value, column)
      when :boolean
        validate_boolean_slot(key, value)
      when :datetime, :date, :time
        validate_datetime_slot(key, value)
      end
    end
  end

  def validate_string_slot(key, value, column)
    return if value.nil?

    max = column.limit || PROPERTY_STRING_MAX_LENGTH
    return if value.to_s.length <= max

    errors.add(key, :too_long, count: max)
  end

  def validate_integer_slot(key, value, column)
    return if value.nil?

    bytes = column.limit || 4
    min = -(2**(bytes * 8 - 1))
    max = (2**(bytes * 8 - 1)) - 1
    return if value.between?(min, max)

    errors.add(key, "must be between #{min} and #{max}")
  end

  def validate_decimal_slot(key, value, column)
    return if value.nil?
    return if column.precision.nil? || column.scale.nil?

    scale = column.scale
    decimal = value.to_d

    if raw_decimal_scale(key) > scale || decimal.round(scale) != decimal
      errors.add(key, "must have at most #{scale} decimal places")
    end

    integer_digits = column.precision - scale
    max = BigDecimal("9" * integer_digits + "." + "9" * scale)
    return unless decimal.abs > max

    errors.add(key, "must be less than or equal to #{max.to_s('F')}")
  end

  # ActiveRecord rounds decimals to the column scale before validation, so read
  # the originally assigned value to reject extra decimal places.
  def raw_decimal_scale(key)
    raw = read_attribute_before_type_cast(key)
    return 0 if raw.blank?

    decimal = BigDecimal(raw.to_s)
    return 0 if decimal.frac.zero?

    decimal.frac.abs.to_s("F").split(".").last.length
  rescue ArgumentError, TypeError
    0
  end

  def validate_boolean_slot(key, value)
    return if value.nil?
    return if [ true, false ].include?(value)

    errors.add(key, :inclusion)
  end

  def validate_datetime_slot(key, value)
    raw = read_attribute_before_type_cast(key)

    if raw.present? && value.nil?
      errors.add(key, "is not a valid date/time")
    elsif value.present? && !value.respond_to?(:strftime)
      errors.add(key, "is not a valid date/time")
    end
  end
end
