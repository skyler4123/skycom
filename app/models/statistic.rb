class Statistic < ApplicationRecord
  include TagConcern

  belongs_to :owner, polymorphic: true
end
