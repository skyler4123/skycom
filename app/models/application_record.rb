class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  include TagConcern
  include RoleConcern
end
