import { Controller } from "@hotwired/stimulus"

export default class Companies_Pages_RetailCashierController extends Controller {
  /** @type {any | null} */ page = null
  /** @type {any[]} */ products = []
  /** @type {any[]} */ services = []
  /** @type {{ id: number, name: string, items: { id: number, name: string, price: number, qty: number, stockId?: string }[] }[]} */ tabs = []
  /** @type {number} */ activeTabIndex = 0
  /** @type {number} */ tabCounter = 0
  /** @type {string} */ activePaymentMethod = 'cash'
  /** @type {number} */ cashReceived = 0
  /** @type {string | null} */ orderId = null
  /** @type {number} */ orderTotal = 0

  async connect() {
    const pathParts = window.location.pathname.split("/")
    const companyId = pathParts[2]
    const pageId = pathParts[4]

    try {
      const url = `${Helpers.retail_cashier_company_page_path(companyId, pageId)}.json`
      const response = await fetchJson(url)
      this.page = response.page
      this.products = response.products || []
      this.services = response.services || []

      this.addTab()
    } catch (error) {
      this.element.innerHTML = `<div class="flex items-center justify-center h-screen text-red-600 text-lg font-semibold">${translate("Failed to load cashier page.")}</div>`
    }
  }

  addTab() {
    this.tabCounter++
    this.tabs.push({ id: this.tabCounter, name: `Customer ${this.tabCounter}`, items: [] })
    this.activeTabIndex = this.tabs.length - 1
    this.renderContent()
  }

