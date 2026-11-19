import { Controller } from "@hotwired/stimulus"

export default class Companies_Operations_Pos_ShowController extends Controller {
  // POS — Cart (tabs[].items[] in memory) → ORDER → pay → receipt.
  // Click card → addToCart mutates local cart only; ORDER flushes to Order+OrderProductAppointment; pay reads DB snapshots.
  // Mounted by the web layout and by Mobile::Companies::Operations::PosController (Shell-First;
  // the mobile shell supplies data-company-id / data-operation-id / data-user-*).
  // Depends on BE: Companies::Operations::PosController#show/catalog/customer_lookup/lock/unlock,
  //               Companies::OrderProcessing::V1Controller#checkout|pay|pay_cancel|apply_discount|remove_discount|cancel,
  //               Companies::OrdersController#receipt,
  //               Webhooks::Payments::MockQrGatewayController (QR webhook → WS pos_payment_completed)
  // Endpoints: Helpers.pos_company_operation_path, pos_catalog_company_operation_path,
  //            pos_customer_lookup_company_operation_path, pos_lock/unlock_company_operation_path,
  //            order_processing_v1_*_path, receipt_company_order_path
  // Docs: docs/ORDER_PROCESSING_V1.md
  /** @type {any | null} */ operation = null
  /** @type {string | null} */ operationId = null
  /** @type {any | null} */ appointment = null
  /** @type {any[]} */ products = []
  /** @type {any[]} */ services = []
  /** @type {{ id: number, name: string, customer: any | null, items: { kind: string, id: any, name: string, priceCents: number, qty: number, stockQuantity?: number, priceSet?: boolean }[], orderId: string | null, orderTotalCents: number, appliedDiscount: any | null, cashReceivedCents: number, awaitingToken: string | null }[]} */ tabs = []
  /** @type {number} */ activeTabIndex = 0
  /** @type {number} */ tabCounter = 0
  /** @type {string} */ currency = "usd"
  /** @type {{ rate_bp: number, rate_percent: number, name: string }} */ tax = { rate_bp: 0, rate_percent: 0, name: "Tax" }
  /** @type {{ limit: number, products_total: number, services_total: number }} */ catalogMeta = { limit: 50, products_total: 0, services_total: 0 }
  /** @type {"grid"|"list"} */ viewMode = "grid"
  /** @type {boolean} */ locked = false
  /** @type {boolean} */ lockSubmitting = false
  /** @type {boolean} */ orderSubmitting = false
  /** @type {boolean} */ paySubmitting = false
  /** @type {boolean} */ discountSubmitting = false
  /** @type {string} */ searchError = ""
  /** @type {number} */ searchRequestId = 0
  /** @type {boolean} */ serverSearchActive = false
  /** @type {any[]} */ paymentMethods = []
  /** @type {string | null} */ selectedMethodId = null
  /** @type {string | null} */ selectedCategoryName = null
  /** @type {string} */ searchQuery = ""

  async connect() {
    const pathParts = window.location.pathname.split("/")
    const companyId = this.element.dataset.companyId || pathParts[2]
    const operationId = this.element.dataset.operationId || pathParts[4]
    this.operationId = operationId

    this.boundF1 = (event) => {
      if (event.key !== "F1") return
      event.preventDefault()
      const input = document.getElementById("barcode-input")
      if (!input) return
      input.focus()
      input.select()
    }
    window.addEventListener("keydown", this.boundF1)

    try {
      const branchId = new URLSearchParams(window.location.search).get("branch_id")
      const baseUrl = `${Helpers.pos_company_operation_path(companyId, operationId)}.json`
      const url = branchId ? `${baseUrl}?branch_id=${encodeURIComponent(branchId)}` : baseUrl
      const response = await fetchJson(url)
      this.operation = response.operation
      this.appointment = response.appointment
      this.products = response.products || []
      this.services = response.services || []
      this.paymentMethods = response.payment_methods || []
      this.selectedMethodId = this.paymentMethods[0]?.id || null
      this.currency = response.currency || "usd"
      this.tax = response.tax || { rate_bp: 0, rate_percent: 0, name: "Tax" }
      this.catalogMeta = response.catalog || { limit: 50, products_total: this.products.length, services_total: this.services.length }
      this.locked = Boolean(response.locked)
      this.viewMode = localStorage.getItem("pos_view_mode") === "list" ? "list" : "grid"

      this.restoreState()
      if (this.tabs.length === 0) {
        this.addTab()
      } else {
        this.renderContent()
        if (!this.locked) this.focusBarcode()
        if (this.tabs.some((tab) => tab.awaitingToken)) {
          this.subscribePaymentCompleted()
          if (this.activeTab?.awaitingToken && this.activeTab.qrString) {
            this.renderQrCodeInto(this.activeTab.qrString)
          }
        }
      }
    } catch (error) {
      this.element.innerHTML = `<div class="flex items-center justify-center h-screen text-danger text-lg font-semibold">${translate("Failed to load cashier screen.")}</div>`
    }
  }

  disconnect() {
    if (this.boundF1) window.removeEventListener("keydown", this.boundF1)
  }

  // --- Tabs (one customer per tab) -------------------------------------------------

  addTab() {
    this.tabCounter++
    const walkInName = this.tabCounter === 1 ? translate("Walk-in") : `${translate("Walk-in")} ${this.tabCounter}`
    this.tabs.push({
      id: this.tabCounter, name: walkInName, customer: null, items: [],
      orderId: null, orderTotalCents: 0, appliedDiscount: null,
      cashReceivedCents: 0, awaitingToken: null, qrString: null
    })
    this.activeTabIndex = this.tabs.length - 1
    this.renderContent()
    this.focusBarcode()
  }

  switchTab(event) {
    this.activeTabIndex = Number(event.params.index)
    this.saveState()
    this.renderContent()
    if (this.activeTab?.awaitingToken && this.activeTab.qrString) {
      this.renderQrCodeInto(this.activeTab.qrString)
    }
    this.focusBarcode()
  }

  async closeTab(event) {
    const index = Number(event.params.index)
    if (this.tabs.length <= 1) return
    const tab = this.tabs[index]
    if (!tab) return

    if (tab.items.length > 0 || tab.customer || tab.orderId) {
      const result = await Helpers.confirmAction({
        title: translate("Discard this sale?"),
        text: tab.orderId
          ? translate("This closes the tab and voids the order.")
          : translate("This closes the tab. Nothing is saved."),
        confirmButtonText: translate("Discard"),
        cancelButtonText: translate("Keep")
      })
      if (!result.isConfirmed) return
    }

    if (tab.orderId) {
      try {
        await fetchJson(Helpers.order_processing_v1_cancel_path(this.getCompanyId()), {
          method: "POST",
          body: { order_id: tab.orderId }
        })
      } catch (error) {
        if (error.status === 423) this.locked = true
        toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to void the order") })
        this.renderContent()
        return
      }
    }

    this.tabs.splice(index, 1)
    if (index < this.activeTabIndex) {
      this.activeTabIndex--
    } else if (index === this.activeTabIndex) {
      this.activeTabIndex = Math.max(0, index - 1)
    }
    this.saveState()
    this.renderContent()
  }

  get activeTab() {
    return this.tabs[this.activeTabIndex]
  }

  // Sale state belongs to the tab, not the page. These accessors keep the
  // existing render/method code readable while each customer keeps their own
  // order, discount, cash, QR token, and receipt.
  get orderId() {
    return this.activeTab?.orderId || null
  }

  set orderId(value) {
    if (this.activeTab) this.activeTab.orderId = value
  }

  get orderTotalCents() {
    return this.activeTab?.orderTotalCents || 0
  }

  set orderTotalCents(value) {
    if (this.activeTab) this.activeTab.orderTotalCents = Number(value) || 0
  }

  get cashReceived() {
    return this.activeTab?.cashReceivedCents || 0
  }

  set cashReceived(value) {
    if (this.activeTab) this.activeTab.cashReceivedCents = Number(value) || 0
  }

  get awaitingToken() {
    return this.activeTab?.awaitingToken || null
  }

  set awaitingToken(value) {
    if (this.activeTab) this.activeTab.awaitingToken = value
  }

  get receipt() {
    return this.activeTab?.receipt || null
  }

  set receipt(value) {
    if (this.activeTab) this.activeTab.receipt = value
  }

  get appliedDiscount() {
    return this.activeTab?.appliedDiscount || null
  }

  set appliedDiscount(value) {
    if (this.activeTab) this.activeTab.appliedDiscount = value
  }

  // --- Catalog filtering -----------------------------------------------------------

  get companyCategories() {
    if (typeof window.currentCategories !== "function") return []
    return window.currentCategories() || []
  }

  get catalogCategories() {
    const names = new Set()

    this.companyCategories
      .filter((category) => category && ["products", "services"].includes(category.resource_name))
      .forEach((category) => {
        if (category.name) names.add(category.name)
      })

    // Fallback: keep pills usable even when client_cache has not synced yet.
    const catalogItems = [...this.products, ...this.services]
    catalogItems.forEach((item) => {
      if (item.category_name) names.add(item.category_name)
    })

    return [...names].sort((a, b) => String(a).localeCompare(String(b)))
  }

  categoryNameFor(item) {
    if (item.category_name) return item.category_name
    const category = this.companyCategories.find((c) => String(c.id) === String(item.category_id))
    return category?.name || null
  }

