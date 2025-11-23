class ExamGroupsController < ApplicationController
  before_action :set_exam_group, only: %i[ show edit update destroy ]

  # GET /exam_groups or /exam_groups.json
  def index
    @exam_groups = ExamGroup.all
  end

  # GET /exam_groups/1 or /exam_groups/1.json
  def show
  end

  # GET /exam_groups/new
  def new
    @exam_group = ExamGroup.new
  end

  # GET /exam_groups/1/edit
  def edit
  end

  # POST /exam_groups or /exam_groups.json
  def create
    @exam_group = ExamGroup.new(exam_group_params)

    respond_to do |format|
      if @exam_group.save
        format.html { redirect_to @exam_group, notice: "Exam group was successfully created." }
        format.json { render :show, status: :created, location: @exam_group }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @exam_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /exam_groups/1 or /exam_groups/1.json
  def update
    respond_to do |format|
      if @exam_group.update(exam_group_params)
        format.html { redirect_to @exam_group, notice: "Exam group was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @exam_group }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @exam_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /exam_groups/1 or /exam_groups/1.json
  def destroy
    @exam_group.destroy!

    respond_to do |format|
      format.html { redirect_to exam_groups_path, notice: "Exam group was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_exam_group
      @exam_group = ExamGroup.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def exam_group_params
      params.expect(exam_group: [ :company_id, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end
