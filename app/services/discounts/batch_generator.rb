# frozen_string_literal: true

# Bulk-generates single-use codes for a DiscountGroup in one insert_all!.
# Format: "PREFIX-XXXXXXXX" (prefix optional). An in-memory Set keeps the batch
# internally unique and collision-free against the company's existing codes;
# the DB unique index on [company_id, code] is the final guard — a racing
# batch raises ActiveRecord::RecordNotUnique.
class Discounts::BatchGenerator
  DEFAULT_CODE_LENGTH = 8
  MAX_QUANTITY = 1000 # single-file constants (docs/CONSTANTS.md)

  def self.call(discount_group:, quantity:, code_length: DEFAULT_CODE_LENGTH)
    new(discount_group: discount_group, quantity: quantity, code_length: code_length).generate
  end

  def initialize(discount_group:, quantity:, code_length:)
    @group = discount_group
    @quantity = quantity.to_i
    @code_length = code_length.to_i
  end

  def generate
    return failure("Quantity must be between 1 and #{MAX_QUANTITY}") unless quantity_valid?
    return failure("Prefix is too long for the requested code length") if prefix_overflows?

    now = Time.current
    existing_codes = Discount.where(company_id: @group.company_id).pluck(:code).to_set
    records = []

    while records.size < @quantity
      candidate = build_code
      next if existing_codes.include?(candidate)

      existing_codes << candidate
      records << { company_id: @group.company_id, discount_group_id: @group.id,
        code: candidate, status: 0, created_at: now, updated_at: now }
    end

    Discount.insert_all!(records)
    { success: true, generated: records.size }
  end

  private

  def quantity_valid?
    @quantity.between?(1, MAX_QUANTITY)
  end

  def prefix_overflows?
    @group.prefix.present? && (@group.prefix.length + 1 + @code_length) > 255
  end

  def build_code
    random = SecureRandom.alphanumeric(@code_length).upcase
    @group.prefix.present? ? "#{@group.prefix}-#{random}" : random
  end

  def failure(message)
    { success: false, errors: [ message ] }
  end
end