  switchTab(event) {
    this.activeTabIndex = event.params.index
    this.renderContent()
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

  addToCart(event) {
    if (this.orderId) return
    const { id, name, price, stockId } = event.params
    if (!this.activeTab) return
    const existing = this.activeTab.items.find(i => i.id === id)
    if (existing) {
      existing.qty++
    } else {
      this.activeTab.items.push({ id, name, price, qty: 1, stockId })
    }
    this.renderContent()
  }

  removeFromCart(event) {
    if (this.orderId) return
    const { id } = event.params
    if (!this.activeTab) return
    this.activeTab.items = this.activeTab.items.filter(i => i.id !== id)
    this.renderContent()
  }

  updateQty(event) {
    if (this.orderId) return
    const { id, delta } = event.params
    if (!this.activeTab) return
    const item = this.activeTab.items.find(i => i.id === id)
    if (item) {
      item.qty = Math.max(0, item.qty + delta)
      if (item.qty === 0) {
        this.activeTab.items = this.activeTab.items.filter(i => i.id !== id)
      }
    }
    this.renderContent()
  }

  setPaymentMethod(event) {
    this.activePaymentMethod = event.params.method
    this.renderContent()
  }

  updateCashReceived(event) {
    this.cashReceived = parseFloat(event.target.value) || 0
    this.refreshChangeDue()
  }

  refreshChangeDue() {
    const el = document.getElementById('cashier-change-due')
    if (!el) return
    const changeDue = this.getChangeDue()
    el.textContent = (changeDue >= 0 ? '$' : '-$') + Math.abs(changeDue).toFixed(2)
    el.className = `text-lg font-black ${changeDue >= 0 ? 'text-green-600' : 'text-red-600'}`
  }

  async initiateOrder() {
    const tab = this.activeTab
    if (!tab || tab.items.length === 0) {
      toast({ type: 'warning', message: translate('Cart is empty') })
      return
    }

    const companyId = this.getCompanyId()
    const items = tab.items
      .filter(i => i.stockId)
      .map(i => ({ stock_id: i.stockId, product_id: i.id, quantity: i.qty, unit_price: i.price }))

    if (items.length === 0) {
      toast({ type: 'warning', message: translate('No stock-tracked items in cart') })
      return
    }

    try {
      const res = await fetchJson(Helpers.order_processing_v1_checkout_path(companyId), {
        method: 'POST',
        body: { branch_id: this.page.branch.id, items }
      })
      this.orderId = res.order_id
      this.orderTotal = res.total_price || 0
      this.renderContent()
      toast({ type: 'success', message: res.message || translate('Order created') })
    } catch (error) {
      toast({ type: 'error', message: error.errors?.join(', ') || error.message || translate('Failed to create order') })
    }
  }

  async pay() {
    try {
      const res = await fetchJson(Helpers.order_processing_v1_pay_path(this.getCompanyId()), {
        method: 'POST',
        body: { order_id: this.orderId }
      })
      toast({ type: 'success', message: res.message || translate('Payment completed') })
      this.activeTab.items = []
      this.orderId = null
      this.orderTotal = 0
      this.cashReceived = 0
      this.renderContent()
    } catch (error) {
      toast({ type: 'error', message: error.errors?.join(', ') || error.message || translate('Payment failed') })
    }
  }

  cancelOrder() {
    this.orderId = null
    this.orderTotal = 0
    this.renderContent()
  }

  getSubtotal() {
    if (!this.activeTab) return 0
    return this.activeTab.items.reduce((sum, i) => sum + (i.price * i.qty), 0)
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

  renderContent() {
    this.element.innerHTML = this.contentHTML()
  }

  contentHTML() {
    const p = this.page || {}
    const branchName = p.branch?.name || ''
    const pageName = p.name || translate('Cashier')
    const userName = window.currentUser?.name || translate('Admin User')
    const userRole = window.currentUser?.role || translate('Administrator')
    const avatarUrl = window.currentUser?.avatar || ''

    return `
      <div class="bg-gray-50 text-gray-900 min-h-screen flex flex-col overflow-hidden">
        ${this.renderHeader(branchName, pageName, userName, userRole, avatarUrl)}
        <main class="flex flex-1 pt-16 overflow-hidden">
          <div class="flex-1 flex flex-col p-6 overflow-y-auto">
            ${this.renderCategoryPills()}
            ${this.renderProductsSection()}
            ${this.renderServicesSection()}
          </div>
          <aside class="w-1/3 bg-white border-l border-gray-200 flex flex-col shrink-0 relative z-10">
            ${this.renderOrderHeader()}
            <div class="flex-1 overflow-y-auto p-4 space-y-3">${this.renderCartItems()}</div>
            ${this.renderPaymentSection()}
          </aside>
        </main>
        ${this.renderFloatingActions()}
      </div>
    `
  }

  renderHeader(branchName, pageName, userName, userRole, avatarUrl) {
    return `
      <header class="fixed top-0 w-full z-50 bg-white shadow-sm flex justify-between items-center h-16 px-8 border-b border-gray-200">
        <div class="flex items-center gap-6">
          <div class="text-xl font-bold tracking-tighter text-blue-600">${pageName}</div>
          <div class="h-6 w-px bg-gray-200 mx-2"></div>
          <div class="flex items-center gap-2">
            <span class="material-symbols-outlined text-gray-500">storefront</span>
            <span class="text-sm font-medium">${branchName || translate('Branch')}</span>
          </div>
        </div>
        <div class="flex-1 max-w-xl mx-12">
          <div class="relative">
            <span class="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-gray-500 text-lg">search</span>
            <input type="text" placeholder="${translate("Search products (F1)...")}"
              class="w-full bg-gray-100 border-none rounded-lg pl-10 pr-4 py-2 text-sm focus:ring-2 focus:ring-blue-600 transition-all outline-none" />
          </div>
        </div>
        <div class="flex items-center gap-4">
          <button class="p-2 rounded-full hover:bg-gray-50 transition-colors cursor-pointer">
            <span class="material-symbols-outlined text-gray-500">notifications</span>
          </button>
          <button class="p-2 rounded-full hover:bg-gray-50 transition-colors cursor-pointer">
            <span class="material-symbols-outlined text-gray-500">help_outline</span>
          </button>
          <button class="p-2 rounded-full hover:bg-gray-50 transition-colors cursor-pointer">
            <span class="material-symbols-outlined text-gray-500">settings</span>
          </button>
          <div class="flex items-center gap-3 ml-2 pl-4 border-l border-gray-200">
            <div class="text-right">
              <p class="text-xs font-bold">${userName}</p>
              <p class="text-[10px] text-gray-500">${userRole}</p>
            </div>
            <div class="w-8 h-8 rounded-full bg-gray-200 flex items-center justify-center overflow-hidden">
              ${avatarUrl ? `<img src="${avatarUrl}" class="w-full h-full object-cover" />` : `
                <span class="material-symbols-outlined text-gray-500 text-sm">person</span>
              `}
            </div>
          </div>
        </div>
      </header>
    `
  }

  renderCategoryPills() {
    const categories = [
      translate('All Products'), translate('Tech Accessories'), translate('Apparel'), translate('Office Supplies'), translate('Electronics'), translate('Services')
    ]
    return `
      <div class="flex items-center gap-3 mb-6 overflow-x-auto pb-2">
        ${categories.map((cat, i) => `
          <button class="px-6 py-2 ${i === 0 ? 'bg-blue-600 text-white' : 'bg-white hover:bg-gray-100 border border-gray-200 text-gray-500'} rounded-full font-medium whitespace-nowrap transition-colors cursor-pointer text-sm">
            ${cat}
          </button>
        `).join('')}
      </div>
    `
  }

  renderProductsSection() {
    if (this.products.length === 0) return ''

    return `
      <div class="flex justify-between items-end mb-4">
        <h3 class="text-xs font-bold text-gray-500 uppercase tracking-widest">${translate("Products Gallery")}</h3>
        <div class="flex gap-2">
          <button class="p-1.5 rounded bg-white border border-gray-200 hover:bg-gray-50 cursor-pointer">
            <span class="material-symbols-outlined text-sm text-gray-500">grid_view</span>
          </button>
          <button class="p-1.5 rounded bg-white border border-gray-200 hover:bg-gray-50 cursor-pointer">
            <span class="material-symbols-outlined text-sm text-gray-500">view_list</span>
          </button>
        </div>
      </div>
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5 gap-4">
        ${this.products.map(p => this.renderProductCard(p)).join('')}
      </div>
    `
  }

  renderProductCard(p) {
    return `
      <div data-action="click->${this.identifier}#addToCart"
        data-${this.identifier}-id-param="${p.id}"
        data-${this.identifier}-stock-id-param="${p.stock_id || ''}"
        data-${this.identifier}-name-param="${(p.name || '').replace(/"/g, '&quot;')}"
        data-${this.identifier}-price-param="${p.price || 0}"
        class="bg-white rounded-xl overflow-hidden shadow-sm border border-gray-200 hover:shadow-lg transition-all cursor-pointer flex flex-col group active:scale-[0.98]">
        <div class="h-32 overflow-hidden relative">
          ${p.image_url
            ? `<img src="${p.image_url}" class="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105" />`
            : `<div class="w-full h-full bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center">
                 <span class="material-symbols-outlined text-3xl text-blue-400">inventory_2</span>
               </div>`
          }
          <div class="absolute inset-0 bg-blue-600/0 group-hover:bg-blue-600/10 transition-colors"></div>
        </div>
        <div class="p-4 flex flex-col flex-1">
          <span class="text-[10px] uppercase tracking-tighter text-gray-500 mb-1">${p.code || 'SKU-' + p.id}</span>
          <h4 class="font-bold text-gray-900 leading-tight mb-2 text-sm">${p.name || translate('Unnamed Product')}</h4>
          <div class="mt-auto flex justify-between items-center">
            <span class="text-blue-600 font-black">$${(p.price || 0).toFixed(2)}</span>
            <span class="material-symbols-outlined text-blue-600 opacity-0 group-hover:opacity-100 transition-opacity">add_circle</span>
          </div>
        </div>
      </div>
    `
  }

  renderServicesSection() {
    if (this.services.length === 0) return ''

    const serviceIconMap = {
      delivery: 'local_shipping',
      shipping: 'local_shipping',
      assembly: 'build',
      install: 'build',
      warranty: 'verified',
      protect: 'verified',
      gift: 'id_card',
      wrap: 'id_card',
      package: 'id_card'
    }

    return `
      <div class="mt-12 mb-6">
        <h3 class="text-xs font-bold text-gray-500 uppercase tracking-widest mb-4">${translate("Retail Services")}</h3>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          ${this.services.map(s => {
            const sName = (s.name || '').toLowerCase()
            const icon = Object.entries(serviceIconMap).find(([key]) => sName.includes(key))?.[1] || 'spa'
            return `
              <div data-action="click->${this.identifier}#addToCart"
                data-${this.identifier}-id-param="${s.id}"
                data-${this.identifier}-name-param="${(s.name || '').replace(/"/g, '&quot;')}"
                data-${this.identifier}-price-param="${s.price || 0}"
                class="bg-gray-100 border border-gray-200 p-4 rounded-xl flex items-center gap-4 hover:border-blue-600 transition-colors cursor-pointer group">
                <div class="w-12 h-12 rounded-lg bg-blue-600/10 flex items-center justify-center text-blue-600 shrink-0">
                  <span class="material-symbols-outlined">${icon}</span>
                </div>
                <div>
                  <h4 class="text-sm font-bold text-gray-900">${s.name || translate('Service')}</h4>
                  <p class="text-xs text-gray-500">$${(s.price || 0).toFixed(2)}</p>
                </div>
              </div>
            `
          }).join('')}
        </div>
      </div>
    `
  }

