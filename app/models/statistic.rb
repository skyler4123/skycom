class Statistic < ApplicationRecord
  belongs_to :owner, polymorphic: true
end
