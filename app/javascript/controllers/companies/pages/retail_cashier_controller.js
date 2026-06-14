import { Controller } from "@hotwired/stimulus"

export default class Companies_Pages_RetailCashierController extends Controller {
  /** @type {any | null} */ page = null
  /** @type {any[]} */ products = []
  /** @type {any[]} */ services = []
  /** @type {{ id: number, name: string, items: { id: number, name: string, price: number, qty: number }[] }[]} */ tabs = []
  /** @type {number} */ activeTabIndex = 0
  /** @type {number} */ tabCounter = 0

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
      this.element.innerHTML = `<div class="flex items-center justify-center h-screen text-red-600 text-lg font-semibold">Failed to load cashier page.</div>`
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
    const { id, name, price } = event.params
    if (!this.activeTab) return
    const existing = this.activeTab.items.find(i => i.id === id)
    if (existing) {
      existing.qty++
    } else {
      this.activeTab.items.push({ id, name, price, qty: 1 })
    }
    this.renderContent()
  }

  removeFromCart(event) {
    const { id } = event.params
    if (!this.activeTab) return
    this.activeTab.items = this.activeTab.items.filter(i => i.id !== id)
    this.renderContent()
  }

  updateQty(event) {
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

  pay() {
    const tab = this.activeTab
    if (!tab || tab.items.length === 0) {
      console.log("Pay clicked — cart is empty")
      return
    }
    console.log("=== PAYMENT ===")
    console.log("Customer:", tab.name)
    console.log("Items:", JSON.parse(JSON.stringify(tab.items)))
    console.log("Total:", this.getTotal().toFixed(2))
    console.log("==============")
  }

  getTotal() {
    if (!this.activeTab) return 0
    return this.activeTab.items.reduce((sum, i) => sum + (i.price * i.qty), 0)
  }

  renderContent() {
    this.element.innerHTML = this.contentHTML()
  }

  contentHTML() {
    const p = this.page || {}
    const branchName = p.branch?.name || ""
    const pageName = p.name || "Cashier"

    return `
      <div class="h-screen flex flex-col bg-slate-50 overflow-hidden">
        <div class="bg-white border-b border-slate-200 px-6 py-3 flex items-center justify-between shrink-0">
          <div class="flex items-center gap-4">
            <a href="${Helpers.company_pages_path(this.getCompanyId())}"
              class="text-sm text-slate-400 hover:text-slate-600 cursor-pointer">
              <span class="material-symbols-outlined text-[18px] align-middle">arrow_back</span>
            </a>
            <h1 class="text-lg font-bold text-slate-900">${pageName}</h1>
            <span class="text-sm text-slate-400">${branchName}</span>
          </div>
        </div>

        <div class="flex flex-1 overflow-hidden">
          <div class="flex flex-col flex-1 min-w-0">
            <div class="bg-white border-b border-slate-200 px-4 py-2 flex items-center gap-1 overflow-x-auto shrink-0">
              ${this.tabs.map((tab, i) => `
                <div class="flex items-center gap-1 px-3 py-1.5 rounded-lg text-sm whitespace-nowrap cursor-pointer transition-colors ${i === this.activeTabIndex ? 'bg-blue-100 text-blue-700 font-semibold' : 'text-slate-600 hover:bg-slate-100'}">
                  <span data-action="click->${this.identifier}#switchTab" data-${this.identifier}-index-param="${i}">${tab.name}</span>
                  ${this.tabs.length > 1 ? `
                    <button data-action="click->${this.identifier}#closeTab" data-${this.identifier}-index-param="${i}"
                      class="ml-1 text-slate-400 hover:text-red-500 cursor-pointer">
                      <span class="material-symbols-outlined text-[14px]">close</span>
                    </button>
                  ` : ''}
                </div>
              `).join('')}
              <button data-action="click->${this.identifier}#addTab"
                class="flex items-center gap-1 px-3 py-1.5 text-sm text-blue-600 hover:bg-blue-50 rounded-lg cursor-pointer whitespace-nowrap">
                <span class="material-symbols-outlined text-[16px]">add</span>
                Add
              </button>
            </div>

            <div class="flex-1 overflow-y-auto p-4">
              ${this.renderProductGrid()}
            </div>
          </div>

          <div class="w-[380px] bg-white border-l border-slate-200 flex flex-col shrink-0">
            <div class="px-5 py-3 border-b border-slate-200">
              <div class="flex items-center justify-between">
                <span class="text-xs font-bold text-slate-400 uppercase tracking-wider">Cart</span>
                <span class="text-xs font-medium text-slate-500">${this.activeTab?.name || ''}</span>
              </div>
            </div>
            <div class="flex-1 overflow-y-auto px-5 py-3 space-y-2">${this.renderCartItems()}</div>
            <div class="px-5 py-4 border-t border-slate-200 bg-slate-50">
              <div class="flex justify-between items-baseline mb-4">
                <span class="text-sm font-semibold text-slate-600">Total</span>
                <span class="text-2xl font-bold text-slate-900">$${this.getTotal().toFixed(2)}</span>
              </div>
              <button data-action="click->${this.identifier}#pay"
                class="w-full py-3 bg-blue-600 hover:bg-blue-700 text-white rounded-xl font-bold text-sm transition-colors cursor-pointer">
                Pay
              </button>
            </div>
          </div>
        </div>
      </div>
    `
  }

  renderProductGrid() {
    const productCards = this.products.map(p => `
      <div data-action="click->${this.identifier}#addToCart"
        data-${this.identifier}-id-param="${p.id}"
        data-${this.identifier}-name-param="${p.name.replace(/"/g, '&quot;')}"
        data-${this.identifier}-price-param="${p.price || 0}"
        class="bg-white rounded-xl border border-slate-200 p-3 hover:shadow-md hover:border-blue-200 transition-all cursor-pointer active:scale-[0.98]">
        ${p.image_url
          ? `<div class="w-full h-24 rounded-lg overflow-hidden mb-3 bg-slate-50">
               <img src="${p.image_url}" class="w-full h-full object-cover" />
             </div>`
          : `<div class="w-full h-24 bg-gradient-to-br from-blue-50 to-indigo-100 rounded-lg flex items-center justify-center mb-3">
               <span class="material-symbols-outlined text-3xl text-blue-400">inventory_2</span>
             </div>`
        }
        <p class="text-sm font-semibold text-slate-900 truncate">${p.name}</p>
        <p class="text-sm font-bold text-blue-600 mt-1">$${(p.price || 0).toFixed(2)}</p>
      </div>
    `).join('')

    const serviceCards = this.services.map(s => `
      <div data-action="click->${this.identifier}#addToCart"
        data-${this.identifier}-id-param="${s.id}"
        data-${this.identifier}-name-param="${s.name.replace(/"/g, '&quot;')}"
        data-${this.identifier}-price-param="${s.price || 0}"
        class="bg-white rounded-xl border border-slate-200 p-3 hover:shadow-md hover:border-emerald-200 transition-all cursor-pointer active:scale-[0.98]">
        ${s.image_url
          ? `<div class="w-full h-24 rounded-lg overflow-hidden mb-3 bg-slate-50">
               <img src="${s.image_url}" class="w-full h-full object-cover" />
             </div>`
          : `<div class="w-full h-24 bg-gradient-to-br from-emerald-50 to-green-100 rounded-lg flex items-center justify-center mb-3">
               <span class="material-symbols-outlined text-3xl text-emerald-400">spa</span>
             </div>`
        }
        <p class="text-sm font-semibold text-slate-900 truncate">${s.name}</p>
        <p class="text-sm font-bold text-emerald-600 mt-1">$${(s.price || 0).toFixed(2)}</p>
      </div>
    `).join('')

    const sections = []
    if (productCards) {
      sections.push(`
        <div>
          <h3 class="text-xs font-bold text-slate-400 uppercase tracking-wider mb-3">Products</h3>
          <div class="grid grid-cols-3 xl:grid-cols-4 gap-3">${productCards}</div>
        </div>
      `)
    }
    if (serviceCards) {
      sections.push(`
        <div class="mt-6">
          <h3 class="text-xs font-bold text-slate-400 uppercase tracking-wider mb-3">Services</h3>
          <div class="grid grid-cols-3 xl:grid-cols-4 gap-3">${serviceCards}</div>
        </div>
      `)
    }

    return sections.length > 0
      ? sections.join('')
      : '<div class="flex items-center justify-center h-full text-slate-400 text-sm">No products or services available.</div>'
  }

  renderCartItems() {
    if (!this.activeTab || this.activeTab.items.length === 0) {
      return '<div class="text-center text-slate-400 py-8 text-sm">Cart is empty</div>'
    }
    return this.activeTab.items.map(item => `
      <div class="flex items-center justify-between p-3 bg-slate-50 rounded-lg gap-3">
        <div class="flex-1 min-w-0">
          <p class="text-sm font-medium text-slate-900 truncate">${item.name}</p>
          <div class="flex items-center gap-1 mt-1.5">
            <button data-action="click->${this.identifier}#updateQty" data-${this.identifier}-id-param="${item.id}" data-${this.identifier}-delta-param="-1"
              class="w-7 h-7 rounded-md bg-white border border-slate-200 text-slate-600 hover:text-red-600 hover:border-red-200 flex items-center justify-center text-sm font-medium cursor-pointer">−</button>
            <span class="text-sm font-semibold w-7 text-center text-slate-900">${item.qty}</span>
            <button data-action="click->${this.identifier}#updateQty" data-${this.identifier}-id-param="${item.id}" data-${this.identifier}-delta-param="1"
              class="w-7 h-7 rounded-md bg-white border border-slate-200 text-slate-600 hover:text-emerald-600 hover:border-emerald-200 flex items-center justify-center text-sm font-medium cursor-pointer">+</button>
          </div>
        </div>
        <div class="text-right shrink-0">
          <p class="text-sm font-bold text-slate-900">$${(item.price * item.qty).toFixed(2)}</p>
          <button data-action="click->${this.identifier}#removeFromCart" data-${this.identifier}-id-param="${item.id}"
            class="text-[11px] text-red-400 hover:text-red-600 cursor-pointer">Remove</button>
        </div>
      </div>
    `).join('')
  }

  getCompanyId() {
    return window.location.pathname.split("/")[2]
  }
}
