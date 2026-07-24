# frozen_string_literal: true

class Companies::PaymentMethodAppointmentsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        payment_methods = PaymentMethod.where(country: current_company.country)

        appointments = payment_methods.map do |pm|
          appointment = PaymentMethodAppointment.find_or_create_by!(
            company: current_company,
            payment_method: pm
          ) do |a|
            a.name = "#{pm.name} for #{current_company.name}"
            a.code = "#{pm.code}-#{SecureRandom.hex(4).upcase}"
            a.business_type = :in_store
            a.lifecycle_status = :inactive
          end

          {
            id: appointment.id,
            name: pm.name,
            code: pm.code,
            payment_mode: pm.payment_mode,
            lifecycle_status: appointment.lifecycle_status,
            strategy: pm.strategy
          }
        end

        render json: { payment_method_appointments: appointments }
      end
    end
  end

  def edit
    @appointment = current_company.payment_method_appointments.includes(:payment_method).find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          payment_method_appointment: {
            id: @appointment.id,
            lifecycle_status: @appointment.lifecycle_status,
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
    appointment = current_company.payment_method_appointments.find(params[:id])

    if appointment.update(update_params)
      redirect_to company_payment_method_appointments_path(current_company),
        notice: "Payment method updated successfully"
    else
      redirect_to edit_company_payment_method_appointment_path(current_company, appointment),
        alert: appointment.errors.full_messages.to_sentence
    end
  end

  private

  def update_params
    params.require(:payment_method_appointment).permit(:lifecycle_status)
  end
end
