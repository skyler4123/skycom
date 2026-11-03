class Mobile::Companies::PagesController < Mobile::Companies::BaseController
  def show
    @page = @company.pages
      .includes(:branch)
      .where(business_type: @company.business_type, target_resolution: :mobile)
      .find(params[:id])
  end
end