  renderOrderHeader() {
    return `
      <div class="p-4 border-b border-gray-200">
        <div class="flex items-center gap-1 overflow-x-auto">
          ${this.tabs.map((tab, i) => `
            <div class="flex items-center gap-1 px-3 py-1.5 rounded-lg text-sm whitespace-nowrap transition-colors ${i === this.activeTabIndex ? 'bg-blue-100 text-blue-700 font-semibold' : 'text-gray-500 hover:bg-gray-100'} cursor-pointer">
              <span data-action="click->${this.identifier}#switchTab" data-${this.identifier}-index-param="${i}">${tab.name}</span>
              ${this.tabs.length > 1 ? `
                <button data-action="click->${this.identifier}#closeTab" data-${this.identifier}-index-param="${i}"
                  class="ml-1 text-gray-400 hover:text-red-500 cursor-pointer">
                  <span class="material-symbols-outlined text-[14px]">close</span>
                </button>
              ` : ''}
            </div>
          `).join('')}
          <button data-action="click->${this.identifier}#addTab"
            class="flex items-center gap-1 px-3 py-1.5 text-sm text-blue-600 hover:bg-blue-50 rounded-lg cursor-pointer whitespace-nowrap">
            <span class="material-symbols-outlined text-[16px]">add</span>
            ${translate("Add")}
          </button>
        </div>
      </div>
    `
  }

