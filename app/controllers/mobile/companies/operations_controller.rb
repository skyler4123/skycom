class Mobile::Companies::OperationsController < Mobile::Companies::BaseController
  def index
    @pages = @company.pages.includes(:branch).order(:name)
  end
end
