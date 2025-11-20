class TaskGroupsController < ApplicationController
  before_action :set_task_group, only: %i[ show edit update destroy ]

  # GET /task_groups or /task_groups.json
  def index
    @task_groups = TaskGroup.all
  end

  # GET /task_groups/1 or /task_groups/1.json
  def show
  end

  # GET /task_groups/new
  def new
    @task_group = TaskGroup.new
  end

  # GET /task_groups/1/edit
  def edit
  end

  # POST /task_groups or /task_groups.json
  def create
    @task_group = TaskGroup.new(task_group_params)

    respond_to do |format|
      if @task_group.save
        format.html { redirect_to @task_group, notice: "Task group was successfully created." }
        format.json { render :show, status: :created, location: @task_group }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @task_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /task_groups/1 or /task_groups/1.json
  def update
    respond_to do |format|
      if @task_group.update(task_group_params)
        format.html { redirect_to @task_group, notice: "Task group was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @task_group }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @task_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /task_groups/1 or /task_groups/1.json
  def destroy
    @task_group.destroy!

    respond_to do |format|
      format.html { redirect_to task_groups_path, notice: "Task group was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_task_group
      @task_group = TaskGroup.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def task_group_params
      params.expect(task_group: [ :company_id, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end
