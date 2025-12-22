class Retail::Pos::ApplicationController < Retail::ApplicationController
  before_action :set_branch

  private

  def set_branch
    branch_id = params[:id]
    @branch = Company.find(branch_id) if branch_id.present?
  end
end
