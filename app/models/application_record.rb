class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  include CacheableConcern
  include TagConcern
end
