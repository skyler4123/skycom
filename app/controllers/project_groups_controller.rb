class ProjectGroupsController < ApplicationController
  before_action :set_project_group, only: %i[ show edit update destroy ]

  # GET /project_groups or /project_groups.json
  def index
    @project_groups = ProjectGroup.all
  end

  # GET /project_groups/1 or /project_groups/1.json
  def show
  end

  # GET /project_groups/new
  def new
    @project_group = ProjectGroup.new
  end

  # GET /project_groups/1/edit
  def edit
  end

  # POST /project_groups or /project_groups.json
  def create
    @project_group = ProjectGroup.new(project_group_params)

    respond_to do |format|
      if @project_group.save
        format.html { redirect_to @project_group, notice: "Project group was successfully created." }
        format.json { render :show, status: :created, location: @project_group }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @project_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /project_groups/1 or /project_groups/1.json
  def update
    respond_to do |format|
      if @project_group.update(project_group_params)
        format.html { redirect_to @project_group, notice: "Project group was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @project_group }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @project_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /project_groups/1 or /project_groups/1.json
  def destroy
    @project_group.destroy!

    respond_to do |format|
      format.html { redirect_to project_groups_path, notice: "Project group was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_project_group
      @project_group = ProjectGroup.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def project_group_params
      params.expect(project_group: [ :company_id, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end