  get filteredProducts() {
    const query = this.serverSearchActive ? "" : this.searchQuery.trim().toLowerCase()
    return this.products.filter((product) => {
      if (this.selectedCategoryName && this.categoryNameFor(product) !== this.selectedCategoryName) return false
      if (!query) return true
      return `${product.name || ""} ${product.code || ""}`.toLowerCase().includes(query)
    })
  }

  get filteredServices() {
    const query = this.serverSearchActive ? "" : this.searchQuery.trim().toLowerCase()
    return this.services.filter((service) => {
      if (this.selectedCategoryName && this.categoryNameFor(service) !== this.selectedCategoryName) return false
      if (!query) return true
      return `${service.name || ""} ${service.code || ""}`.toLowerCase().includes(query)
    })
  }

  selectCategory(event) {
    this.selectedCategoryName = event.params.name || null
    this.renderContent()
  }

  setViewMode(event) {
    this.viewMode = event.params.mode === "list" ? "list" : "grid"
    localStorage.setItem("pos_view_mode", this.viewMode)
    this.renderContent()
  }

  updateSearch(event) {
    this.searchQuery = event.target.value
    this.searchError = ""
    this.refreshSearchError()
    this.refreshCatalog()

    clearTimeout(this.searchTimer)
    const query = this.searchQuery.trim()
    if (!query) {
      this.serverSearchActive = false
      this.loadCatalog("")
      return
    }

    this.searchTimer = setTimeout(() => this.loadCatalog(query), 300)
  }

  async loadCatalog(query) {
    if (this.locked) return
    const requestId = ++this.searchRequestId
    const branchId = this.appointment?.branch?.id ||
      new URLSearchParams(window.location.search).get("branch_id")
    const params = { q: query }
    if (branchId) params.branch_id = branchId
    try {
      const res = await fetchJson(
        Helpers.pos_catalog_company_operation_path(this.getCompanyId(), this.operationId, params)
      )
      if (requestId !== this.searchRequestId) return

      this.products = res.products || []
      this.services = res.services || []
      this.currency = res.currency || this.currency
      this.tax = res.tax || this.tax
      this.catalogMeta = res.catalog || this.catalogMeta
      this.serverSearchActive = Boolean(query)
      this.refreshCatalog()
    } catch (error) {
      if (requestId !== this.searchRequestId) return
      toast({ type: "error", message: error.errors?.join(", ") || translate("Search is temporarily unavailable") })
    }
  }

  async handleBarcodeEnter(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }
    if (this.locked) return
    const input = document.getElementById("barcode-input")
    const query = (input?.value || this.searchQuery || "").trim().toLowerCase()
    if (!query) return

    let product = this.products.find((item) => String(item.code || "").toLowerCase() === query)
    let service = this.services.find((item) => String(item.code || "").toLowerCase() === query)
    let kind = product ? "product" : (service ? "service" : null)

    if (!product && !service) {
      const found = await this.findCatalogItem(query)
      if (found) {
        kind = found.kind
        product = found.kind === "product" ? found.item : null
        service = found.kind === "service" ? found.item : null
      }
    }

    const match = product || service
    if (!match) {
      this.searchError = translate("Code not found")
      this.refreshSearchError()
      return
    }

