class HomeController < ApplicationController
  skip_before_action :authenticate, only: [:index]

  def index
  end

  def retail
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
