# frozen_string_literal: true

class Companies::PaymentMethodAppointmentsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        if params[:branch_id].present?
          branch = current_company.branches.find(params[:branch_id])
          appointments = branch.payment_method_appointments.includes(:payment_method)

          company_level_active_ids = current_company.payment_method_appointments.company_level
            .where(lifecycle_status: LIFECYCLE_STATUS.fetch(:active))
            .pluck(:payment_method_id).to_set

          render json: {
            payment_method_appointments: appointments.map { |a|
              format_appointment(a, company_level_active: company_level_active_ids.include?(a.payment_method_id))
            }
          }
        else
          appointments = current_company.payment_method_appointments.company_level.includes(:payment_method)

          render json: {
            payment_method_appointments: appointments.map { |a| format_appointment(a) }
          }
        end
      end
    end
  end

  def edit
    @appointment = PaymentMethodAppointment.where(company_id: current_company.id).includes(:payment_method).find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          payment_method_appointment: {
            id: @appointment.id,
            lifecycle_status: @appointment.lifecycle_status,
            merchant_number: @appointment.merchant_number,
            merchant_name: @appointment.merchant_name,
            merchant_id: @appointment.merchant_id,
            payment_method: {
              name: @appointment.payment_method.name,
              code: @appointment.payment_method.code,
              payment_mode: @appointment.payment_method.payment_mode,
              business_type: @appointment.payment_method.business_type
            }
          }
        }
      end
    end
  end

  def update
    appointment = PaymentMethodAppointment.where(company_id: current_company.id).find(params[:id])

    if appointment.update(update_params)
      respond_to do |format|
        format.html { redirect_to company_payment_method_appointments_path(current_company),
          notice: "Payment method updated successfully" }
        format.json do
          render json: {
            payment_method_appointment: {
              id: appointment.id,
              lifecycle_status: appointment.lifecycle_status
            },
            message: "Payment method updated successfully"
          }
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to edit_company_payment_method_appointment_path(current_company, appointment),
          alert: appointment.errors.full_messages.to_sentence }
        format.json { render json: { errors: appointment.errors.full_messages }, status: :unprocessable_content }
      end
    end
  end

  private

  def format_appointment(appointment, company_level_active: nil)
    pm = appointment.payment_method
    {
      id: appointment.id,
      name: pm.name,
      code: pm.code,
      payment_mode: pm.payment_mode,
      lifecycle_status: appointment.lifecycle_status,
      strategy: pm.strategy,
      merchant_number: appointment.merchant_number,
      merchant_name: appointment.merchant_name,
      merchant_id: appointment.merchant_id,
      company_level_active: company_level_active
    }
  end

  def update_params
    params.require(:payment_method_appointment).permit(:lifecycle_status, :merchant_number, :merchant_name, :merchant_id)
  end
end
