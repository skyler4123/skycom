class Retail::Pos::ApplicationController < Retail::ApplicationController
  before_action :set_store

  private

  def set_store
    store_id = params[:store_id]
    @store = Company.find(store_id) if store_id.present?
  end
end
