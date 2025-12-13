class ArticleGroupsController < ApplicationController
  before_action :set_article_group, only: %i[ show edit update destroy ]

  # GET /article_groups or /article_groups.json
  def index
    @article_groups = ArticleGroup.all
  end

  # GET /article_groups/1 or /article_groups/1.json
  def show
  end

  # GET /article_groups/new
  def new
    @article_group = ArticleGroup.new
  end

  # GET /article_groups/1/edit
  def edit
  end

  # POST /article_groups or /article_groups.json
  def create
    @article_group = ArticleGroup.new(article_group_params)

    respond_to do |format|
      if @article_group.save
        format.html { redirect_to @article_group, notice: "Article group was successfully created." }
        format.json { render :show, status: :created, location: @article_group }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @article_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /article_groups/1 or /article_groups/1.json
  def update
    respond_to do |format|
      if @article_group.update(article_group_params)
        format.html { redirect_to @article_group, notice: "Article group was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @article_group }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @article_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /article_groups/1 or /article_groups/1.json
  def destroy
    @article_group.destroy!

    respond_to do |format|
      format.html { redirect_to article_groups_path, notice: "Article group was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_article_group
      @article_group = ArticleGroup.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def article_group_params
      params.expect(article_group: [ :company_group_id, :company_id, :title, :content, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end
