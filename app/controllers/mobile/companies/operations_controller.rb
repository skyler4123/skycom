class Mobile::Companies::OperationsController < Mobile::Companies::BaseController
  def index
    scope = @company.pages.includes(:branch).where(business_type: @company.business_type)

    @pages = scope.where(target_resolution: :mobile).order(:name)
    @summary = {
      total: scope.count,
      desktop: scope.where(target_resolution: :desktop).count,
      mobile: scope.where(target_resolution: :mobile).count
    }
  end
end
