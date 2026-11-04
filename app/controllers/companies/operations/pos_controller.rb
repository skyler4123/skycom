# frozen_string_literal: true

# Companies::Operations::PosController — the POS operation. Hydrates the
# branch-scoped product/service catalog and the branch's non-redirect payment
# methods for the resolved BranchOperationAppointment.
# Serves Stimulus: Companies_Operations_Pos_ShowController (hydrate)
# Endpoints: GET /companies/:company_id/operations/pos/:operation_id
# Docs: docs/OPERATIONS.md, docs/ORDER_PROCESSING_V1.md
class Companies::Operations::PosController < Companies::Operations::BaseController
  private

  def expected_operation_type
    :pos
  end

  def operation_payload
    branch = @appointment.branch
    warehouse_ids = branch.warehouse_ids

    products = current_company.products.where(branch_id: branch.id).limit(50).map do |product|
      price = product.price
      stock = Stock.find_by(product_id: product.id, warehouse_id: warehouse_ids)
      {
        id: product.id,
        name: product.name,
        code: product.code,
        stock_id: stock&.id,
        price: price&.to_f || 0,
        currency: price&.currency.iso_code || "USD",
        image_url: product.image_attachments.first&.variant(:thumb)&.processed&.url
      }
    end

    services = current_company.services.where(branch_id: branch.id).limit(50).map do |service|
      {
        id: service.id,
        name: service.name,
        code: service.code,
        price: 0,
        currency: "usd",
        image_url: service.image_attachments.first&.variant(:thumb)&.processed&.url
      }
    end

    payment_methods = branch.branch_payment_method_appointments
      .includes(:payment_method)
      .where(lifecycle_status: LIFECYCLE_STATUS.fetch(:active))
      .reject { |appointment| appointment.payment_method.redirect? }
      .map do |appointment|
        { id: appointment.id }.merge(
          appointment.payment_method.slice(:name, :code, :payment_mode, :strategy)
        )
      end

    {
      coming_soon: false,
      products: products,
      services: services,
      payment_methods: payment_methods
    }
  end
end
