# frozen_string_literal: true

# The Store Manager console is one workflow: reading the overview, searching the
# queue, marking ready, handing over, replenishing a shelf row and closing the
# shift all require the same operation access gate.
class Companies::Operations::StoreManagerPolicy < Companies::Operations::BasePolicy
  STORE_MANAGER_ACTIONS = %i[
    show queue mark_ready hand_over create_replenishment save_shift_close
  ].freeze

  (STORE_MANAGER_ACTIONS - %i[show]).each do |action|
    define_method("#{action}?") { show? }
  end
end
