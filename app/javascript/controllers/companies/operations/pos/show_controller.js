import { Controller } from "@hotwired/stimulus"

export default class Companies_Operations_Pos_ShowController extends Controller {
  // POS — Cart (tabs[].items[] in memory) → ORDER → pay → receipt.
  // Click card → addToCart mutates local cart only; ORDER flushes to Order+OrderProductAppointment; pay reads DB snapshots.
  // Mounted by the web layout and by Mobile::Companies::Operations::PosController (Shell-First;
  // the mobile shell supplies data-company-id / data-operation-id / data-user-*).
  // Depends on BE: Companies::Operations::PosController#show (hydrate products/services/payment_methods),
  //               Companies::OrderProcessing::V1Controller#checkout|pay|pay_cancel,
  //               Companies::OrdersController#receipt,
  //               Companies::Operations::PosController#customer_lookup (customer + membership),
  //               Webhooks::Payments::MockQrGatewayController (QR webhook → WS pos_payment_completed)
  // Endpoints: Helpers.pos_company_operation_path, pos_customer_lookup_company_operation_path,
  //            order_processing_v1_*_path, receipt_company_order_path
  // Docs: docs/ORDER_PROCESSING_V1.md
  /** @type {any | null} */ operation = null
  /** @type {string | null} */ operationId = null
  /** @type {any | null} */ appointment = null
  /** @type {any[]} */ products = []
  /** @type {any[]} */ services = []
  /** @type {{ id: number, name: string, customer: any | null, items: { id: any, name: string, price: number, qty: number, stockId?: string }[] }[]} */ tabs = []
  /** @type {number} */ activeTabIndex = 0
  /** @type {number} */ tabCounter = 0
  /** @type {number} */ cashReceived = 0
  /** @type {string | null} */ orderId = null
  /** @type {number} */ orderTotal = 0
  /** @type {any[]} */ paymentMethods = []
  /** @type {string | null} */ selectedMethodId = null
  /** @type {string | null} */ awaitingToken = null
  /** @type {any | null} */ receipt = null
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

