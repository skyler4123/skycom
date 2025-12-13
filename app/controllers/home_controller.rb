class HomeController < ApplicationController
  skip_before_action :authenticate, only: [:index]

  def index
  end

  def retail
    retail = Current.user.retail
    redirect_to retail_management_dashboard_index_path(retail) if retail
    redirect_to new_company_group_path if !retail
  end

  def education
    education = Current.user.education
    redirect_to education_schools_path(education) if education
    redirect_to new_company_group_path if !education
  end

  def hospital
    hospital = Current.user.hospital
    redirect_to hospital_patients_path(hospital) if hospital
    redirect_to new_company_group_path if !hospital
  end

  def restaurant
    restaurant = Current.user.restaurant
    redirect_to restaurant_management_dashboard_index_path(restaurant) if restaurant
    redirect_to new_company_group_path if !restaurant
  end

  def shop
    shop = Current.user.shop
    redirect_to shop_management_dashboard_index_path(shop) if shop
    redirect_to new_company_group_path if !shop
  end

  def fitness
    fitness = Current.user.fitness
    redirect_to fitness_management_dashboard_index_path(fitness) if fitness
    redirect_to new_company_group_path if !fitness
  end
end
