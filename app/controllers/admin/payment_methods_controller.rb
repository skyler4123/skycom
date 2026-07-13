class Admin::PaymentMethodsController < Admin::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = PaymentMethod.all
        @pagy, @results = pagy(:offset, scope.order(created_at: :desc), jsonapi: true)

        render json: {
          payment_methods: format_payment_methods(@results),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: {} }
    end
  end

  def create
    pm = PaymentMethod.new(payment_method_params)
    if pm.save
      redirect_to admin_payment_methods_path, notice: "Payment method created successfully"
    else
      redirect_to new_admin_payment_method_path,
        alert: pm.errors.full_messages.to_sentence
    end
  end

  def edit
    @payment_method = PaymentMethod.find(params[:id])
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { payment_method: format_payment_method(@payment_method) } }
    end
  end

  def update
    pm = PaymentMethod.find(params[:id])
    if pm.update(payment_method_params)
      redirect_to admin_payment_methods_path, notice: "Payment method updated successfully"
    else
      redirect_to edit_admin_payment_method_path(pm),
        alert: pm.errors.full_messages.to_sentence
    end
  end

  private

  def format_payment_method(pm)
    pm.as_json(only: [
      :id, :name, :code, :description,
      :business_type, :country_code, :payment_mode,
      :gateway_url,
      :lifecycle_status,
      :created_at, :updated_at
    ])
  end

  def format_payment_methods(pms)
    pms.map { |pm| format_payment_method(pm) }
  end

  def payment_method_params
    params.require(:payment_method).permit(
      :name, :code, :description,
      :business_type, :country_code, :payment_mode,
      :gateway_url, :secret_key,
      :lifecycle_status
    )
  end
end
