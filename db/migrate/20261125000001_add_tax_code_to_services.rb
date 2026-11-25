# frozen_string_literal: true

class AddTaxCodeToServices < ActiveRecord::Migration[8.1]
  def change
    add_reference :services, :tax_code, type: :uuid, null: true, foreign_key: true
  end
end