    this.searchQuery = ""
    this.searchError = ""
    this.serverSearchActive = false
    this.refreshSearchError()
    if (input) input.value = ""
    this.addToCart({
      params: {
        id: match.id,
        kind,
        name: match.name,
        priceCents: match.price_cents,
        priceSet: match.price_set,
        stockQuantity: product ? match.stock_quantity : 0
      }
    })
    this.loadCatalog("")
  }

  async findCatalogItem(code) {
    const branchId = this.appointment?.branch?.id ||
      new URLSearchParams(window.location.search).get("branch_id")
    const params = { q: code }
    if (branchId) params.branch_id = branchId
    try {
      const res = await fetchJson(
        Helpers.pos_catalog_company_operation_path(this.getCompanyId(), this.operationId, params)
      )
      const product = (res.products || []).find(
        (item) => String(item.code || "").toLowerCase() === code
      )
      if (product) return { kind: "product", item: product }
      const service = (res.services || []).find(
        (item) => String(item.code || "").toLowerCase() === code
      )
      if (service) return { kind: "service", item: service }
    } catch (_error) {
      return null
    }
    return null
  }

  refreshSearchError() {
    const error = document.getElementById("pos-search-error")
    const input = document.getElementById("barcode-input")
    if (error) {
      error.textContent = this.searchError
      error.classList.toggle("hidden", !this.searchError)
    }
    if (input) {
      input.classList.toggle("ring-2", Boolean(this.searchError))
      input.classList.toggle("ring-danger", Boolean(this.searchError))
    }
  }

  refreshCatalog() {
    const grid = document.getElementById("pos-product-grid")
    if (grid) {
      grid.className = this.productContainerClasses()
      grid.innerHTML = this.renderProductCards()
    }

    const services = document.getElementById("pos-services-section")
    if (services) services.innerHTML = this.renderServicesList()

    const productCap = document.getElementById("pos-product-cap")
    if (productCap) productCap.outerHTML = this.renderCap("product", this.catalogMeta.products_total, this.filteredProducts.length)
    const serviceCap = document.getElementById("pos-service-cap")
    if (serviceCap) serviceCap.outerHTML = this.renderCap("service", this.catalogMeta.services_total, this.filteredServices.length)
  }

  // --- Cart ------------------------------------------------------------------------

  // Card click → local cart (no API). Locked when orderId exists. Dupe → qty++.
  addToCart(event) {
    if (this.locked || this.orderId || !this.activeTab) return
    const { id, kind = "product", name, priceCents, priceSet, stockQuantity } = event.params
    if (String(priceSet) === "false") {
      toast({ type: "warning", message: translate("Price is not set for this item") })
      return
    }

    const quantity = Number(stockQuantity || 0)
    if (kind === "product" && quantity <= 0) {
      toast({ type: "warning", message: translate("Out of stock") })
      return
    }

    const existing = this.activeTab.items.find(
      (item) => String(item.id) === String(id) && item.kind === kind
    )
    if (existing) {
      if (kind === "product" && existing.qty >= quantity) {
        toast({ type: "warning", message: `${translate("Only")} ${quantity} ${translate("available")}` })
        return
      }
      existing.qty++
    } else {
      this.activeTab.items.push({
        kind, id, name,
        priceCents: Number(priceCents) || 0,
        qty: 1,
        stockQuantity: quantity,
        priceSet: true
      })
    }
    this.saveState()
    this.renderContent()
    this.focusBarcode()
  }

  removeFromCart(event) {
    if (this.orderId || !this.activeTab) return
    const { id, kind = "product" } = event.params
    this.activeTab.items = this.activeTab.items.filter(
      (item) => !(String(item.id) === String(id) && item.kind === kind)
    )
    this.saveState()
    this.renderContent()
  }

  updateQty(event) {
    if (this.orderId || !this.activeTab) return
    const { id, kind = "product", delta } = event.params
    const item = this.activeTab.items.find(
      (candidate) => String(candidate.id) === String(id) && candidate.kind === kind
    )
    if (item) {
      const next = item.qty + Number(delta)
      if (kind === "product" && next > Number(item.stockQuantity || 0)) {
        toast({ type: "warning", message: `${translate("Only")} ${item.stockQuantity} ${translate("available")}` })
        return
      }
      item.qty = Math.max(0, next)
      if (item.qty === 0) {
        this.activeTab.items = this.activeTab.items.filter(
          (candidate) => !(String(candidate.id) === String(id) && candidate.kind === kind)
        )
      }
    }
    this.saveState()
    this.renderContent()
  }

  async clearCart() {
    if (this.orderId || !this.activeTab || this.activeTab.items.length === 0) return
    const result = await Helpers.confirmAction({
      title: translate("Discard this sale?"),
      text: translate("This clears the active tab. Nothing is saved."),
      confirmButtonText: translate("Discard"),
      cancelButtonText: translate("Keep")
    })
    if (!result.isConfirmed) return
    this.activeTab.items = []
    this.saveState()
    this.renderContent()
  }

  cartQuantityFor(id, kind = "product") {
    if (!this.activeTab) return 0
    return this.activeTab.items
      .filter((item) => String(item.id) === String(id) && item.kind === kind)
      .reduce((sum, item) => sum + item.qty, 0)
  }

  // --- Customer lookup -------------------------------------------------------------

  focusCustomerLookup() {
    document.getElementById("pos-customer-lookup")?.focus()
  }

  async searchCustomer(event) {
    if (event) event.preventDefault()
    const input = document.getElementById("pos-customer-lookup")
    const query = (input?.value || "").trim()
    if (!query || !this.activeTab) return

    const companyId = this.getCompanyId()
    const params = { q: query }
    const branchId = this.appointment?.branch?.id || new URLSearchParams(window.location.search).get("branch_id")
    if (branchId) params.branch_id = branchId

    try {
      const response = await fetchJson(
        Helpers.pos_customer_lookup_company_operation_path(companyId, this.operationId, params)
      )
      const customer = response.customer || null

      if (!customer) {
        toast({ type: "warning", message: translate("Customer not found") })
        return
      }

      this.activeTab.customer = customer
      this.activeTab.name = customer.name || this.activeTab.name
      this.saveState()
      this.renderContent()
      toast({ type: "success", message: translate("Customer selected") })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message || translate("Failed to find customer") })
    }
  }

  clearCustomer() {
    if (!this.activeTab) return
    this.activeTab.customer = null
    this.activeTab.name = this.activeTab.id === 1 ? translate("Walk-in") : `${translate("Walk-in")} ${this.activeTab.id}`
    this.saveState()
    this.renderContent()
  }

  initialsFor(name) {
    const parts = String(name || "").trim().split(/\s+/).filter(Boolean)
    if (parts.length === 0) return "?"
    return parts.slice(0, 2).map((part) => part[0].toUpperCase()).join("")
  }

  // --- Payment / order lifecycle ---------------------------------------------------

  setPaymentMethod(event) {
    this.selectedMethodId = event.params.methodId
    this.renderContent()
  }

  getSelectedMethod() {
    return this.paymentMethods.find((method) => String(method.id) === String(this.selectedMethodId))
  }

  get isQrMode() {
    return this.getSelectedMethod()?.payment_mode === "qr"
  }

  async applyDiscount(event) {
    if (event) event.preventDefault()
    if (this.discountSubmitting || !this.orderId) return
    const input = document.getElementById("pos-discount-code")
    const code = (input?.value || "").trim()
    if (!code) return

    this.discountSubmitting = true
    try {
      const res = await fetchJson(Helpers.order_processing_v1_apply_discount_path(this.getCompanyId()), {
        method: "POST",
        body: { order_id: this.orderId, discount_code: code }
      })
      this.appliedDiscount = res.discount
        ? { code: res.discount.code, amountCents: res.discount.amount_cents }
        : null
      this.orderTotalCents = res.total_cents || this.orderTotalCents
      this.discountSubmitting = false
      this.saveState()
      this.renderContent()
      toast({ type: "success", message: res.message || translate("Discount applied") })
    } catch (error) {
      this.discountSubmitting = false
      toast({ type: "error", message: error.errors?.join(", ") || error.message || translate("Code not valid") })
    }
  }

  async removeDiscount() {
    if (this.discountSubmitting || !this.orderId) return
    this.discountSubmitting = true
    try {
      const res = await fetchJson(Helpers.order_processing_v1_remove_discount_path(this.getCompanyId()), {
        method: "POST",
        body: { order_id: this.orderId }
      })
      this.appliedDiscount = null
      this.orderTotalCents = res.total_cents || this.orderTotalCents
      this.discountSubmitting = false
      this.saveState()
      this.renderContent()
      toast({ type: "success", message: res.message || translate("Discount removed") })
    } catch (error) {
      this.discountSubmitting = false
      toast({ type: "error", message: error.errors?.join(", ") || error.message || translate("Failed to remove the discount") })
    }
  }

  updateCashReceived(event) {
    const value = parseFloat(event.target.value) || 0
    this.cashReceived = this.currency === "vnd" ? Math.round(value) : Math.round(value * 100)
    this.saveState()
    this.refreshChangeDue()
  }

  setCashReceived(event) {
    this.cashReceived = Number(event.params.amount) || 0
    this.renderContent()
  }

  get quickCashAmounts() {
    const total = this.getTotalCents()
    if (!total) return []

    const steps = this.currency === "vnd" ? [ 10_000, 20_000, 50_000, 100_000 ] : [ 500, 5_000, 10_000 ]
    const roundUp = (step) => Math.ceil(total / step) * step
    return [...new Set(steps.map(roundUp))].filter((amount) => amount >= total)
  }

  refreshChangeDue() {
    const el = document.getElementById("cashier-change-due")
    if (!el) return
    const changeDue = this.getChangeDueCents()
    el.textContent = Helpers.formatMoney(changeDue, this.currency)
    el.className = `text-lg font-black ${changeDue >= 0 ? "text-success" : "text-danger"}`
  }

  async initiateOrder() {
    const tab = this.activeTab
    if (this.locked || this.orderSubmitting) return
    if (!tab || tab.items.length === 0) {
      toast({ type: "warning", message: translate("Cart is empty") })
      return
    }

    const companyId = this.getCompanyId()
    const items = tab.items.map((item) => (
      item.kind === "service"
        ? { service_id: item.id, quantity: item.qty }
        : { product_id: item.id, quantity: item.qty }
    ))

    this.orderSubmitting = true
    this.renderContent()
    try {
      const body = { branch_id: this.appointment.branch.id, items }
      if (tab.customer?.id) body.customer_id = tab.customer.id

      const res = await fetchJson(Helpers.order_processing_v1_checkout_path(companyId), {
        method: "POST",
        body
      })
      this.orderId = res.order_id
      this.orderTotalCents = res.total_cents || 0
      this.tax = {
        rate_bp: res.tax_rate_bp || 0,
        rate_percent: (res.tax_rate_bp || 0) / 100,
        name: res.tax_name || "Tax"
      }

      const prices = new Map((res.items || []).map((line) => [ `${line.kind}:${line.id}`, line.unit_price_cents ]))
      let changed = false
      tab.items.forEach((item) => {
        const next = prices.get(`${item.kind}:${item.id}`)
        if (next != null && Number(next) !== Number(item.priceCents)) {
          item.priceCents = Number(next)
          changed = true
        }
      })
      this.cashReceived = this.getTotalCents()
      this.orderSubmitting = false
      this.saveState()
      this.renderContent()
      toast({ type: "success", message: res.message || translate("Order created") })
      if (changed) toast({ type: "warning", message: translate("Prices updated from the catalog") })
    } catch (error) {
      this.orderSubmitting = false
      toast({ type: "error", message: error.errors?.join(", ") || error.message || translate("Failed to create order") })
      this.renderContent()
    }
  }

  async pay() {
    if (this.locked || this.paySubmitting) return
    if (!this.selectedMethodId) {
      toast({ type: "warning", message: translate("No payment method is available for this branch") })
      return
    }
    this.paySubmitting = true
    try {
      const res = await fetchJson(Helpers.order_processing_v1_pay_path(this.getCompanyId()), {
        method: "POST",
        body: {
          order_id: this.orderId,
          payment_method_appointment_id: this.selectedMethodId,
          cash_received_cents: this.cashReceived
        }
      })

      if (res.status === "pending") {
        this.awaitingToken = res.transaction_token
        if (this.activeTab) this.activeTab.qrString = res.qr_string || null
        this.orderTotalCents = res.total_cents || this.orderTotalCents
        this.paySubmitting = false
        this.subscribePaymentCompleted()
        this.saveState()
        this.renderContent()
        this.renderQrCodeInto(res.qr_string)
        return
      }

      this.orderTotalCents = res.total_cents || this.orderTotalCents
      this.paySubmitting = false
      toast({ type: "success", message: res.message || translate("Payment completed") })
      await this.showReceipt()
    } catch (error) {
      if (error.status === 423) this.locked = true
      const message = error.errors?.join(", ") || error.message || translate("Payment failed")
      if (/discount/i.test(message)) this.appliedDiscount = null
      this.paySubmitting = false
      toast({ type: "error", message })
      this.saveState()
      this.renderContent()
    }
  }

  async showReceipt() {
    return this.showReceiptForTab(this.activeTab)
  }

  async showReceiptForTab(tab) {
    if (!tab?.orderId) return
    try {
      const res = await fetchJson(Helpers.receipt_company_order_path(this.getCompanyId(), tab.orderId))
      tab.receipt = res.receipt || null
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to load receipt") })
    }
    tab.items = []
    tab.orderId = null
    tab.orderTotalCents = 0
    tab.appliedDiscount = null
    tab.cashReceivedCents = 0
    tab.awaitingToken = null
    tab.qrString = null
    this.saveState()
    if (tab.id === this.activeTab?.id) this.renderContent()
  }

  newSale() {
    if (!this.activeTab) return
    this.receipt = null
    this.orderId = null
    this.orderTotalCents = 0
    this.appliedDiscount = null
    this.cashReceived = 0
    this.awaitingToken = null
    if (this.activeTab) this.activeTab.qrString = null
    this.activeTab.items = []
    this.activeTab.customer = null
    this.activeTab.name = this.activeTab.id === 1 ? translate("Walk-in") : `${translate("Walk-in")} ${this.activeTab.id}`
    this.saveState()
    this.renderContent()
    this.focusBarcode()
  }

  subscribePaymentCompleted() {
    const ws = window.WEBSOCKET
    if (!ws?.channelName || !ws?.subscribe) return
    const channel = ws.channelName("company", this.getCompanyId())
    ws.subscribe(channel, "pos_payment_completed", (data) => {
      const token = data?.payload?.transaction_token
      const tab = this.tabs.find((candidate) => candidate.awaitingToken === token)
      if (!tab) return
      toast({ type: "success", message: translate("Payment completed") })
      this.showReceiptForTab(tab)
    })
  }

  renderQrCodeInto(qrString) {
    setTimeout(() => {
      const container = document.getElementById("cashier-qr-container")
      if (container && window.renderQrCode) window.renderQrCode(container, qrString)
    }, 50)
  }

  async cancelAwaitingPayment() {
    let cancelled
    try {
      cancelled = await fetchJson(Helpers.order_processing_v1_pay_cancel_path(this.getCompanyId()), {
        method: "POST",
        body: { transaction_token: this.awaitingToken }
      })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Cancellation failed") })
      return
    }

    this.awaitingToken = null
    if (this.activeTab) this.activeTab.qrString = null
    if (cancelled?.status === "not_pending") {
      await this.showReceipt()
      return
    }
    await this.voidOrder()
  }

  async cancelOrder() {
    if (!this.orderId) {
      this.resetSale()
      return
    }
    const result = await Helpers.confirmAction({
      title: translate("Void this order?"),
      text: translate("The order is cancelled in the database. Stock and discount reservations are released."),
      confirmButtonText: translate("Void"),
      cancelButtonText: translate("Keep")
    })
    if (!result.isConfirmed) return
    await this.voidOrder()
  }

  async voidOrder() {
    const orderId = this.orderId
    if (!orderId) return
    try {
      const res = await fetchJson(Helpers.order_processing_v1_cancel_path(this.getCompanyId()), {
        method: "POST",
        body: { order_id: orderId }
      })
      this.resetSale()
      toast({ type: "success", message: res.message || translate("Order voided") })
    } catch (error) {
      if (error.status === 423) this.locked = true
      toast({ type: "error", message: error.errors?.join(", ") || error.message || translate("Failed to void the order") })
      this.renderContent()
    }
  }

  resetSale() {
    this.orderId = null
    this.orderTotalCents = 0
    this.appliedDiscount = null
    this.cashReceived = 0
    this.awaitingToken = null
    if (this.activeTab) this.activeTab.qrString = null
    this.saveState()
    this.renderContent()
  }

  getSubtotalCents() {
    if (!this.activeTab) return 0
    return this.activeTab.items.reduce(
      (sum, item) => sum + Number(item.priceCents || 0) * item.qty, 0
    )
  }

  getDiscountCents() {
    return Number(this.appliedDiscount?.amountCents || 0)
  }

  getTaxCents() {
    const taxable = Math.max(this.getSubtotalCents() - this.getDiscountCents(), 0)
    return Math.round(taxable * Number(this.tax.rate_bp || 0) / 10_000)
  }

  getTotalCents() {
    return Math.max(this.getSubtotalCents() - this.getDiscountCents(), 0) + this.getTaxCents()
  }

  getChangeDueCents() {
    return this.cashReceived - this.getTotalCents()
  }

  async lockTerminal() {
    if (this.locked || this.lockSubmitting) return
    this.lockSubmitting = true
    try {
      await fetchJson(Helpers.pos_lock_company_operation_path(this.getCompanyId(), this.operationId), {
        method: "POST",
        body: { branch_id: this.appointment?.branch?.id }
      })
      this.locked = true
      this.lockSubmitting = false
      this.saveState()
      this.renderContent()
    } catch (error) {
      this.lockSubmitting = false
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to lock the terminal") })
    }
  }

  async unlockTerminal(event) {
    event.preventDefault()
    if (this.lockSubmitting) return
    const password = new FormData(event.target).get("password")?.toString() || ""
    this.lockSubmitting = true
    try {
      await fetchJson(Helpers.pos_unlock_company_operation_path(this.getCompanyId(), this.operationId), {
        method: "POST",
        body: { password, branch_id: this.appointment?.branch?.id }
      })
      this.locked = false
      this.lockSubmitting = false
      this.saveState()
      this.renderContent()
      this.focusBarcode()
    } catch (error) {
      this.lockSubmitting = false
      toast({ type: "error", message: error.errors?.join(", ") || translate("Incorrect password") })
    }
  }

  storageKey() {
    const branchId = this.appointment?.branch?.id ||
      new URLSearchParams(window.location.search).get("branch_id") || "branch"
    return `pos_state:${this.getCompanyId()}:${this.operationId}:${branchId}`
  }

  saveState() {
    try {
      const tabs = this.tabs.map((tab) => ({
        ...tab,
        receipt: undefined
      }))
      localStorage.setItem(this.storageKey(), JSON.stringify({
        version: 1,
        tabs,
        activeTabIndex: this.activeTabIndex,
        tabCounter: this.tabCounter,
        viewMode: this.viewMode
      }))
    } catch (_error) {
      // A full quota must never stop a sale.
    }
  }

  restoreState() {
    let saved = null
    try {
      saved = JSON.parse(localStorage.getItem(this.storageKey()) || "null")
    } catch (_error) {
      saved = null
    }
    if (!saved || saved.version !== 1 || !Array.isArray(saved.tabs)) return

    this.tabs = saved.tabs
      .filter((tab) => tab && Array.isArray(tab.items))
      .map((tab) => ({
        id: Number(tab.id) || 1,
        name: tab.name || translate("Walk-in"),
        customer: tab.customer || null,
        items: tab.items.filter((item) => item && item.kind && item.id).map((item) => ({
          kind: item.kind,
          id: item.id,
          name: item.name || "",
          priceCents: Number(item.priceCents) || 0,
          qty: Number(item.qty) || 1,
          stockQuantity: Number(item.stockQuantity) || 0,
          priceSet: item.priceSet !== false
        })),
        orderId: tab.orderId || null,
        orderTotalCents: Number(tab.orderTotalCents) || 0,
        appliedDiscount: tab.appliedDiscount || null,
        cashReceivedCents: Number(tab.cashReceivedCents) || 0,
        awaitingToken: tab.awaitingToken || null,
        qrString: tab.qrString || null
      }))

    this.activeTabIndex = Math.min(
      Math.max(0, Number(saved.activeTabIndex) || 0),
      Math.max(0, this.tabs.length - 1)
    )
    this.tabCounter = Math.max(
      Number(saved.tabCounter) || 0,
      ...this.tabs.map((tab) => Number(tab.id) || 0)
    )
    this.viewMode = saved.viewMode === "list" ? "list" : (localStorage.getItem("pos_view_mode") === "list" ? "list" : "grid")
  }

  focusBarcode() {
    if (this.locked) return
    setTimeout(() => document.getElementById("barcode-input")?.focus(), 0)
  }

  // --- Rendering -------------------------------------------------------------------

  renderContent() {
    this.element.innerHTML = this.contentHTML()
  }

  contentHTML() {
    const operation = this.operation || {}
    const branchName = operation.branch?.name || this.appointment?.branch?.name || ""
    const operationName = operation.name || translate("Cashier")
    const currentUser = typeof window.currentUser === "function" ? window.currentUser() : window.currentUser
    const userName = this.element.dataset.userName || currentUser?.name || translate("Admin User")
    const userRole = this.element.dataset.userRole || currentUser?.role || translate("Administrator")
    const avatarUrl = this.element.dataset.userAvatar || currentUser?.avatar || ""

    const screen = `
      <div class="bg-background text-foreground min-h-screen flex flex-col">
        ${this.renderHeader(branchName, operationName, userName, userRole, avatarUrl)}
        <main class="flex-1 pt-16">
          <div class="w-full px-4 lg:px-6 py-3">
            <div class="grid grid-cols-1 lg:grid-cols-12 gap-3 items-start">
              <section data-operation-block="catalog" class="lg:col-span-7 xl:col-span-8 flex flex-col gap-3 min-w-0">
                ${this.renderTabs()}
                ${this.renderSearch()}
                ${this.renderCategoryPills()}
                ${this.renderProductsSection()}
                <div id="pos-services-section" data-operation-block="services">${this.renderServicesList()}</div>
              </section>
              <aside data-operation-block="order" class="lg:col-span-5 xl:col-span-4 bg-card rounded-2xl shadow-md p-3 flex flex-col gap-3 lg:sticky lg:top-20">
                ${this.renderOrderHeader()}
                ${this.renderCustomerCard()}
                <div class="flex flex-col gap-1.5 max-h-[260px] overflow-y-auto pr-1" data-operation-block="cart">${this.renderCartItems()}</div>
                ${this.renderPaymentSection()}
              </aside>
            </div>
          </div>
        </main>
      </div>
    `

    return `
      <div class="pos-screen print:hidden" ${this.locked ? "inert" : ""}>${screen}</div>
      ${this.locked ? this.renderLockOverlay(userName) : ""}
      ${this.receipt ? `<div id="pos-print-root" class="hidden print:block">${this.renderReceiptSlip(this.receipt)}</div>` : ""}
    `
  }

  renderLockOverlay(userName) {
    return `
      <div data-operation-block="lock" class="fixed inset-0 z-[60] bg-overlay backdrop-blur-md flex items-center justify-center p-4">
        <div class="w-full max-w-sm bg-card border border-line rounded-2xl shadow-xl p-6 flex flex-col gap-4 text-center">
          <div class="w-12 h-12 rounded-full bg-primary/10 text-primary flex items-center justify-center mx-auto">
            <span class="material-symbols-outlined text-[24px]">lock</span>
          </div>
          <div>
            <h2 class="text-lg font-bold text-foreground">${translate("Terminal locked")}</h2>
            <p class="text-[12px] text-muted-foreground mt-1">${this.escape(userName)}</p>
          </div>
          ${Helpers.form({
            action: Helpers.pos_unlock_company_operation_path(this.getCompanyId(), this.operationId),
            method: "POST",
            attributes: `data-action="submit->${this.identifier}#unlockTerminal" class="flex flex-col gap-2 text-left"`,
            html: `
              <label class="text-[11px] uppercase tracking-widest text-muted-foreground font-bold" for="pos-unlock-password">${translate("Enter your password to unlock")}</label>
              <input id="pos-unlock-password" name="password" type="password" autocomplete="current-password"
                class="w-full h-11 px-3 rounded-xl bg-muted border border-line text-foreground focus:ring-2 focus:ring-primary outline-none" />
              <button type="submit" ${this.lockSubmitting ? "disabled" : ""}
                class="w-full h-11 rounded-xl bg-primary text-primary-foreground font-bold hover:brightness-110 disabled:opacity-60 transition-colors">
                ${translate("Unlock")}
              </button>
            `
          })}
        </div>
      </div>
    `
  }

  renderHeader(branchName, operationName, userName, userRole, avatarUrl) {
    return `
      <header class="fixed top-0 w-full z-50 bg-card border-b border-line shadow-sm">
        <div class="h-16 w-full px-4 lg:px-6 flex items-center justify-between gap-3">
          <div class="flex items-center gap-3 min-w-0">
            <div class="flex items-center gap-2 shrink-0" title="${this.escape(operationName)}">
              <div class="w-9 h-9 rounded-lg bg-primary flex items-center justify-center text-primary-foreground font-bold shadow-sm">S</div>
              <span class="font-bold text-foreground tracking-tight truncate">${translate("Skycom POS")}</span>
            </div>
            <div class="h-6 w-px bg-line hidden md:block"></div>
            <div class="hidden sm:flex items-center gap-1.5 bg-muted px-3 py-1.5 rounded-lg text-muted-foreground text-[13px]">
              <span class="material-symbols-outlined text-primary text-[18px]">storefront</span>
              <span class="truncate">${this.escape(branchName || translate("Branch"))}</span>
            </div>
          </div>
          <div class="flex items-center gap-2 shrink-0">
            <nav class="hidden md:flex items-center gap-1 bg-muted p-1 rounded-xl">
              <span class="px-3 py-1 rounded-lg bg-primary text-primary-foreground text-[13px] font-semibold shadow-sm">${translate("Register")}</span>
              <a href="${Helpers.company_orders_path(this.getCompanyId())}" class="px-3 py-1 rounded-lg text-muted-foreground hover:text-foreground text-[13px] font-semibold transition-colors">${translate("Orders")}</a>
            </nav>
            <div class="hidden sm:flex items-center gap-2 bg-muted px-3 py-1.5 rounded-lg">
              <div class="w-7 h-7 rounded-full bg-primary/10 text-primary flex items-center justify-center shrink-0">
                ${avatarUrl
                  ? `<img src="${this.escape(avatarUrl)}" class="w-full h-full rounded-full object-cover" />`
                  : `<span class="material-symbols-outlined text-[16px]">person</span>`}
              </div>
              <div class="flex flex-col text-left leading-tight">
                <span class="text-[12px] font-semibold text-foreground">${this.escape(userName)}</span>
                <span class="text-[10px] text-muted-foreground">${this.escape(userRole)}</span>
              </div>
            </div>
            <button class="w-9 h-9 rounded-lg bg-muted hover:bg-line text-foreground flex items-center justify-center transition-colors overflow-hidden" ${Helpers.darkmodeTrigger()}></button>
            <button data-action="click->${this.identifier}#lockTerminal" ${this.lockSubmitting ? "disabled" : ""}
              class="w-9 h-9 rounded-lg bg-muted hover:bg-line text-foreground flex items-center justify-center transition-colors disabled:opacity-60"
              title="${translate("Lock Terminal")}" aria-label="${translate("Lock Terminal")}" type="button">
              <span class="material-symbols-outlined text-[18px]">lock</span>
            </button>
          </div>
        </div>
      </header>
    `
  }

  renderTabs() {
    return `
      <div class="flex items-center gap-2 overflow-x-auto pb-1 border-b border-line">
        <div class="flex items-center gap-1.5">
          ${this.tabs.map((tab, index) => this.renderTab(tab, index)).join("")}
          <button data-action="click->${this.identifier}#addTab"
            class="flex items-center gap-1 px-3 py-2 rounded-xl bg-muted hover:bg-line text-primary font-semibold text-[13px] whitespace-nowrap transition-colors shrink-0 cursor-pointer">
            <span class="material-symbols-outlined text-[16px]">add</span>
            ${translate("New Customer")}
          </button>
        </div>
      </div>
    `
  }

  renderTab(tab, index) {
    const active = index === this.activeTabIndex
    const count = tab.items.length
    const activeClasses = "bg-primary text-primary-foreground border-primary shadow-sm"
    const idleClasses = "bg-card text-muted-foreground hover:text-foreground hover:bg-muted border-line"

    return `
      <div class="flex items-center gap-2 px-3 py-2 rounded-xl whitespace-nowrap transition-colors border ${active ? activeClasses : idleClasses}">
        <button data-action="click->${this.identifier}#switchTab" data-${this.identifier}-index-param="${index}"
          class="flex items-center gap-1.5 font-semibold text-[13px] cursor-pointer">
          ${active ? `<span class="w-1.5 h-1.5 rounded-full bg-primary-foreground animate-pulse"></span>` : ""}
          <span>${this.escape(tab.name)}</span>
        </button>
        <span class="px-1.5 py-0.5 rounded-full text-[11px] font-bold ${active ? "bg-primary-foreground/20 text-primary-foreground" : "bg-muted text-muted-foreground"}">${count}</span>
        ${this.tabs.length > 1
          ? `<button data-action="click->${this.identifier}#closeTab" data-${this.identifier}-index-param="${index}"
               class="${active ? "text-primary-foreground/80 hover:text-primary-foreground" : "text-muted-foreground hover:text-danger"} cursor-pointer">
               <span class="material-symbols-outlined text-[14px]!">close</span>
             </button>`
          : ""}
      </div>
    `
  }

  renderSearch() {
    return `
      <div class="bg-card p-3 rounded-xl shadow-sm flex flex-col gap-1">
        <div class="relative flex-1">
          <span class="material-symbols-outlined absolute left-3.5 top-1/2 -translate-y-1/2 text-muted-foreground text-[20px]">search</span>
          <input id="barcode-input" type="text" value="${this.escape(this.searchQuery)}"
            data-action="input->${this.identifier}#updateSearch keydown.enter->${this.identifier}#handleBarcodeEnter"
            placeholder="${translate("Search products or scan barcode (F1)...")}"
            class="w-full h-11 pl-11 pr-12 rounded-xl bg-muted text-foreground placeholder:text-muted-foreground focus:ring-2 focus:ring-primary outline-none transition-all" />
          <span class="absolute right-3 top-1/2 -translate-y-1/2 bg-line text-muted-foreground text-[11px] px-1.5 py-0.5 rounded">F1</span>
        </div>
        <p id="pos-search-error" class="hidden text-[11px] text-danger px-1">${this.escape(this.searchError)}</p>
      </div>
    `
  }

  renderCategoryPills() {
    return `
      <div class="flex items-center gap-2 overflow-x-auto py-1">
        ${this.renderCategoryPill(null, translate("All"))}
        ${this.catalogCategories.map((name) => this.renderCategoryPill(name, name)).join("")}
      </div>
    `
  }

  renderCategoryPill(name, label) {
    const active = (name || null) === this.selectedCategoryName
    const param = name ? ` data-${this.identifier}-name-param="${this.escape(name)}"` : ""
    const activeClasses = "bg-primary text-primary-foreground shadow-sm"
    const idleClasses = "bg-card text-muted-foreground hover:bg-muted hover:text-foreground border border-line"

    return `
      <button data-action="click->${this.identifier}#selectCategory"${param}
        class="px-4 py-2 rounded-xl text-[13px] font-semibold whitespace-nowrap transition-colors cursor-pointer ${active ? activeClasses : idleClasses}">
        ${this.escape(label)}
      </button>
    `
  }

  productContainerClasses() {
    return this.viewMode === "list"
      ? "flex flex-col gap-2"
      : "grid grid-cols-2 sm:grid-cols-3 xl:grid-cols-4 gap-3"
  }

  renderProductsSection() {
    return `
      <div class="flex justify-between items-end mb-1">
        <h3 class="text-xs font-bold text-muted-foreground uppercase tracking-widest">${translate("Products Gallery")}</h3>
        <div class="flex gap-2">
          <button data-action="click->${this.identifier}#setViewMode" data-${this.identifier}-mode-param="grid"
            aria-pressed="${this.viewMode === "grid"}" title="${translate("Grid view")}"
            class="p-1.5 rounded border cursor-pointer transition-colors ${this.viewMode === "grid" ? "bg-primary text-primary-foreground border-primary" : "bg-card border-line hover:bg-muted text-muted-foreground"}">
            <span class="material-symbols-outlined text-sm">grid_view</span>
          </button>
          <button data-action="click->${this.identifier}#setViewMode" data-${this.identifier}-mode-param="list"
            aria-pressed="${this.viewMode === "list"}" title="${translate("List view")}"
            class="p-1.5 rounded border cursor-pointer transition-colors ${this.viewMode === "list" ? "bg-primary text-primary-foreground border-primary" : "bg-card border-line hover:bg-muted text-muted-foreground"}">
            <span class="material-symbols-outlined text-sm">view_list</span>
          </button>
        </div>
      </div>
      <div id="pos-product-grid" data-view-mode="${this.viewMode}" class="${this.productContainerClasses()}">
        ${this.renderProductCards()}
      </div>
      ${this.renderCap("product", this.catalogMeta.products_total, this.filteredProducts.length)}
    `
  }

  renderProductCards() {
    const products = this.filteredProducts
    if (products.length === 0) {
      return `<div class="col-span-full text-center text-muted-foreground py-10 text-sm">${translate("No products found")}</div>`
    }
    return products
      .map((product) => this.viewMode === "list" ? this.renderProductRow(product) : this.renderProductCard(product))
      .join("")
  }

  renderProductCard(product) {
    const cartQty = this.cartQuantityFor(product.id)
    const stockQuantity = Number(product.stock_quantity || 0)
    const lowStock = stockQuantity <= 5
    const priceSet = product.price_set !== false
    const priceLabel = priceSet
      ? Helpers.formatMoney(product.price_cents, this.currency)
      : translate("Price not set")

    return `
      <article data-action="click->${this.identifier}#addToCart"
        data-${this.identifier}-id-param="${this.escape(product.id)}"
        data-${this.identifier}-kind-param="product"
        data-${this.identifier}-name-param="${this.escape(product.name || "")}"
        data-${this.identifier}-price-cents-param="${product.price_cents ?? 0}"
        data-${this.identifier}-price-set-param="${priceSet}"
        data-${this.identifier}-stock-quantity-param="${stockQuantity}"
        class="group relative bg-card p-3 rounded-xl flex flex-col justify-between shadow-sm hover:shadow-md transition-all cursor-pointer border border-line hover:border-primary/40 active:scale-[0.99] ${priceSet ? "" : "opacity-70"}">
        <div class="relative w-full h-32 rounded-lg overflow-hidden bg-muted mb-2">
          ${product.image_url
            ? `<img src="${this.escape(product.image_url)}" class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" />`
            : `<div class="w-full h-full flex items-center justify-center">
                 <span class="material-symbols-outlined text-3xl text-primary">inventory_2</span>
               </div>`}
          ${cartQty > 0
            ? `<span class="absolute bottom-2 right-2 bg-success text-success-foreground text-[11px] font-semibold px-2 py-0.5 rounded-full shadow-sm flex items-center gap-1">
                 <span class="material-symbols-outlined text-[12px]">check</span>${cartQty} ${translate("in cart")}
               </span>`
            : ""}
        </div>
        <div class="flex flex-col gap-1">
          <h3 class="text-sm font-semibold text-foreground leading-snug line-clamp-1 group-hover:text-primary transition-colors">${this.escape(product.name || translate("Unnamed Product"))}</h3>
          <div class="flex items-center justify-between mt-1 gap-2">
            <span class="text-lg font-bold ${priceSet ? "text-primary" : "text-danger"}">${priceLabel}</span>
            <span class="text-[11px] ${lowStock ? "text-danger" : "text-muted-foreground"}">${this.stockLabel(product)}</span>
          </div>
        </div>
      </article>
    `
  }

  renderProductRow(product) {
    const cartQty = this.cartQuantityFor(product.id)
    const stockQuantity = Number(product.stock_quantity || 0)
    const priceSet = product.price_set !== false
    const priceLabel = priceSet
      ? Helpers.formatMoney(product.price_cents, this.currency)
      : translate("Price not set")

    return `
      <article data-action="click->${this.identifier}#addToCart"
        data-${this.identifier}-id-param="${this.escape(product.id)}"
        data-${this.identifier}-kind-param="product"
        data-${this.identifier}-name-param="${this.escape(product.name || "")}"
        data-${this.identifier}-price-cents-param="${product.price_cents ?? 0}"
        data-${this.identifier}-price-set-param="${priceSet}"
        data-${this.identifier}-stock-quantity-param="${stockQuantity}"
        class="bg-card border border-line rounded-xl p-2.5 flex items-center gap-3 cursor-pointer hover:border-primary/40 transition-colors ${priceSet ? "" : "opacity-70"}">
        <div class="w-12 h-12 rounded-lg bg-muted overflow-hidden shrink-0 flex items-center justify-center">
          ${product.image_url
            ? `<img src="${this.escape(product.image_url)}" class="w-full h-full object-cover" />`
            : `<span class="material-symbols-outlined text-primary">inventory_2</span>`}
        </div>
        <div class="flex-1 min-w-0">
          <h3 class="text-[13px] font-semibold text-foreground truncate">${this.escape(product.name || translate("Unnamed Product"))}</h3>
          <p class="text-[11px] text-muted-foreground">${this.stockLabel(product)}</p>
        </div>
        <span class="text-sm font-bold ${priceSet ? "text-primary" : "text-danger"}">${priceLabel}</span>
        ${cartQty > 0 ? `<span class="bg-success/10 text-success text-[11px] font-bold px-2 py-0.5 rounded-full">${cartQty}</span>` : ""}
      </article>
    `
  }

  stockLabel(product) {
    const quantity = Number(product.stock_quantity || 0)
    if (!product.stock_warehouse_name) return translate("Not stocked at this branch")
    return `${quantity} ${translate("in stock")} · ${this.escape(product.stock_warehouse_name)}`
  }

  renderCap(kind, total, shown) {
    if (!total || total <= shown) return `<div id="pos-${kind}-cap"></div>`
    return `<p id="pos-${kind}-cap" class="text-[11px] text-muted-foreground mt-2">${translate("Showing")} ${shown} ${translate("of")} ${total}</p>`
  }

  renderServicesList() {
    const services = this.filteredServices
    const cap = this.renderCap("service", this.catalogMeta.services_total, services.length)
    if (services.length === 0) {
      return `
        <div class="mt-4">
          <h3 class="text-xs font-bold text-muted-foreground uppercase tracking-widest mb-3">${translate("Retail Services")}</h3>
          <p class="text-sm text-muted-foreground py-3">${translate("No services found")}</p>
          ${cap}
        </div>
      `
    }

    const serviceIconMap = {
      delivery: "local_shipping",
      shipping: "local_shipping",
      assembly: "build",
      install: "build",
      warranty: "verified",
      protect: "verified",
      gift: "id_card",
      wrap: "id_card",
      package: "id_card"
    }

    return `
      <div class="mt-4">
        <h3 class="text-xs font-bold text-muted-foreground uppercase tracking-widest mb-3">${translate("Retail Services")}</h3>
        <div class="flex flex-col gap-2">
          ${services.map((service) => {
            const serviceName = (service.name || "").toLowerCase()
            const icon = Object.entries(serviceIconMap).find(([key]) => serviceName.includes(key))?.[1] || "spa"
            const priceSet = service.price_set !== false
            const priceLabel = priceSet
              ? Helpers.formatMoney(service.price_cents, this.currency)
              : translate("Price not set")
            return `
              <div data-action="click->${this.identifier}#addToCart"
                data-${this.identifier}-id-param="${this.escape(service.id)}"
                data-${this.identifier}-kind-param="service"
                data-${this.identifier}-name-param="${this.escape(service.name || "")}"
                data-${this.identifier}-price-cents-param="${service.price_cents ?? 0}"
                data-${this.identifier}-price-set-param="${priceSet}"
                class="bg-muted border border-line p-3 rounded-xl flex items-center gap-3 hover:border-primary/40 transition-colors cursor-pointer group ${priceSet ? "" : "opacity-70"}">
                <div class="w-10 h-10 rounded-lg bg-primary/10 flex items-center justify-center text-primary shrink-0">
                  <span class="material-symbols-outlined text-[20px]">${icon}</span>
                </div>
                <div class="min-w-0 flex-1">
                  <h4 class="text-[13px] font-semibold text-foreground truncate">${this.escape(service.name || translate("Service"))}</h4>
                  <p class="text-[11px] text-muted-foreground">${priceLabel}</p>
                </div>
              </div>
            `
          }).join("")}
        </div>
        ${cap}
      </div>
    `
  }

  renderOrderHeader() {
    const count = this.activeTab?.items.length || 0
    const tabName = this.activeTab?.name || translate("Walk-in customer")

    return `
      <div class="flex items-start justify-between pb-2 border-b border-line gap-2">
        <div class="flex flex-col gap-0.5 min-w-0">
          <div class="flex items-center gap-2">
            <span class="text-lg font-bold text-foreground">${translate("Current Order")}</span>
            <span class="bg-muted text-muted-foreground text-[11px] font-semibold px-2 py-0.5 rounded-full">${count} ${count === 1 ? translate("item") : translate("items")}</span>
          </div>
          <div class="flex items-center gap-1.5 text-success text-[11px] font-semibold">
            <span class="w-1.5 h-1.5 rounded-full bg-success"></span>
            <span class="truncate">${translate("Serving:")} ${this.escape(tabName)} (${translate("Active Customer")})</span>
          </div>
        </div>
        <div class="flex items-center gap-1 shrink-0">
          <button data-action="click->${this.identifier}#clearCart"
            class="text-muted-foreground hover:text-danger p-1 rounded hover:bg-danger/10 transition-colors cursor-pointer"
            title="${translate("Clear Cart")}">
            <span class="material-symbols-outlined text-[18px]">delete</span>
          </button>
        </div>
      </div>
    `
  }

  renderCustomerCard() {
    const tab = this.activeTab
    const customer = tab?.customer
    const membership = customer?.membership
    const displayName = customer?.name || translate("Walk-in customer")
    const initials = this.initialsFor(customer?.name || tab?.name || "Walk-in")

    return `
      <div data-operation-block="customer" class="bg-muted rounded-xl px-3 py-2 flex flex-col gap-2">
        <div class="flex items-center gap-2.5">
          <div class="w-8 h-8 rounded-full bg-primary flex items-center justify-center text-primary-foreground text-[11px] font-bold shrink-0">
            ${this.escape(initials)}
          </div>
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-1.5 min-w-0">
              <span class="text-[13px] font-semibold text-foreground truncate">${this.escape(displayName)}</span>
              ${membership
                ? `<span class="bg-primary/10 text-primary text-[10px] font-bold px-1.5 py-0.5 rounded shrink-0">${this.escape(membership.name || membership.code || "")}</span>`
                : ""}
            </div>
            <span class="text-[11px] text-muted-foreground block truncate">
              ${customer ? `${translate("Synced with")} ${this.escape(tab.name)}` : translate("Search by customer ID, phone, or name")}
            </span>
          </div>
          ${customer
            ? `<div class="flex items-center gap-2 shrink-0">
                 <button data-action="click->${this.identifier}#focusCustomerLookup"
                   class="text-[11px] font-semibold text-primary hover:text-primary/80 cursor-pointer">${translate("Change")}</button>
                 <button data-action="click->${this.identifier}#clearCustomer"
                   class="text-[11px] font-semibold text-danger hover:text-danger/80 cursor-pointer">${translate("Clear")}</button>
               </div>`
            : ""}
        </div>
        <div class="flex items-center gap-1.5">
          <input id="pos-customer-lookup" type="text"
            data-action="keydown.enter->${this.identifier}#searchCustomer"
            placeholder="${translate("Customer ID / phone / name...")}"
            class="flex-1 h-8 px-2.5 rounded-lg bg-card border border-line text-[12px] text-foreground placeholder:text-muted-foreground focus:ring-2 focus:ring-primary outline-none" />
          <button data-action="click->${this.identifier}#searchCustomer"
            class="h-8 px-3 rounded-lg bg-card border border-line text-[12px] font-semibold text-primary hover:bg-muted transition-colors shrink-0 cursor-pointer">
            ${translate("Find")}
          </button>
        </div>
      </div>
    `
  }

  renderCartItems() {
    if (!this.activeTab || this.activeTab.items.length === 0) {
      return `<div class="text-center text-muted-foreground py-8 text-sm">${translate("Cart is empty")}</div>`
    }

    return this.activeTab.items.map((item) => {
      const lineTotal = Helpers.formatMoney(Number(item.priceCents || 0) * item.qty, this.currency)
      const atCap = item.kind === "product" && item.qty >= Number(item.stockQuantity || 0)

      if (this.orderId) {
        return `
          <div class="p-2 rounded-xl bg-muted border border-line flex items-center justify-between gap-2">
            <div class="flex flex-col flex-1 min-w-0">
              <span class="text-[13px] font-semibold text-foreground truncate">${this.escape(item.name)}</span>
              <span class="text-[11px] text-muted-foreground">${translate("Qty:")} ${item.qty}</span>
            </div>
            <span class="text-[13px] font-bold text-foreground">${lineTotal}</span>
          </div>
        `
      }

      return `
        <div class="p-2 rounded-xl bg-muted/50 hover:bg-muted transition-colors flex items-center justify-between gap-2 group">
          <div class="flex flex-col flex-1 min-w-0">
            <span class="text-[13px] font-semibold text-foreground truncate">${this.escape(item.name)}</span>
            <span class="text-[11px] text-muted-foreground">${Helpers.formatMoney(item.priceCents, this.currency)} ${translate("/ ea")}</span>
            ${atCap ? `<span class="text-[10px] text-warning">${translate("Stock limit")}: ${item.stockQuantity}</span>` : ""}
          </div>
          <div class="flex items-center bg-card rounded-lg p-0.5 shadow-sm border border-line shrink-0">
            <button data-action="click->${this.identifier}#updateQty" data-${this.identifier}-id-param="${this.escape(item.id)}" data-${this.identifier}-kind-param="${item.kind}" data-${this.identifier}-delta-param="-1"
              class="w-6 h-6 flex items-center justify-center text-muted-foreground hover:text-foreground rounded font-bold cursor-pointer">
              <span class="material-symbols-outlined text-[14px]">remove</span>
            </button>
            <span class="w-6 text-center text-[12px] font-semibold text-foreground">${item.qty}</span>
            <button data-action="click->${this.identifier}#updateQty" data-${this.identifier}-id-param="${this.escape(item.id)}" data-${this.identifier}-kind-param="${item.kind}" data-${this.identifier}-delta-param="1"
              ${atCap ? "disabled" : ""}
              class="w-6 h-6 flex items-center justify-center text-muted-foreground hover:text-foreground rounded font-bold cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed">
              <span class="material-symbols-outlined text-[14px]">add</span>
            </button>
          </div>
          <span class="text-[13px] font-bold text-foreground w-20 text-right shrink-0">${lineTotal}</span>
          <button data-action="click->${this.identifier}#removeFromCart" data-${this.identifier}-id-param="${this.escape(item.id)}" data-${this.identifier}-kind-param="${item.kind}"
            class="text-muted-foreground hover:text-danger p-1 shrink-0 cursor-pointer">
            <span class="material-symbols-outlined text-[16px]">close</span>
          </button>
        </div>
      `
    }).join("")
  }

  renderPaymentSection() {
    const subtotalCents = this.getSubtotalCents()
    const discountCents = this.getDiscountCents()
    const taxCents = this.getTaxCents()
    const totalCents = this.getTotalCents()
    const money = (cents) => Helpers.formatMoney(cents, this.currency)

    if (this.receipt) {
      return `
        <div data-operation-block="receipt" class="pt-2 border-t border-line">
          <div class="space-y-3">
            <div class="flex items-center justify-between">
              <h3 class="text-sm font-black uppercase tracking-widest text-muted-foreground">${translate("Receipt")}</h3>
              ${Helpers.statusBadge(this.receipt.payment_status)}
            </div>
            ${this.renderReceiptSlip(this.receipt)}
            <div class="grid grid-cols-2 gap-2">
              <button data-action="click->${this.identifier}#printReceipt"
                class="w-full bg-card border-2 border-line text-foreground py-2.5 rounded-xl text-sm font-black hover:bg-muted transition-colors flex items-center justify-center gap-1.5 cursor-pointer">
                <span class="material-symbols-outlined text-[18px]">print</span>
                ${translate("Print Receipt")}
              </button>
              <button data-action="click->${this.identifier}#newSale"
                class="w-full bg-primary text-primary-foreground py-2.5 rounded-xl text-sm font-black hover:brightness-110 transition-colors flex items-center justify-center gap-1.5 cursor-pointer">
                <span class="material-symbols-outlined text-[18px]">add_shopping_cart</span>
                ${translate("New Sale")}
              </button>
            </div>
          </div>
        </div>
      `
    }

    if (this.awaitingToken) {
      return `
        <div class="pt-2 border-t border-line">
          <div class="space-y-3 text-center">
            <h3 class="text-sm font-bold text-foreground">${translate("Scan to Pay")}</h3>
            <p class="text-[11px] text-muted-foreground">${translate("Scan the QR code with your banking app to complete the payment.")}</p>
            <p class="text-2xl font-black text-primary">${money(totalCents)}</p>
            <div class="flex justify-center">
              <div id="cashier-qr-container" data-transaction-token="${this.escape(this.awaitingToken)}" class="w-56 h-56 bg-card rounded-xl p-3 border border-line flex items-center justify-center"></div>
            </div>
            <div class="flex items-center justify-center gap-2 text-sm text-warning">
              <span class="material-symbols-outlined text-[18px]! animate-pulse">hourglass_top</span>
              ${translate("Waiting for payment confirmation...")}
            </div>
            <button data-action="click->${this.identifier}#cancelAwaitingPayment"
              class="w-full bg-card border-2 border-line text-foreground py-2.5 rounded-xl font-black hover:bg-muted transition-all cursor-pointer">
              ${translate("Cancel")}
            </button>
          </div>
        </div>
      `
    }

    const icons = { cash: "payments", qr: "qr_code_scanner" }
    const methodButtons = this.paymentMethods.map((method) => `
      <button data-action="click->${this.identifier}#setPaymentMethod"
        data-${this.identifier}-method-id-param="${this.escape(method.id)}"
        class="py-2.5 rounded-xl flex flex-col items-center gap-1 border-2 transition-colors cursor-pointer ${String(this.selectedMethodId) === String(method.id) ? "bg-muted text-primary border-primary" : "bg-muted text-foreground border-transparent hover:border-line"}">
        <span class="material-symbols-outlined text-[20px]">${icons[method.payment_mode] || "credit_card"}</span>
        <span class="text-[12px] font-semibold">${this.escape(method.name)}</span>
      </button>
    `).join("")

    const isCashMode = this.getSelectedMethod()?.payment_mode === "cash"
    const changeDue = this.getChangeDueCents()
    const cashValue = this.cashReceived ? Helpers.minorToMajor(this.cashReceived, this.currency) : ""
    const cashPanel = isCashMode ? `
      <div class="bg-muted p-3 rounded-xl flex flex-col gap-2">
        <div>
          <label class="block text-[10px] uppercase tracking-widest text-muted-foreground font-bold mb-1">${translate("Received")}</label>
          <input type="number" value="${cashValue}" data-action="input->${this.identifier}#updateCashReceived"
            class="w-full bg-card border border-line rounded-lg px-3 py-2 text-lg font-bold focus:ring-2 focus:ring-primary outline-none" />
        </div>
        <div class="grid grid-cols-3 gap-1.5">
          ${this.quickCashAmounts.map((amount) => `
            <button data-action="click->${this.identifier}#setCashReceived" data-${this.identifier}-amount-param="${amount}"
              class="py-1.5 rounded-lg bg-card border border-line hover:bg-muted text-[11px] font-semibold text-foreground transition-colors cursor-pointer">
              ${money(amount)}
            </button>
          `).join("")}
        </div>
        <div class="flex items-center justify-between bg-success/10 border border-success/20 rounded-lg px-3 py-2">
          <span class="text-[11px] font-bold text-success">${translate("Change Due")}</span>
          <span id="cashier-change-due" class="text-lg font-black ${changeDue >= 0 ? "text-success" : "text-danger"}">${money(changeDue)}</span>
        </div>
      </div>
    ` : ""

    const underpaid = isCashMode && changeDue < 0
    return `
      <div data-operation-block="payment" class="flex flex-col gap-3 pt-2 border-t border-line">
        <div class="bg-muted p-3 rounded-xl flex flex-col gap-1.5">
          <div class="flex justify-between items-center text-[12px] text-muted-foreground">
            <span>${translate("Subtotal")}</span>
            <span class="text-[13px] font-semibold text-foreground">${money(subtotalCents)}</span>
          </div>
          ${discountCents > 0 ? `
            <div class="flex justify-between items-center text-[12px] text-success">
              <span>${translate("Discount")}${this.appliedDiscount?.code ? ` (${this.escape(this.appliedDiscount.code)})` : ""}</span>
              <span class="text-[13px] font-semibold">-${money(discountCents)}</span>
            </div>
          ` : ""}
          ${this.tax.rate_bp > 0 ? `
            <div class="flex justify-between items-center text-[12px] text-muted-foreground">
              <span>${this.escape(this.tax.name)} (${this.taxRateLabel()}%)</span>
              <span class="text-[13px] font-semibold text-foreground">${money(taxCents)}</span>
            </div>
          ` : ""}
          <div class="h-px bg-line my-1"></div>
          <div class="flex justify-between items-center">
            <span class="text-[13px] font-bold text-foreground">${translate("Total Amount")}</span>
            <span class="text-2xl font-extrabold text-primary">${money(totalCents)}</span>
          </div>
        </div>

        ${this.renderDiscountBlock()}

        ${this.paymentMethods.length === 0 ? `<p class="text-[11px] text-danger">${translate("No payment method is available for this branch")}</p>` : ""}
        <div class="grid grid-cols-3 gap-2">${methodButtons}</div>

        ${cashPanel}

        ${this.orderId ? `
          <div class="grid grid-cols-2 gap-2">
            <button data-action="click->${this.identifier}#cancelOrder"
              class="w-full bg-card border-2 border-line text-foreground py-3 rounded-xl text-sm font-black hover:bg-muted active:scale-[0.98] transition-all flex items-center justify-center cursor-pointer">
              ${translate("Cancel")}
            </button>
            <button data-action="click->${this.identifier}#pay" ${(this.paySubmitting || underpaid || this.paymentMethods.length === 0) ? "disabled" : ""}
              title="${underpaid ? translate("Cash received is less than the total") : ""}"
              class="w-full bg-success text-success-foreground py-3 rounded-xl text-sm font-black shadow-lg shadow-success/20 hover:brightness-110 active:scale-[0.98] transition-all flex items-center justify-center gap-2 cursor-pointer disabled:opacity-60 disabled:cursor-not-allowed">
              <span class="material-symbols-outlined text-[18px]">point_of_sale</span>
              ${translate("COMPLETE PAYMENT")}
            </button>
          </div>
        ` : `
          <button data-action="click->${this.identifier}#initiateOrder" ${this.orderSubmitting ? "disabled" : ""}
            class="w-full bg-primary text-primary-foreground py-3 rounded-xl text-base font-black shadow-lg shadow-primary/20 hover:brightness-110 active:scale-[0.98] transition-all flex items-center justify-center gap-2 cursor-pointer disabled:opacity-60">
            <span class="material-symbols-outlined text-[20px]">shopping_cart</span>
            ${translate("ORDER")}
          </button>
        `}
      </div>
    `
  }

  renderDiscountBlock() {
    if (!this.orderId) return ""
    if (this.appliedDiscount) {
      return `
        <div data-operation-block="discount" class="bg-success/10 border border-success/20 rounded-xl px-3 py-2 flex items-center justify-between gap-2">
          <div class="min-w-0">
            <p class="text-[11px] font-bold text-success truncate">${this.escape(this.appliedDiscount.code)}</p>
            <p class="text-[10px] text-muted-foreground">${translate("Discount")}: -${Helpers.formatMoney(this.appliedDiscount.amountCents, this.currency)}</p>
          </div>
          <button data-action="click->${this.identifier}#removeDiscount" ${this.discountSubmitting ? "disabled" : ""}
            class="text-[11px] font-semibold text-danger hover:text-danger/80 disabled:opacity-50 shrink-0">
            ${translate("Remove")}
          </button>
        </div>
      `
    }

    return Helpers.form({
      action: Helpers.order_processing_v1_apply_discount_path(this.getCompanyId()),
      method: "POST",
      attributes: `data-action="submit->${this.identifier}#applyDiscount" class="flex items-center gap-2"`,
      html: `
        <input id="pos-discount-code" name="discount_code" type="text" autocomplete="off"
          placeholder="${translate("Discount code")}"
          class="flex-1 h-9 px-3 rounded-lg bg-muted border border-line text-[12px] text-foreground placeholder:text-muted-foreground focus:ring-2 focus:ring-primary outline-none" />
        <button type="submit" ${this.discountSubmitting ? "disabled" : ""}
          class="h-9 px-3 rounded-lg bg-card border border-line text-[12px] font-semibold text-primary hover:bg-muted disabled:opacity-50 transition-colors">
          ${translate("Apply")}
        </button>
      `
    })
  }

  taxRateLabel() {
    const rate = Number(this.tax.rate_percent || 0)
    return Number.isInteger(rate) ? String(rate) : rate.toFixed(2).replace(/0+$/, "").replace(/\.$/, "")
  }

  renderReceiptSlip(receipt) {
    const money = (cents) => Helpers.formatMoney(cents, receipt.currency || this.currency)
    return `
      <div class="w-full max-w-[80mm] mx-auto bg-card border border-line rounded-xl p-4 text-foreground font-mono">
        <div class="text-center">
          <h3 class="text-sm font-black uppercase tracking-widest">${this.escape(receipt.branch_name || this.appointment?.branch?.name || translate("Receipt"))}</h3>
          <p class="text-[10px] text-muted-foreground mt-1">${receipt.issued_at ? Helpers.locationTime(receipt.issued_at, Helpers.TIMESTAMP_FORMAT, this.appointment?.location) : ""}</p>
          <p class="text-[10px] text-muted-foreground">${translate("Cashier")}: ${this.escape(receipt.cashier_name || "")}</p>
          <p class="text-[10px] text-muted-foreground">${this.escape(receipt.invoice_code || "")}</p>
        </div>
        <div class="border-t border-dashed border-line mt-3 pt-3 space-y-1">
          ${(receipt.items || []).map((item) => `
            <div class="flex justify-between gap-2 text-[11px]">
              <span class="truncate">${item.quantity} × ${this.escape(item.name)}</span>
              <span class="font-bold shrink-0">${money(item.total_cents)}</span>
            </div>
          `).join("")}
        </div>
        <div class="border-t border-dashed border-line mt-3 pt-3 space-y-1">
          <div class="flex justify-between text-[11px] text-muted-foreground"><span>${translate("Subtotal")}</span><span>${money(receipt.subtotal_cents)}</span></div>
          ${receipt.discount_cents > 0 ? `<div class="flex justify-between text-[11px] text-success"><span>${translate("Discount")}${receipt.discount_code ? ` (${this.escape(receipt.discount_code)})` : ""}</span><span>-${money(receipt.discount_cents)}</span></div>` : ""}
          ${receipt.tax_rate_bp > 0 ? `<div class="flex justify-between text-[11px] text-muted-foreground"><span>${this.escape(receipt.tax_name || "Tax")} (${this.taxRateFor(receipt.tax_rate_bp)}%)</span><span>${money(receipt.tax_cents)}</span></div>` : ""}
          <div class="flex justify-between text-[13px] font-black pt-1"><span>${translate("Total Amount")}</span><span>${money(receipt.total_cents)}</span></div>
          ${receipt.payment_method_name ? `<div class="flex justify-between text-[11px] text-muted-foreground"><span>${translate("Payment Method")}</span><span>${this.escape(receipt.payment_method_name)}</span></div>` : ""}
          ${receipt.cash_received_cents != null ? `<div class="flex justify-between text-[11px] text-muted-foreground"><span>${translate("Received")}</span><span>${money(receipt.cash_received_cents)}</span></div>` : ""}
          ${receipt.change_cents != null ? `<div class="flex justify-between text-[11px] text-muted-foreground"><span>${translate("Change Due")}</span><span>${money(receipt.change_cents)}</span></div>` : ""}
        </div>
      </div>
    `
  }

  taxRateFor(rateBp) {
    const rate = Number(rateBp || 0) / 100
    return Number.isInteger(rate) ? String(rate) : rate.toFixed(2).replace(/0+$/, "").replace(/\.$/, "")
  }

  printReceipt() {
    if (!this.receipt) return
    window.print()
  }

  escape(value) {
    return String(value ?? "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;")
  }

  getCompanyId() {
    return this.element.dataset.companyId || window.location.pathname.split("/")[2]
  }
}
