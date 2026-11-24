# frozen_string_literal: true

class Companies::FaqsPolicy < ApplicationPolicy
  # Informational page: every employee with a company record may read it.
  def show? = true
end
