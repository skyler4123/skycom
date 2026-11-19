# frozen_string_literal: true

class Companies::Operations::PosPolicy < Companies::Operations::BasePolicy
  # POS operators may look up a customer to attach it to the active tab.
  def customer_lookup?
    show?
  end

  def catalog?
    show?
  end

  def lock?
    show?
  end

  def unlock?
    show?
  end
end
