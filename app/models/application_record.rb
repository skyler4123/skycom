# frozen_string_literal: true

# ApplicationRecord — Atomic purpose: abstract base class for every Skycom Active
# Record model; it is not a database table.
#
# Why it exists: gives the schema-backed models one shared base and one place to
# set default ordering behavior instead of repeating it in each model.
# How it works: inherits ActiveRecord::Base, marks itself primary_abstract_class,
# and includes CreatedAtDefaultOrderingConcern, which sets implicit_order_column
# to created_at for `.first`/`.last`.
# Main associations: none (abstract base class).
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  include CreatedAtDefaultOrderingConcern
end
