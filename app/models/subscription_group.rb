class SubscriptionGroup < ApplicationRecord
  include ImmutableRecordConcern

  belongs_to :price
  belongs_to :period
end