      this.addTab()
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
    this.tabs.push({ id: this.tabCounter, name: walkInName, customer: null, items: [] })
    this.activeTabIndex = this.tabs.length - 1
    this.renderContent()
    this.focusBarcode()
  }

  switchTab(event) {
    this.activeTabIndex = event.params.index
    this.renderContent()
    this.focusBarcode()
  }

  closeTab(event) {
    const index = event.params.index
    if (this.tabs.length <= 1) return
    this.tabs.splice(index, 1)
    if (this.activeTabIndex >= this.tabs.length) {
      this.activeTabIndex = this.tabs.length - 1
    }
    this.renderContent()
  }

  get activeTab() {
    return this.tabs[this.activeTabIndex]
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
    const query = this.searchQuery.trim().toLowerCase()
    return this.products.filter((product) => {
      if (this.selectedCategoryName && this.categoryNameFor(product) !== this.selectedCategoryName) return false
      if (!query) return true
      return `${product.name || ""} ${product.code || ""}`.toLowerCase().includes(query)
    })
  }

  get filteredServices() {
    const query = this.searchQuery.trim().toLowerCase()
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

  updateSearch(event) {
    this.searchQuery = event.target.value
    this.refreshCatalog()
  }

  handleBarcodeEnter(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }
    const input = document.getElementById("barcode-input")
    const query = (input?.value || this.searchQuery || "").trim().toLowerCase()
    if (!query) return

    const match = this.products.find((product) => String(product.code || "").toLowerCase() === query)
    if (!match) return

    this.searchQuery = ""
    this.addToCart({
      params: { id: match.id, name: match.name, price: match.price, stockId: match.stock_id }
    })
  }

  refreshCatalog() {
    const grid = document.getElementById("pos-product-grid")
    if (grid) grid.innerHTML = this.renderProductCards()

    const services = document.getElementById("pos-services-section")
    if (services) services.innerHTML = this.renderServicesList()
  }

  // --- Cart ------------------------------------------------------------------------

  // Card click → local cart (no API). Locked when orderId exists. Dupe → qty++.
  addToCart(event) {
    if (this.orderId) return
    const { id, name, price, stockId } = event.params
    if (!this.activeTab) return
    const existing = this.activeTab.items.find((item) => String(item.id) === String(id))
    if (existing) {
      existing.qty++
    } else {
      this.activeTab.items.push({ id, name, price, qty: 1, stockId })
    }
    this.renderContent()
    this.focusBarcode()
  }

  removeFromCart(event) {
    if (this.orderId) return
    const { id } = event.params
    if (!this.activeTab) return
    this.activeTab.items = this.activeTab.items.filter((item) => String(item.id) !== String(id))
    this.renderContent()
  }

  updateQty(event) {
    if (this.orderId) return
    const { id, delta } = event.params
    if (!this.activeTab) return
    const item = this.activeTab.items.find((candidate) => String(candidate.id) === String(id))
    if (item) {
      item.qty = Math.max(0, item.qty + delta)
      if (item.qty === 0) {
        this.activeTab.items = this.activeTab.items.filter((candidate) => String(candidate.id) !== String(id))
      }
    }
    this.renderContent()
  }

  clearCart() {
    if (this.orderId || !this.activeTab) return
    this.activeTab.items = []
    this.renderContent()
  }

  cartQuantityFor(id) {
    if (!this.activeTab) return 0
    return this.activeTab.items
      .filter((item) => String(item.id) === String(id))
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

  updateCashReceived(event) {
    this.cashReceived = parseFloat(event.target.value) || 0
    this.refreshChangeDue()
  }

  setCashReceived(event) {
    this.cashReceived = Number(event.params.amount) || 0
    this.renderContent()
  }

  get quickCashAmounts() {
    const total = this.getTotal()
    if (!total) return []

    const roundUp = (step) => Math.ceil(total / step) * step
    return [...new Set([roundUp(5), roundUp(50), roundUp(100)])].filter((amount) => amount >= total)
  }

  refreshChangeDue() {
    const el = document.getElementById("cashier-change-due")
    if (!el) return
    const changeDue = this.getChangeDue()
    el.textContent = (changeDue >= 0 ? "$" : "-$") + Math.abs(changeDue).toFixed(2)
    el.className = `text-lg font-black ${changeDue >= 0 ? "text-success" : "text-danger"}`
  }

  async initiateOrder() {
    const tab = this.activeTab
    if (!tab || tab.items.length === 0) {
      toast({ type: "warning", message: translate("Cart is empty") })
      return
    }

    const companyId = this.getCompanyId()
    const items = tab.items
      .filter((item) => item.stockId)
      .map((item) => ({ stock_id: item.stockId, product_id: item.id, quantity: item.qty, unit_price: item.price }))

    if (items.length === 0) {
      toast({ type: "warning", message: translate("No stock-tracked items in cart") })
      return
    }

    try {
      const body = { branch_id: this.appointment.branch.id, items }
      if (tab.customer?.id) body.customer_id = tab.customer.id

      const res = await fetchJson(Helpers.order_processing_v1_checkout_path(companyId), {
        method: "POST",
        body
      })
      this.orderId = res.order_id
      this.orderTotal = res.total_price || 0

      if (this.isQrMode) {
        await this.pay()
        return
      }

      this.renderContent()
      toast({ type: "success", message: res.message || translate("Order created") })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message || translate("Failed to create order") })
    }
  }

  async pay() {
    try {
      const res = await fetchJson(Helpers.order_processing_v1_pay_path(this.getCompanyId()), {
        method: "POST",
        body: { order_id: this.orderId, payment_method_appointment_id: this.selectedMethodId }
      })

      if (res.status === "pending") {
        this.awaitingToken = res.transaction_token
        this.subscribePaymentCompleted()
        this.renderContent()
        this.renderQrCodeInto(res.qr_string)
        return
      }

      toast({ type: "success", message: res.message || translate("Payment completed") })
      await this.showReceipt()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message || translate("Payment failed") })
      if (this.isQrMode && !this.awaitingToken) this.orderId = null
      this.renderContent()
    }
  }

  async showReceipt() {
    try {
      const res = await fetchJson(Helpers.receipt_company_order_path(this.getCompanyId(), this.orderId))
      this.receipt = res.receipt || null
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to load receipt") })
    }
    this.activeTab.items = []
    this.cashReceived = 0
    this.awaitingToken = null
    this.renderContent()
  }

  newSale() {
    this.receipt = null
    this.orderId = null
    this.orderTotal = 0
    this.renderContent()
    this.focusBarcode()
  }

  subscribePaymentCompleted() {
    const ws = window.WEBSOCKET
    if (!ws?.channelName || !ws?.subscribe) return
    const channel = ws.channelName("company", this.getCompanyId())
    ws.subscribe(channel, "pos_payment_completed", (data) => {
      if (data?.payload?.transaction_token !== this.awaitingToken) return
      toast({ type: "success", message: translate("Payment completed") })
      this.showReceipt()
    })
  }

  renderQrCodeInto(qrString) {
    setTimeout(() => {
      const container = document.getElementById("cashier-qr-container")
      if (container && window.renderQrCode) window.renderQrCode(container, qrString)
    }, 50)
  }

  async cancelAwaitingPayment() {
    try {
      await fetchJson(Helpers.order_processing_v1_pay_cancel_path(this.getCompanyId()), {
        method: "POST",
        body: { transaction_token: this.awaitingToken }
      })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Cancellation failed") })
    }
    this.awaitingToken = null
    this.cancelOrder()
  }

  cancelOrder() {
    this.orderId = null
    this.orderTotal = 0
    this.renderContent()
  }

  getSubtotal() {
    if (!this.activeTab) return 0
    return this.activeTab.items.reduce((sum, item) => sum + item.price * item.qty, 0)
  }

  getTax() {
    return this.getSubtotal() * 0.10
  }

  getTotal() {
    return this.getSubtotal() + this.getTax()
  }

  getChangeDue() {
    return this.cashReceived - this.getTotal()
  }

  openDrawer() {
    toast({ type: "info", message: translate("Cash drawer is not connected.") })
  }

  focusBarcode() {
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

    return `
      <div class="bg-background text-foreground min-h-screen flex flex-col">
        ${this.renderHeader(branchName, operationName, userName, userRole, avatarUrl)}
        <main class="flex-1 pt-16">
          <div class="w-full px-4 lg:px-6 py-3">
            <div class="grid grid-cols-1 lg:grid-cols-12 gap-3 items-start">
              <section class="lg:col-span-7 xl:col-span-8 flex flex-col gap-3 min-w-0">
                ${this.renderTabs()}
                ${this.renderSearch()}
                ${this.renderCategoryPills()}
                ${this.renderProductsSection()}
                <div id="pos-services-section">${this.renderServicesList()}</div>
              </section>
              <aside class="lg:col-span-5 xl:col-span-4 bg-card rounded-2xl shadow-md p-3 flex flex-col gap-3 lg:sticky lg:top-20">
                ${this.renderOrderHeader()}
                ${this.renderCustomerCard()}
                <div class="flex flex-col gap-1.5 max-h-[260px] overflow-y-auto pr-1">${this.renderCartItems()}</div>
                ${this.renderPaymentSection()}
              </aside>
            </div>
          </div>
        </main>
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
            <button class="w-9 h-9 rounded-lg bg-muted hover:bg-line text-foreground flex items-center justify-center transition-colors" title="${translate("Lock Terminal")}" type="button">
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
      <div class="bg-card p-3 rounded-xl shadow-sm flex items-center gap-3">
        <div class="relative flex-1">
          <span class="material-symbols-outlined absolute left-3.5 top-1/2 -translate-y-1/2 text-muted-foreground text-[20px]">search</span>
          <input id="barcode-input" type="text" value="${this.escape(this.searchQuery)}"
            data-action="input->${this.identifier}#updateSearch keydown.enter->${this.identifier}#handleBarcodeEnter"
            placeholder="${translate("Search products or scan barcode (F1)...")}"
            class="w-full h-11 pl-11 pr-12 rounded-xl bg-muted text-foreground placeholder:text-muted-foreground focus:ring-2 focus:ring-primary outline-none transition-all" />
          <span class="absolute right-3 top-1/2 -translate-y-1/2 bg-line text-muted-foreground text-[11px] px-1.5 py-0.5 rounded">F1</span>
        </div>
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

  renderProductsSection() {
    return `
      <div class="flex justify-between items-end mb-1">
        <h3 class="text-xs font-bold text-muted-foreground uppercase tracking-widest">${translate("Products Gallery")}</h3>
        <div class="flex gap-2">
          <button class="p-1.5 rounded bg-card border border-line hover:bg-muted cursor-pointer" type="button">
            <span class="material-symbols-outlined text-sm text-muted-foreground">grid_view</span>
          </button>
          <button class="p-1.5 rounded bg-card border border-line hover:bg-muted cursor-pointer" type="button">
            <span class="material-symbols-outlined text-sm text-muted-foreground">view_list</span>
          </button>
        </div>
      </div>
      <div id="pos-product-grid" class="grid grid-cols-2 sm:grid-cols-3 xl:grid-cols-4 gap-3">
        ${this.renderProductCards()}
      </div>
    `
  }

  renderProductCards() {
    const products = this.filteredProducts
    if (products.length === 0) {
      return `<div class="col-span-full text-center text-muted-foreground py-10 text-sm">${translate("No products found")}</div>`
    }
    return products.map((product) => this.renderProductCard(product)).join("")
  }

  renderProductCard(product) {
    const cartQty = this.cartQuantityFor(product.id)
    const stockQuantity = Number(product.stock_quantity || 0)
    const lowStock = stockQuantity <= 5

    return `
      <article data-action="click->${this.identifier}#addToCart"
        data-${this.identifier}-id-param="${this.escape(product.id)}"
        data-${this.identifier}-stock-id-param="${this.escape(product.stock_id || "")}"
        data-${this.identifier}-name-param="${this.escape(product.name || "")}"
        data-${this.identifier}-price-param="${product.price || 0}"
        class="group relative bg-card p-3 rounded-xl flex flex-col justify-between shadow-sm hover:shadow-md transition-all cursor-pointer border border-line hover:border-primary/40 active:scale-[0.99]">
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
            <span class="text-lg font-bold text-primary">$${Number(product.price || 0).toFixed(2)}</span>
            <span class="text-[11px] ${lowStock ? "text-danger" : "text-muted-foreground"}">${stockQuantity} ${translate("in stock")}</span>
          </div>
        </div>
      </article>
    `
  }

  renderServicesList() {
    const services = this.filteredServices
    if (services.length === 0) return ""

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
        <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-3">
          ${services.map((service) => {
            const serviceName = (service.name || "").toLowerCase()
            const icon = Object.entries(serviceIconMap).find(([key]) => serviceName.includes(key))?.[1] || "spa"
            return `
              <div data-action="click->${this.identifier}#addToCart"
                data-${this.identifier}-id-param="${this.escape(service.id)}"
                data-${this.identifier}-name-param="${this.escape(service.name || "")}"
                data-${this.identifier}-price-param="${service.price || 0}"
                class="bg-muted border border-line p-3 rounded-xl flex items-center gap-3 hover:border-primary/40 transition-colors cursor-pointer group">
                <div class="w-10 h-10 rounded-lg bg-primary/10 flex items-center justify-center text-primary shrink-0">
                  <span class="material-symbols-outlined text-[20px]">${icon}</span>
                </div>
                <div class="min-w-0">
                  <h4 class="text-[13px] font-semibold text-foreground truncate">${this.escape(service.name || translate("Service"))}</h4>
                  <p class="text-[11px] text-muted-foreground">$${Number(service.price || 0).toFixed(2)}</p>
                </div>
              </div>
            `
          }).join("")}
        </div>
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
      <div class="bg-muted rounded-xl px-3 py-2 flex flex-col gap-2">
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
            ? `<button data-action="click->${this.identifier}#focusCustomerLookup"
                 class="text-[11px] font-semibold text-primary hover:text-primary/80 shrink-0 cursor-pointer">${translate("Change")}</button>`
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
      if (this.orderId) {
        return `
          <div class="p-2 rounded-xl bg-muted border border-line flex items-center justify-between gap-2">
            <div class="flex flex-col flex-1 min-w-0">
              <span class="text-[13px] font-semibold text-foreground truncate">${this.escape(item.name)}</span>
              <span class="text-[11px] text-muted-foreground">${translate("Qty:")} ${item.qty}</span>
            </div>
            <span class="text-[13px] font-bold text-foreground">$${(item.price * item.qty).toFixed(2)}</span>
          </div>
        `
      }

      return `
        <div class="p-2 rounded-xl bg-muted/50 hover:bg-muted transition-colors flex items-center justify-between gap-2 group">
          <div class="flex flex-col flex-1 min-w-0">
            <span class="text-[13px] font-semibold text-foreground truncate">${this.escape(item.name)}</span>
            <span class="text-[11px] text-muted-foreground">$${Number(item.price || 0).toFixed(2)} ${translate("/ ea")}</span>
          </div>
          <div class="flex items-center bg-card rounded-lg p-0.5 shadow-sm border border-line shrink-0">
            <button data-action="click->${this.identifier}#updateQty" data-${this.identifier}-id-param="${this.escape(item.id)}" data-${this.identifier}-delta-param="-1"
              class="w-6 h-6 flex items-center justify-center text-muted-foreground hover:text-foreground rounded font-bold cursor-pointer">
              <span class="material-symbols-outlined text-[14px]">remove</span>
            </button>
            <span class="w-6 text-center text-[12px] font-semibold text-foreground">${item.qty}</span>
            <button data-action="click->${this.identifier}#updateQty" data-${this.identifier}-id-param="${this.escape(item.id)}" data-${this.identifier}-delta-param="1"
              class="w-6 h-6 flex items-center justify-center text-muted-foreground hover:text-foreground rounded font-bold cursor-pointer">
              <span class="material-symbols-outlined text-[14px]">add</span>
            </button>
          </div>
          <span class="text-[13px] font-bold text-foreground w-16 text-right shrink-0">$${(item.price * item.qty).toFixed(2)}</span>
          <button data-action="click->${this.identifier}#removeFromCart" data-${this.identifier}-id-param="${this.escape(item.id)}"
            class="text-muted-foreground hover:text-danger p-1 shrink-0 cursor-pointer">
            <span class="material-symbols-outlined text-[16px]">close</span>
          </button>
        </div>
      `
    }).join("")
  }

  renderPaymentSection() {
    const subtotal = this.getSubtotal()
    const tax = this.getTax()
    const total = this.getTotal()

    if (this.receipt) {
      const receipt = this.receipt
      return `
        <div class="pt-2 border-t border-line">
          <div class="space-y-3">
            <div class="flex items-center justify-between">
              <h3 class="text-sm font-black uppercase tracking-widest text-muted-foreground">${translate("Receipt")}</h3>
              ${Helpers.statusBadge(receipt.payment_status)}
            </div>
            <div class="text-[11px] text-muted-foreground font-mono">${this.escape(receipt.invoice_code || "")}${receipt.issued_at ? ` · ${new Date(receipt.issued_at).toLocaleString()}` : ""}</div>
            <div class="border-t border-dashed border-line pt-3 space-y-2">
              ${(receipt.items || []).map((item) => `
                <div class="flex justify-between text-sm text-foreground gap-2">
                  <span class="truncate">${item.quantity} × ${this.escape(item.name)}</span>
                  <span class="font-bold shrink-0">$${Number(item.total_price).toFixed(2)}</span>
                </div>
              `).join("")}
            </div>
            <div class="border-t border-dashed border-line pt-3 space-y-1.5">
              <div class="flex justify-between text-sm text-muted-foreground"><span>${translate("Subtotal")}</span><span>$${Number(receipt.subtotal).toFixed(2)}</span></div>
              <div class="flex justify-between text-sm text-muted-foreground"><span>${translate("Tax (10%)")}</span><span>$${Number(receipt.tax).toFixed(2)}</span></div>
              <div class="flex justify-between items-center pt-1">
                <span class="font-bold text-foreground">${translate("Total Amount")}</span>
                <span class="text-xl font-black text-primary">$${Number(receipt.total).toFixed(2)}</span>
              </div>
            </div>
            ${receipt.payment_method_name ? `<div class="text-[11px] text-muted-foreground">${translate("Payment Method")}: <span class="font-bold text-foreground">${this.escape(receipt.payment_method_name)}</span></div>` : ""}
            <button data-action="click->${this.identifier}#newSale"
              class="w-full bg-primary text-primary-foreground py-3 rounded-xl text-base font-black shadow-lg shadow-primary/20 hover:brightness-110 active:scale-[0.98] transition-all flex items-center justify-center gap-2 cursor-pointer">
              <span class="material-symbols-outlined">add_shopping_cart</span>
              ${translate("New Sale")}
            </button>
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
            <p class="text-2xl font-black text-primary">$${total.toFixed(2)}</p>
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
    const changeDue = this.getChangeDue()
    const cashPanel = isCashMode ? `
      <div class="bg-muted p-3 rounded-xl flex flex-col gap-2">
        <div>
          <label class="block text-[10px] uppercase tracking-widest text-muted-foreground font-bold mb-1">${translate("Received")}</label>
          <div class="relative">
            <span class="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground font-bold text-sm">$</span>
            <input type="number" value="${this.cashReceived || ""}" data-action="input->${this.identifier}#updateCashReceived"
              class="w-full bg-card border border-line rounded-lg pl-7 pr-3 py-2 text-lg font-bold focus:ring-2 focus:ring-primary outline-none" />
          </div>
        </div>
        <div class="grid grid-cols-3 gap-1.5">
          ${this.quickCashAmounts.map((amount) => `
            <button data-action="click->${this.identifier}#setCashReceived" data-${this.identifier}-amount-param="${amount}"
              class="py-1.5 rounded-lg bg-card border border-line hover:bg-muted text-[11px] font-semibold text-foreground transition-colors cursor-pointer">
              $${amount}
            </button>
          `).join("")}
        </div>
        <div class="flex items-center justify-between bg-success/10 border border-success/20 rounded-lg px-3 py-2">
          <span class="text-[11px] font-bold text-success">${translate("Change Due")}</span>
          <span id="cashier-change-due" class="text-lg font-black ${changeDue >= 0 ? "text-success" : "text-danger"}">${changeDue >= 0 ? "$" + changeDue.toFixed(2) : "-$" + Math.abs(changeDue).toFixed(2)}</span>
        </div>
      </div>
    ` : ""

    return `
      <div class="flex flex-col gap-3 pt-2 border-t border-line">
        <div class="bg-muted p-3 rounded-xl flex flex-col gap-1.5">
          <div class="flex justify-between items-center text-[12px] text-muted-foreground">
            <span>${translate("Subtotal")}</span>
            <span class="text-[13px] font-semibold text-foreground">$${subtotal.toFixed(2)}</span>
          </div>
          <div class="flex justify-between items-center text-[12px] text-muted-foreground">
            <span>${translate("Tax (10%)")}</span>
            <span class="text-[13px] font-semibold text-foreground">$${tax.toFixed(2)}</span>
          </div>
          <div class="h-px bg-line my-1"></div>
          <div class="flex justify-between items-center">
            <span class="text-[13px] font-bold text-foreground">${translate("Total Amount")}</span>
            <span class="text-2xl font-extrabold text-primary">$${total.toFixed(2)}</span>
          </div>
        </div>

        <div class="grid grid-cols-3 gap-2">${methodButtons}</div>

        ${cashPanel}

        ${this.orderId ? `
          <div class="grid grid-cols-2 gap-2">
            <button data-action="click->${this.identifier}#cancelOrder"
              class="w-full bg-card border-2 border-line text-foreground py-3 rounded-xl text-sm font-black hover:bg-muted active:scale-[0.98] transition-all flex items-center justify-center cursor-pointer">
              ${translate("Cancel")}
            </button>
            <button data-action="click->${this.identifier}#pay"
              class="w-full bg-success text-success-foreground py-3 rounded-xl text-sm font-black shadow-lg shadow-success/20 hover:brightness-110 active:scale-[0.98] transition-all flex items-center justify-center gap-2 cursor-pointer">
              <span class="material-symbols-outlined text-[18px]">point_of_sale</span>
              ${translate("COMPLETE PAYMENT")}
            </button>
          </div>
        ` : `
          <button data-action="click->${this.identifier}#initiateOrder"
            class="w-full bg-primary text-primary-foreground py-3 rounded-xl text-base font-black shadow-lg shadow-primary/20 hover:brightness-110 active:scale-[0.98] transition-all flex items-center justify-center gap-2 cursor-pointer">
            <span class="material-symbols-outlined text-[20px]">shopping_cart</span>
            ${translate("ORDER")}
          </button>
        `}

        <div class="grid grid-cols-2 gap-2 pt-1 border-t border-line">
          <button data-action="click->${this.identifier}#printReceipt"
            class="py-1.5 rounded-lg bg-muted hover:bg-line text-muted-foreground text-[11px] font-semibold flex items-center justify-center gap-1.5 transition-colors cursor-pointer">
            <span class="material-symbols-outlined text-[16px]">print</span>
            ${translate("Print Receipt")}
          </button>
          <button data-action="click->${this.identifier}#openDrawer"
            class="py-1.5 rounded-lg bg-muted hover:bg-line text-muted-foreground text-[11px] font-semibold flex items-center justify-center gap-1.5 transition-colors cursor-pointer">
            <span class="material-symbols-outlined text-[16px]">point_of_sale</span>
            ${translate("Open Drawer")}
          </button>
        </div>
      </div>
    `
  }

  printReceipt() {
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
