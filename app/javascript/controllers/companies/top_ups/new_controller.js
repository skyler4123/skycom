import Companies_LayoutController from "controllers/companies/layout_controller"

// Top-up page — displays the country-based top-up tiers (from CREDIT_RATES)
// and the company's b2b payment options. Selection UI only; the actual
// payment flow is future work (handleSubmit is a placeholder).
// Depends on BE: Companies::TopUpsController#new|mock_qr_gateway (+ mock_redirect),
//               Webhooks::Payments::MockQrGatewayController (top_up_completed)
// Endpoints: Helpers.new_company_top_up_path, mock_qr_gateway_company_top_ups_path
export default class Companies_TopUps_NewController extends Companies_LayoutController {
  static targets = ["tierList"]

  /** @type {Array} */ topUpOptions = []
  /** @type {Array} */ paymentMethods = []
  /** @type {string | null} */ selectedTier = null
  /** @type {string | null} */ selectedMethodId = null

  async connect() {
    super.connect()

    poll(() => {
      if (currentCompany()) {
        this.loadData()
        return true
      }
      return false
    })
  }

  async loadData() {
    try {
      const response = await fetchJson(`${Helpers.new_company_top_up_path(currentCompany().id)}.json`)
      this.topUpOptions = response.top_up_options || []
      this.paymentMethods = response.payment_methods || []
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to load top-up options") })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  formatCents(cents) {
    const currency = currentCompany()?.currency || "usd"
    if (currency === "vnd") {
      return `${Number(cents || 0).toLocaleString("vi-VN")}₫`
    }
    const dollars = Number(cents || 0) / 100
    return `$${dollars.toLocaleString("en-US", { minimumFractionDigits: 2 })}`
  }

  formatCredits(value) {
    return Number(value || 0).toLocaleString("en-US")
  }

  tierCardsHTML() {
    if (this.topUpOptions.length === 0) {
      return `<p class="text-sm text-slate-500">${translate("No top-up options available")}</p>`
    }

    return this.topUpOptions.map(t => {
      const selected = this.selectedTier === String(t.money_amount_cents)
      return `
        <div
          data-action="click->${this.identifier}#selectTier"
          data-${this.identifier}-money-cents-param="${t.money_amount_cents}"
          class="relative flex flex-col items-center gap-1 p-5 rounded-xl border-2 cursor-pointer transition-all bg-white dark:bg-slate-900
            ${selected
              ? "border-blue-500 bg-blue-50 dark:bg-blue-900/20 dark:border-blue-400"
              : "border-slate-200 dark:border-slate-700 hover:border-blue-300 dark:hover:border-blue-600"}"
        >
          <span class="text-lg font-black text-slate-900 dark:text-white">${this.formatCents(t.money_amount_cents)}</span>
          <span class="text-xs font-medium text-slate-500 dark:text-slate-400">${this.formatCredits(t.credit_amount)} ${translate("Credits")}</span>
          ${selected ? `<span class="absolute top-2 right-2 material-symbols-outlined text-blue-600 dark:text-blue-400 text-[20px]">check_circle</span>` : ""}
        </div>
      `
    }).join("")
  }

  selectTier(event) {
    this.selectedTier = String(event.params.moneyCents)
    this.tierListTarget.innerHTML = this.tierCardsHTML()
  }

  selectMethod(event) {
    const methodId = event.params.methodId

    document.querySelectorAll(".payment-method-card").forEach(card => {
      const isSelected = card.getAttribute("data-method-id") === methodId
      card.classList.remove(
        "border-blue-500", "bg-blue-50", "dark:bg-blue-900/20", "dark:border-blue-400",
        "border-slate-200", "dark:border-slate-700", "bg-white", "dark:bg-slate-900"
      )
      if (isSelected) {
        card.classList.add("border-blue-500", "bg-blue-50", "dark:bg-blue-900/20", "dark:border-blue-400")
      } else {
        card.classList.add("border-slate-200", "dark:border-slate-700", "bg-white", "dark:bg-slate-900")
      }

      const checkEl = card.querySelector(".selected-check")
      if (isSelected && !checkEl) {
        card.insertAdjacentHTML("beforeend",
          `<span class="selected-check material-symbols-outlined text-blue-600 dark:text-blue-400 text-[20px]">check_circle</span>`
        )
      } else if (!isSelected && checkEl) {
        checkEl.remove()
      }
    })

    this.selectedMethodId = methodId
  }

  contentHTML() {
    const cid = currentCompany()?.id

    const methodCards = this.paymentMethods.length > 0
      ? this.paymentMethods.map(m => {
          const possible = m.lifecycle_status === "active"
          const iconMap = { qr: "qr_code_scanner", redirect: "open_in_new", cash: "payments" }
          const icon = iconMap[m.payment_mode] || "credit_card"

          const clickAttr = possible
            ? `data-action="click->${this.identifier}#selectMethod" data-${this.identifier}-method-id-param="${m.id}"`
            : `title="${translate("Not available")}"`

          return `
            <div ${clickAttr}
              data-method-id="${m.id}"
              class="payment-method-card relative flex items-start gap-4 p-4 rounded-xl border-2 cursor-pointer transition-all
                border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900
                ${!possible ? "opacity-50 cursor-not-allowed" : "hover:border-blue-300 dark:hover:border-blue-600"}">
              <div class="flex items-center justify-center w-10 h-10 rounded-lg bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 shrink-0">
                <span class="material-symbols-outlined text-[22px]">${icon}</span>
              </div>
              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-2 flex-wrap">
                  <span class="text-sm font-semibold text-slate-900 dark:text-white">${m.name}</span>
                  ${!possible ? `<span class="text-[10px] font-bold text-slate-400 uppercase">${translate("Not available")}</span>` : ""}
                </div>
                <p class="text-xs text-slate-500 dark:text-slate-400 mt-0.5">${m.code || ""}</p>
              </div>
            </div>
          `
        }).join("")
      : `<p class="text-sm text-slate-500">${translate("No payment methods available")}</p>`

    return `
      <div class="p-4 md:p-6 overflow-y-auto">
        <div class="mx-auto p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <a href="${Helpers.company_billing_path(cid)}"
            class="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700 mb-6 cursor-pointer">
            <span class="material-symbols-outlined text-[18px]">arrow_back</span>
            ${translate("Back to Billing")}
          </a>

          <div class="space-y-8" id="top-up-form">
            <div class="space-y-3">
              <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Top Up")}</h2>
              <div class="space-y-2">
                <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Top Up Options")}</label>
                <div data-${this.identifier}-target="tierList" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
                  ${this.tierCardsHTML()}
                </div>
              </div>
            </div>

            <div class="space-y-3">
              <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Payment Method")}</label>
              <div class="space-y-2">${methodCards}</div>
            </div>

            <button type="button"
              data-action="click->${this.identifier}#handleSubmit"
              class="w-full px-4 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm transition-colors cursor-pointer">
              ${translate("Confirm Top Up")}
            </button>
          </div>
        </div>
      </div>
    `
  }

  async handleSubmit(event) {
    event.preventDefault()

    const cid = currentCompany()?.id
    if (!cid) return

    const rawAmount = parseInt(this.selectedTier || "0", 10)
    if (!this.selectedTier || rawAmount <= 0) {
      toast({ type: "warning", message: translate("Please select a top-up option") })
      return
    }

    const method = this.paymentMethods.find(m => m.id === this.selectedMethodId)
    if (!method) {
      toast({ type: "warning", message: translate("Please select a payment method") })
      return
    }

    try {
      const payload = { money_amount_cents: rawAmount }

      if (method.strategy === "mock_qr_gateway") {
        const response = await fetchJson(Helpers.mock_qr_gateway_company_top_ups_path(cid), {
          method: "POST",
          body: payload
        })
        this.renderQRWait(response, rawAmount, cid)
      } else if (method.strategy === "mock_redirect_gateway") {
        const response = await fetchJson(Helpers.mock_redirect_gateway_company_top_ups_path(cid), {
          method: "POST",
          body: payload
        })
        window.location.href = response.redirect_url
      } else {
        toast({ type: "warning", message: translate("This payment method is not available yet") })
      }
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Top-up failed") })
    }
  }

  renderQRWait(response, amountCents, companyId) {
    const { qr_string } = response
    const formEl = document.getElementById("top-up-form")
    if (!formEl) return

    formEl.innerHTML = `
      <div class="space-y-6 text-center">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Scan to Pay")}</h2>
        <p class="text-sm text-slate-500">${translate("Scan the QR code with your banking app to complete the top-up.")}</p>
        <p class="text-lg font-black text-slate-900 dark:text-white">${this.formatCents(amountCents)}</p>
        <div class="flex justify-center">
          <div class="w-64 h-64 bg-white rounded-xl p-4 border border-slate-200 dark:border-slate-700 flex items-center justify-center" id="qr-container"></div>
        </div>
        <div class="flex items-center justify-center gap-2 text-sm text-amber-600">
          <span class="material-symbols-outlined text-[18px] animate-pulse">hourglass_top</span>
          ${translate("Waiting for payment confirmation...")}
        </div>
        <button type="button" data-action="click->${this.identifier}#cancelWait"
          class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg cursor-pointer">
          ${translate("Cancel")}
        </button>
      </div>
    `

    setTimeout(() => {
      const qrContainer = document.getElementById("qr-container")
      if (qrContainer && window.renderQrCode) {
        window.renderQrCode(qrContainer, qr_string)
      }
    }, 50)

    const ws = window.WEBSOCKET
    if (ws?.companyChannel && ws?.subscribe) {
      const channel = ws.companyChannel(currentCompany()?.id)
      ws.subscribe(channel, "top_up_completed", () => {
        toast({ type: "success", message: translate("Top-up successful! Redirecting...") })
        setTimeout(() => {
          window.location.href = Helpers.company_usage_path(companyId)
        }, 500)
      })
    }
  }

  cancelWait() {
    this.selectedTier = null
    this.selectedMethodId = null
    this.renderContent()
  }
}
