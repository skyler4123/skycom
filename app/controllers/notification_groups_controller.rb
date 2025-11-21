class NotificationGroupsController < ApplicationController
  before_action :set_notification_group, only: %i[ show edit update destroy ]

  # GET /notification_groups or /notification_groups.json
  def index
    @notification_groups = NotificationGroup.all
  end

  # GET /notification_groups/1 or /notification_groups/1.json
  def show
  end

  # GET /notification_groups/new
  def new
    @notification_group = NotificationGroup.new
  end

  # GET /notification_groups/1/edit
  def edit
  end

  # POST /notification_groups or /notification_groups.json
  def create
    @notification_group = NotificationGroup.new(notification_group_params)

    respond_to do |format|
      if @notification_group.save
        format.html { redirect_to @notification_group, notice: "Notification group was successfully created." }
        format.json { render :show, status: :created, location: @notification_group }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @notification_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /notification_groups/1 or /notification_groups/1.json
  def update
    respond_to do |format|
      if @notification_group.update(notification_group_params)
        format.html { redirect_to @notification_group, notice: "Notification group was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @notification_group }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @notification_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /notification_groups/1 or /notification_groups/1.json
  def destroy
    @notification_group.destroy!

    respond_to do |format|
      format.html { redirect_to notification_groups_path, notice: "Notification group was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_notification_group
      @notification_group = NotificationGroup.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def notification_group_params
      params.expect(notification_group: [ :company_id, :name, :description, :code, :status, :business_type, :discarded_at ])
    end
end
