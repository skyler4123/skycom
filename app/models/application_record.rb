class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  include CreatedAtDefaultOrderingConcern
  include Cache::ClassMethodConcern
end
