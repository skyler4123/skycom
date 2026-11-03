# frozen_string_literal: true

# Mobile page detail is the launch surface for a company Page, so it requires
# the same Page read grant as the Operations list.
class Mobile::Companies::PagesPolicy < ApplicationPolicy
  def show?
    record.can?(:read, Page)
  end
end
