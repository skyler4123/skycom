class Subscription < ApplicationRecord
  include ImmutableRecordConcern

  belongs_to :subscription_group
  belongs_to :price
  belongs_to :period
end