  renderCartItems() {
    if (!this.activeTab || this.activeTab.items.length === 0) {
      return `<div class="text-center text-gray-400 py-8 text-sm">${translate("Cart is empty")}</div>`
    }
    return this.activeTab.items.map(item => {
      if (this.orderId) {
        return `
          <div class="flex gap-3 bg-gray-50 p-3 rounded-xl border border-gray-200/50">
            <div class="w-16 h-16 rounded-lg bg-white overflow-hidden flex-shrink-0 border border-gray-200 flex items-center justify-center">
              <span class="material-symbols-outlined text-gray-400">inventory_2</span>
            </div>
            <div class="flex-1 flex flex-col justify-between min-w-0">
              <h5 class="text-sm font-bold text-gray-900 truncate">${item.name}</h5>
              <div class="flex justify-between items-center mt-1">
                <span class="text-xs text-gray-500">${translate("Qty:")} ${item.qty}</span>
                <span class="text-sm font-bold text-gray-900">$${(item.price * item.qty).toFixed(2)}</span>
              </div>
            </div>
          </div>
        `
      }
      return `
        <div class="flex gap-3 bg-gray-50 p-3 rounded-xl border border-gray-200/50 group">
          <div class="w-16 h-16 rounded-lg bg-white overflow-hidden flex-shrink-0 border border-gray-200 flex items-center justify-center">
            <span class="material-symbols-outlined text-gray-400">inventory_2</span>
          </div>
          <div class="flex-1 flex flex-col justify-between min-w-0">
            <div class="flex justify-between items-start gap-2">
              <h5 class="text-sm font-bold text-gray-900 truncate">${item.name}</h5>
              <button data-action="click->${this.identifier}#removeFromCart" data-${this.identifier}-id-param="${item.id}"
                class="text-gray-400 hover:text-red-600 transition-colors shrink-0 cursor-pointer">
                <span class="material-symbols-outlined text-sm">close</span>
              </button>
            </div>
            <div class="flex justify-between items-center mt-1">
              <div class="flex items-center gap-3 bg-white border border-gray-200 rounded-md px-1 py-0.5">
                <button data-action="click->${this.identifier}#updateQty" data-${this.identifier}-id-param="${item.id}" data-${this.identifier}-delta-param="-1"
                  class="w-5 h-5 flex items-center justify-center text-gray-500 hover:text-blue-600 cursor-pointer">
                  <span class="material-symbols-outlined text-xs">remove</span>
                </button>
                <span class="text-xs font-bold w-4 text-center text-gray-900">${item.qty}</span>
                <button data-action="click->${this.identifier}#updateQty" data-${this.identifier}-id-param="${item.id}" data-${this.identifier}-delta-param="1"
                  class="w-5 h-5 flex items-center justify-center text-gray-500 hover:text-blue-600 cursor-pointer">
                  <span class="material-symbols-outlined text-xs">add</span>
                </button>
              </div>
              <span class="text-sm font-bold text-gray-900">$${(item.price * item.qty).toFixed(2)}</span>
            </div>
          </div>
        </div>
      `
    }).join('')
  }

