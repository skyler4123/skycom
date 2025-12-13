class DocumentGroupsController < ApplicationController
  before_action :set_document_group, only: %i[ show edit update destroy ]

  # GET /document_groups or /document_groups.json
  def index
    @document_groups = DocumentGroup.all
  end

  # GET /document_groups/1 or /document_groups/1.json
  def show
  end

  # GET /document_groups/new
  def new
    @document_group = DocumentGroup.new
  end

  # GET /document_groups/1/edit
  def edit
  end

  # POST /document_groups or /document_groups.json
  def create
    @document_group = DocumentGroup.new(document_group_params)

    respond_to do |format|
      if @document_group.save
        format.html { redirect_to @document_group, notice: "Document group was successfully created." }
        format.json { render :show, status: :created, location: @document_group }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @document_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /document_groups/1 or /document_groups/1.json
  def update
    respond_to do |format|
      if @document_group.update(document_group_params)
        format.html { redirect_to @document_group, notice: "Document group was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @document_group }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @document_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /document_groups/1 or /document_groups/1.json
  def destroy
    @document_group.destroy!

    respond_to do |format|
      format.html { redirect_to document_groups_path, notice: "Document group was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_document_group
      @document_group = DocumentGroup.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def document_group_params
      params.expect(document_group: [ :company_group_id, :company_id, :title, :content, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end
