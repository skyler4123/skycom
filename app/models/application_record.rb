class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  include ApplicationRecord::Uuid7Concern
  include TagConcern
end
