class Retail::Management::FacilitiesController < Retail::Management::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        @facilities = @retail.cached_facilities
        render json: { facilities: @facilities }
      end
    end
  end
end
