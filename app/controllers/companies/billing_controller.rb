# frozen_string_literal: true

class Companies::BillingController < Companies::ApplicationController
  def show
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        orders = current_company.company_orders.includes(:company_invoice).order(created_at: :desc)
        render json: {
          wallet: { credit_balance: current_company.company_wallet.credit_balance, currency: current_company.currency },
          orders: orders.map { |o| format_order(o) }
        }
      end
    end
  end

  private

  def format_order(order)
    invoice = order.company_invoice
    order.as_json(only: %i[id money_amount_cents credit_amount currency workflow_status created_at]).merge(
      invoice: invoice && {
        id: invoice.id,
        invoice_number: invoice.invoice_number,
        payment_status: invoice.payment_status,
        transactions: invoice.company_transactions.includes(:billing_payment_method).map { |t|
          t.as_json(only: %i[id money_amount_cents status gateway_reference created_at]).merge(
            billing_payment_method: t.billing_payment_method&.name
          )
        }
      }
    )
  end
end
