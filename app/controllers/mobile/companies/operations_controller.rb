class Mobile::Companies::OperationsController < Mobile::Companies::BaseController
  def index
    scope = @company.pages.includes(:branch).where(business_type: @company.business_type)

    @pages = scope.where(target_resolution: :mobile).order(:name)
    @summary = Page.counts_for(company: @company)
  end
end
