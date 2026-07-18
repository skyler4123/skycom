import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_TopUps_NewController extends Companies_LayoutController {
  /** @type {Array} */ paymentMethods = []
  /** @type {string|null} */ selectedMethodId = null
  /** @type {string|null} */ wsChannel = null

  async connect() {
    super.connect()

    try {
      const response = await fetchJson()
      this.paymentMethods = response.billing_payment_methods || []
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to load payment methods") })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  disconnect() {
    if (this.wsChannel) {
      document.removeEventListener(`ws:${this.wsChannel}`, this)
    }
  }

  handleEvent(event) {
    if (event.type === `ws:${this.wsChannel}` && event.detail?.event === "top_up.completed") {
      toast({ type: "success", message: translate("Top-up successful! Redirecting...") })
      setTimeout(() => {
        window.location.href = Helpers.company_billing_path(currentCompany()?.id)
      }, 1500)
    }
  }

  contentHTML() {
    const cid = currentCompany()?.id

    const methodCards = this.paymentMethods.length > 0
      ? this.paymentMethods.map(m => {
          const isQr = m.strategy === "mock_qr_gateway"
          const isRedirect = m.strategy === "mock_redirect_gateway"
          const possible = isQr || isRedirect
          const icon = isQr ? "qr_code_scanner" : isRedirect ? "open_in_new" : "credit_card"

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
                  ${isRedirect ? `<span class="px-2 py-0.5 text-[10px] font-bold text-amber-700 bg-amber-50 dark:text-amber-400 dark:bg-amber-900/30 rounded-full uppercase">${translate("Coming soon")}</span>` : ""}
                </div>
                <p class="text-xs text-slate-500 dark:text-slate-400 mt-0.5">${m.description || ""}</p>
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

          <div>
            <div class="space-y-6" id="top-up-form">
              <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Top Up Wallet")}</h2>
              <p class="text-sm text-slate-500">${translate("Add funds to your wallet to cover overage charges and feature add-ons.")}</p>

              <div class="space-y-1">
                <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Amount")}</label>
                <input type="number" id="top-up-amount" min="1" step="1" required placeholder="e.g. 1000"
                  class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white" />
              </div>

              <div class="space-y-3">
                <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Payment Method")}</label>
                <div class="space-y-2" id="payment-methods-list">
                  ${methodCards}
                </div>
              </div>

              <button type="button"
                data-action="click->${this.identifier}#handleSubmit"
                class="w-full px-4 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm transition-colors cursor-pointer">
                ${translate("Confirm Top Up")}
              </button>
            </div>
          </div>
        </div>
      </div>
    `
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

  async handleSubmit(event) {
    event.preventDefault()
    const cid = currentCompany()?.id
    const amountCents = parseInt(document.getElementById("top-up-amount")?.value) || 0
    if (!cid || !this.selectedMethodId || amountCents <= 0) return

    try {
      const response = await fetchJson(Helpers.create_company_top_ups_path(cid), {
        method: "POST",
        body: {
          amount_cents: amountCents,
          billing_payment_method_id: this.selectedMethodId
        }
      })

      this.renderQRWait(response, amountCents, cid)
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Top-up failed") })
    }
  }

  renderQRWait(response, amountCents, companyId) {
    const { qr_string, websocket_channel, websocket_token } = response
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

    this.wsChannel = websocket_channel
    document.addEventListener(`ws:${this.wsChannel}`, this)
    document.dispatchEvent(
      new CustomEvent("ws:subscribe", {
        detail: { channel: websocket_channel, token: websocket_token }
      })
    )
  }

  formatCents(cents) {
    const currency = currentCompany()?.currency || "usd"
    if (currency === "vnd") {
      return `${Number(cents).toLocaleString("vi-VN")}₫`
    }
    return `$${(Number(cents) / 100).toFixed(2)}`
  }

  cancelWait() {
    if (this.wsChannel) {
      document.removeEventListener(`ws:${this.wsChannel}`, this)
      this.wsChannel = null
    }
    this.selectedMethodId = null
    this.renderContent()
  }
}
