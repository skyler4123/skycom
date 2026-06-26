# frozen_string_literal: true

# Billing portal accessible by blocked companies to view and pay outstanding invoices.
# This controller is exempt from the check_accessable before_action.
#
# Routes (nested under companies):
#   GET  /companies/:company_id/billing      → billing#show (suspended portal)
#   POST /companies/:company_id/billing/pay  → billing#pay_all (pay outstanding invoices)
#
class Companies::BillingController < Companies::ApplicationController
  skip_before_action :check_accessable, only: %i[show pay_all]

  def show
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        invoices = current_company.billing_invoices
                                  .where(payment_status: %i[unpaid overdue])
                                  .order(:created_at)

        render json: {
          company: { name: current_company.name, lifecycle_status: current_company.lifecycle_status },
          invoices: invoices.map { |inv|
            { id: inv.id, invoice_number: inv.invoice_number,
              price_cents: inv.price_cents, payment_status: inv.payment_status,
              created_at: inv.created_at }
          },
          wallet: { main_balance_cents: current_company.main_balance_cents,
                    promo_balance_cents: current_company.promo_balance_cents }
        }
      end
    end
  end

  def pay_all
    invoices = current_company.billing_invoices
                              .where(payment_status: %i[unpaid overdue])
                              .order(:created_at)

    if invoices.none?
      return render json: { message: "No outstanding invoices.", reactivated: false, remaining_cents: 0 }
    end

    result = Billing::SettlementService.settle_all(current_company)

    company = current_company.reload
    reactivated = company.lifecycle_status_active?

    render json: {
      message: reactivated ? "All invoices paid. Account reactivated!" : "Invoices settled.",
      paid_count: result[:paid_count],
      reactivated: reactivated,
      remaining_cents: result[:remaining_cents]
    }
  end
end