  renderPaymentSection() {
    const subtotal = this.getSubtotal()
    const tax = this.getTax()
    const total = this.getTotal()
    const changeDue = this.getChangeDue()

    return `
      <div class="p-6 bg-white border-t border-gray-200">
        <div class="grid grid-cols-2 gap-2 mb-6 p-1 bg-gray-100 rounded-xl border border-gray-200">
          <button data-action="click->${this.identifier}#setPaymentMethod" data-${this.identifier}-method-param="cash"
            class="flex items-center justify-center gap-2 py-2.5 rounded-lg ${this.activePaymentMethod === 'cash' ? 'bg-white shadow-sm border border-gray-200 text-blue-600 font-bold' : 'text-gray-500 font-medium hover:bg-white/50'} transition-all cursor-pointer">
            <span class="material-symbols-outlined text-sm">payments</span>
            <span class="text-sm">${translate("Cash")}</span>
          </button>
          <button data-action="click->${this.identifier}#setPaymentMethod" data-${this.identifier}-method-param="card"
            class="flex items-center justify-center gap-2 py-2.5 rounded-lg ${this.activePaymentMethod === 'card' ? 'bg-white shadow-sm border border-gray-200 text-blue-600 font-bold' : 'text-gray-500 font-medium hover:bg-white/50'} transition-all cursor-pointer">
            <span class="material-symbols-outlined text-sm">credit_card</span>
            <span class="text-sm">${translate("Card")}</span>
          </button>
        </div>

        <div class="space-y-3 mb-6">
          <div class="flex justify-between text-sm text-gray-500">
            <span>${translate("Subtotal")}</span>
            <span>$${subtotal.toFixed(2)}</span>
          </div>
          <div class="flex justify-between text-sm text-gray-500">
            <span>${translate("Tax (10%)")}</span>
            <span>$${tax.toFixed(2)}</span>
          </div>
          <div class="flex justify-between items-center pt-2 border-t border-dashed border-gray-200">
            <span class="font-bold text-gray-900">${translate("Total Amount")}</span>
            <span class="text-3xl font-black text-blue-600">$${total.toFixed(2)}</span>
          </div>
        </div>

        <div class="grid grid-cols-2 gap-4 mb-6">
          <div>
            <label class="block text-[10px] uppercase tracking-widest text-gray-500 font-bold mb-1.5">${translate("Received")}</label>
            <div class="relative">
              <span class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500 font-bold text-sm">$</span>
              <input type="number" value="${this.cashReceived || ''}" data-action="input->${this.identifier}#updateCashReceived"
                class="w-full bg-gray-200 border-none rounded-lg pl-7 pr-3 py-3 text-lg font-bold focus:ring-2 focus:ring-blue-600 outline-none" />
            </div>
          </div>
          <div>
            <label class="block text-[10px] uppercase tracking-widest text-gray-500 font-bold mb-1.5">${translate("Change Due")}</label>
            <div class="w-full bg-green-50 border border-green-200 rounded-lg px-3 py-3 flex items-center justify-center">
              <span class="text-lg font-black ${changeDue >= 0 ? 'text-green-600' : 'text-red-600'}">
                <span id="cashier-change-due">${changeDue >= 0 ? '$' + changeDue.toFixed(2) : '-$' + Math.abs(changeDue).toFixed(2)}</span>
              </span>
            </div>
          </div>
        </div>

        ${this.orderId ? `
          <div class="grid grid-cols-2 gap-3">
            <button data-action="click->${this.identifier}#cancelOrder"
              class="w-full bg-white border-2 border-slate-200 text-slate-700 py-4 rounded-xl text-lg font-black hover:bg-slate-50 active:scale-[0.98] transition-all flex items-center justify-center gap-3 cursor-pointer">
              ${translate("Cancel")}
            </button>
            <button data-action="click->${this.identifier}#pay"
              class="w-full bg-emerald-600 text-white py-4 rounded-xl text-lg font-black shadow-lg shadow-emerald-600/20 hover:brightness-110 active:scale-[0.98] transition-all flex items-center justify-center gap-3 cursor-pointer">
              <span class="material-symbols-outlined">point_of_sale</span>
              ${translate("COMPLETE PAYMENT")}
            </button>
          </div>
        ` : `
          <button data-action="click->${this.identifier}#initiateOrder"
            class="w-full bg-blue-600 text-white py-4 rounded-xl text-lg font-black shadow-lg shadow-blue-600/20 hover:brightness-110 active:scale-[0.98] transition-all flex items-center justify-center gap-3 cursor-pointer">
            <span class="material-symbols-outlined">shopping_cart</span>
            ${translate("ORDER")}
          </button>
        `}
      </div>
    `
  }

  renderFloatingActions() {
    return `
      <div class="fixed bottom-8 left-8 flex gap-3 z-50">
        <button class="w-12 h-12 bg-gray-900 text-white rounded-full shadow-xl flex items-center justify-center hover:scale-110 transition-transform cursor-pointer">
          <span class="material-symbols-outlined">barcode_scanner</span>
        </button>
        <button class="w-12 h-12 bg-white border border-gray-200 text-gray-900 rounded-full shadow-xl flex items-center justify-center hover:scale-110 transition-transform cursor-pointer">
          <span class="material-symbols-outlined">print</span>
        </button>
      </div>
    `
  }

  getCompanyId() {
    return window.location.pathname.split("/")[2]
  }
}
