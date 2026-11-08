# frozen_string_literal: true

class Companies::Operations::ReceptionPolicy < Companies::Operations::BasePolicy
  # Reception operators act on the console; every write shares the show gate.
  def check_in?
    show?
  end

  def advance?
    show?
  end

  def create_parcel?
    show?
  end

  def notify_parcel?
    show?
  end

  def pick_up_parcel?
    show?
  end

  def notify_host?
    show?
  end
end
