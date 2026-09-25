class TagTransactionAppointment < ApplicationRecord
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :tag
  # `transaction` conflicts with ActiveRecord#transaction, so use explicit name.
  belongs_to :target_transaction, class_name: "Transaction", foreign_key: "transaction_id"
end
