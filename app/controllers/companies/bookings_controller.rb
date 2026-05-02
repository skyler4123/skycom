# app/controllers/companies/bookings_controller.rb

class Companies::BookingsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.bookings
        scope = scope.where(workflow_status: params[:workflow_status]) if params[:workflow_status].present?

        @pagy, @bookings_results = pagy(:offset, scope, jsonapi: true)

        render json: {
          bookings: format_bookings(@bookings_results),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def create
    respond_to do |format|
      format.json do
        booking = current_company.bookings.new(booking_params)
        if booking.save
          render json: { booking: format_booking(booking) }, status: :created
        else
          render json: { errors: booking.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end

  def update
    booking = current_company.bookings.find(params[:id])

    respond_to do |format|
      format.json do
        if booking.update(booking_params)
          render json: { booking: format_booking(booking) }, status: :created
        else
          render json: { errors: booking.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    render json: { status: "error", message: "Booking not found" }, status: :not_found
  end

  private

  def booking_params
    params.require(:booking).permit(
      :name,
      :description,
      :workflow_status,
      :booking_resource_id
    )
  end

  def format_booking(booking)
    booking.as_json(only: [
      :id, :name, :description, :code,
      :lifecycle_status, :workflow_status,
      :booking_resource_id,
      :created_at, :updated_at
    ])
  end

  def format_bookings(bookings)
    bookings.map { |booking| format_booking(booking) }
  end
end
