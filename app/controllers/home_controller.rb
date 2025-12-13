class HomeController < ApplicationController
  skip_before_action :authenticate, only: [:index]

  def index
  end

  def retail
    retail = Current.user.retail
    redirect_to retail_management_dashboard_index_path(retail)
  end

  def education
  end

  def hospital
  end

  def restaurant
  end

  def shop
  end

  def fitness
  end
end
