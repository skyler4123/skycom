import Retail_Pos_LayoutController from "controllers/retail/pos/layout_controller"
import * as Helpers from "controllers/helpers"
import Retail_Pos_Branches_SettingController from "controllers/retail/pos/branches/setting_controller"

export default class Retail_Pos_Branches_ShowController extends Retail_Pos_LayoutController {
  static targets = ['products', "product", "selectedProduct", "selectedProducts", "totalSelectedProductsPrice", "carts", "cart"]
  static values = {
    productIds: { type: Array, default: [] },
    selectedProductIds: { type: Array, default: [] },
    totalSelectedProductsPrice: { type: Number, default: 0 },
    cartIds: { type: Array, default: [] },
    currentCartId: { type: String, default: "" }
  }

  async init() {
    this.products = []
    this.selectedProducts = []
    this.carts = []

    this.products = await this.fetchProducts()
    this.carts = [
      {
        id: Helpers.randomId(), // Changed
        customerName: 'Customer 1',
        selectedProducts: []
      },
      {
        id: Helpers.randomId(), // Changed
        customerName: 'Customer 2',
        selectedProducts: []
      }
    ];
    this.initValues()
  }

  initValues() {
    this.productIdsValue = Helpers.pluck(this.products) // Changed
    this.cartIdsValue = Helpers.pluck(this.carts)       // Changed
    this.currentCartIdValue = this.carts[0].id
  }

  async fetchProducts() {
    const productsUrl = Helpers.pathname() + '/products' // Changed
    try {
      const response = await fetch(productsUrl)
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      const products = await response.json()
      return products
    } catch (error) {
      console.error("Error fetching products:", error)
    }
  }

  productIdsValueChanged(value, previousValue) {
    this.renderProducts()
  }

  toggleOrder(event) {
    const { productId } = event.params
    const selectedProduct = Helpers.findById(this.selectedProducts, productId) // Changed
    if (selectedProduct) {
      this.selectedProductIdsValue = Helpers.subtractArrays(this.selectedProductIdsValue, [productId]) // Changed
    } else {
      this.selectedProductIdsValue = Helpers.mergeArrays(this.selectedProductIdsValue, [productId])    // Changed
    }
  }

  selectedProductIdsValueChanged(value, previousValue) {
    if (previousValue === undefined) return
    this.selectedProducts = Helpers.queryArray(this.products, {id: value}).map(product => ({...product, quantity: 1})) // Changed
    this.renderHighLightProducts()
    this.renderSelectedProducts()
    this.totalSelectedProductsPriceValue = this.totalSelectedProductsPrice()
    const currentCart = this.currentCart()
    currentCart.selectedProducts = this.selectedProducts
    this.carts = Helpers.mergeObjectArrays(this.carts, [currentCart]) // Changed
  }

  renderHighLightProducts() {
    this.productTargets.forEach((productTarget) => {
      const productTargetId = productTarget.getAttribute(`data-${this.identifier}-product-id-param`)
      if (this.selectedProductIdsValue.includes(productTargetId)) {
        productTarget.setAttribute('open', '')
      } else {
        productTarget.removeAttribute('open')
      }
    })
  }

  currentCartIdValueChanged(value, previousValue) {
    if (previousValue === undefined) return

    this.renderHighLightCurrentCart()
    this.selectedProducts = this.currentCart().selectedProducts
    this.selectedProductIdsValue = Helpers.pluck(this.selectedProducts) // Changed
  }

  renderHighLightCurrentCart() {
    this.cartTargets.forEach((cartTarget) => {
      const cartTargetId = cartTarget.getAttribute(`data-${this.identifier}-cart-id-param`)
      if (cartTargetId === this.currentCartIdValue) {
        cartTarget.setAttribute('open', '')
      } else {
        cartTarget.removeAttribute('open')
      }
    })
  }

  currentCart() {
    return this.carts.find(cart => cart.id === this.currentCartIdValue)
  }

  totalSelectedProductsPrice() {
    return this.selectedProducts.reduce((total, selectedProduct) => {
      return  (total + selectedProduct.price * selectedProduct.quantity)
    }, 0)
  }

  totalSelectedProductsPriceValueChanged(value, previousValue) {
    this.renderTotalSelectedProductsPrice()
  }

  renderTotalSelectedProductsPrice() {
    this.totalSelectedProductsPriceTarget.innerHTML = `$${this.totalSelectedProductsPriceValue.toFixed(2)}`
  }

  increaseQuantityByOne(event) {
    const { productId } = event.params
    const selectedProduct = Helpers.findById(this.selectedProducts, productId) // Changed
    const newSelectedProduct = {
      ...selectedProduct,
      quantity: selectedProduct.quantity + 1
    }
    this.selectedProducts = Helpers.mergeObjectArrays(this.selectedProducts, [newSelectedProduct]) // Changed
    this.renderSelectedProducts()
    this.totalSelectedProductsPriceValue = this.totalSelectedProductsPrice()
  }

  decreaseQuantityByOne(event) {
    const { productId } = event.params
    const selectedProduct = Helpers.findById(this.selectedProducts, productId) // Changed
    const newSelectedProduct = {
      ...selectedProduct,
      quantity: Math.max(0, selectedProduct.quantity - 1)
    }
    if (newSelectedProduct.quantity === 0) {
      this.selectedProducts = Helpers.subtractObjectArrays(this.selectedProducts, [newSelectedProduct]) // Changed
    } else {
      this.selectedProducts = Helpers.mergeObjectArrays(this.selectedProducts, [newSelectedProduct])    // Changed
    }
    this.selectedProductIdsValue = Helpers.pluck(this.selectedProducts, 'id') // Changed
    this.renderSelectedProducts()
    this.totalSelectedProductsPriceValue = this.totalSelectedProductsPrice()
  }

  openSetting(event) {
    Helpers.openModal({ // Changed
      html: `<div data-controller="${Retail_Pos_Branches_SettingController.identifier}"></div>`
    })
  }

  renderProducts() {
    this.productsTarget.innerHTML = `
      ${this.productIdsValue.map(productId => {
        const product = Helpers.findById(this.products, productId) // Changed
        return `
          <div
            class="flex flex-col bg-white dark:bg-gray-900 rounded-xl border-4 border-gray-200 open:border-blue-500 dark:border-gray-800 overflow-hidden cursor-pointer hover:shadow-xl hover:shadow-gray-500/50 transition-shadow"
            data-action="click->${this.identifier}#toggleOrder"
            data-${this.identifier}-product-id-param="${product.id}"
            data-${this.identifier}-target="product"
          >
            <div class="w-full h-64">
              <img class="w-full h-full object-cover" data-srcset="${product.image_urls[0]}">
            </div>
            <div class="p-4 flex-1 flex flex-col justify-between">
              <h3 class="font-semibold text-gray-800 dark:text-gray-100 mb-1">${product.name}</h3>
              <p class="text-sm text-indigo-600 font-medium">$${product.price}</p>
            </div>
          </div>
        `
      }).join('')}
    `
  }

  renderSelectedProducts() {
    this.selectedProductsTarget.innerHTML = this.selectedProducts.map(product => {
      return `
        <div class="flex items-center gap-4">
          <div class="w-16 h-16 rounded-lg bg-gray-100 dark:bg-gray-800 flex-shrink-0 bg-cover bg-center"
            style='background-image: url("${product.image_urls[0]}")'>
          </div>
          <div class="flex-1">
            <h3 class="font-medium text-gray-800 dark:text-gray-100 text-sm">${product.name}</h3>
            <p class="text-xs text-gray-500 dark:text-gray-400">$${product.price}</p>
          </div>
          <div class="flex items-center gap-2">
            <button
              class="w-7 h-7 rounded-md border border-gray-200 dark:border-gray-700 flex items-center justify-center hover:bg-gray-100 dark:hover:bg-gray-800 cursor-pointer"
              data-action="click->${this.identifier}#decreaseQuantityByOne"
              data-${this.identifier}-product-id-param="${product.id}"
            >-</button>
            <span class="font-medium w-4 text-center">${product.quantity}</span>
            <button
              class="w-7 h-7 rounded-md border border-gray-200 dark:border-gray-700 flex items-center justify-center hover:bg-gray-100 dark:hover:bg-gray-800 cursor-pointer"
              data-action="click->${this.identifier}#increaseQuantityByOne"
              data-${this.identifier}-product-id-param="${product.id}"
            >+</button>
          </div>
          <p class="font-semibold text-sm w-16 text-right">$${(product.price * product.quantity).toFixed(2)}</p>
        </div>
      `
    }).join('')
  }

  layoutHTML() {
    return `
      <div class="bg-gray-50 dark:bg-gray-950 text-gray-800 dark:text-gray-200">
        <div class="flex h-screen">
          <main class="flex-1 flex flex-col overflow-hidden">
            <div class="flex h-full">
              <div class="flex-1 flex flex-col p-6 overflow-y-auto">
                <header class="flex-shrink-0 flex items-center justify-between whitespace-nowrap mb-6">
                  <div class="flex items-center gap-4">
                    <button
                      data-action="click->${this.identifier}#openSetting"
                      class="flex cursor-pointer items-center justify-center overflow-hidden rounded-md h-10 w-10 border border-gray-200 dark:border-gray-700 hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-600 dark:text-gray-300">
                      <span class="material-symbols-outlined">menu</span>
                    </button>
                    <div class="flex flex-col">
                      <h1 class="text-gray-900 dark:text-white text-2xl font-bold leading-tight tracking-tight">POS Terminal
                      </h1>
                      <p class="text-gray-500 dark:text-gray-400 text-sm">Urban Trends</p>
                    </div>
                  </div>
                  <div class="flex items-center gap-4">
                    <label class="flex flex-col min-w-40 w-80">
                      <div class="flex w-full flex-1 items-stretch rounded-lg h-10">
                        <div
                          class="text-gray-500 flex bg-white dark:bg-gray-800 items-center justify-center pl-4 rounded-l-lg border border-r-0 border-gray-200 dark:border-gray-700">
                          <span class="material-symbols-outlined">search</span>
                        </div>
                        <input
                          class="flex w-full min-w-0 flex-1 resize-none overflow-hidden rounded-lg text-gray-900 dark:text-white focus:outline-none focus:ring-0 border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 h-full placeholder:text-gray-500 px-4 rounded-l-none border-l border text-base font-normal leading-normal"
                          placeholder="Search products..." value="" />
                      </div>
                    </label>
                    <div class="bg-center bg-no-repeat aspect-square bg-cover rounded-full size-10"
                      data-alt="User profile picture"
                      style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuBYk6_5wqHwhOUyfqIOzuw7uF6nG1B2aHcNfqPXgheh0TJNM9wgrKtU__k7USaOwDZLXPpvIrYvaXBnMbO7rmZHK15vMirHZqrK0UBZ18vJdiQZlmTrGe8wch8p3G7GXSetuz5njKmy7Hb6XGw18g0stonxhwtIcuuEqzZVHxbviNLuy4i_B8JHC1x_JlbUrZoIV2QQqyAprbH-jems99h8nqDZ6D6FBmq8JDrKIfaBYkl3mR0cYldl3c0gaNynjiRNKDKfaUcIKBc");'>
                    </div>
                  </div>
                </header>
                <nav class="flex-shrink-0 mb-6">
                  <div class="flex items-center gap-2 overflow-x-auto pb-2 -mb-2">
                    <button
                      class="px-4 py-2 rounded-full bg-indigo-600 text-white text-sm font-medium whitespace-nowrap">All</button>
                    <button
                      class="px-4 py-2 rounded-full bg-white dark:bg-gray-800 hover:bg-gray-100 dark:hover:bg-gray-700 border border-gray-200 dark:border-gray-700 text-gray-600 dark:text-gray-300 text-sm font-medium whitespace-nowrap">Apparel</button>
                    <button
                      class="px-4 py-2 rounded-full bg-white dark:bg-gray-800 hover:bg-gray-100 dark:hover:bg-gray-700 border border-gray-200 dark:border-gray-700 text-gray-600 dark:text-gray-300 text-sm font-medium whitespace-nowrap">Accessories</button>
                    <button
                      class="px-4 py-2 rounded-full bg-white dark:bg-gray-800 hover:bg-gray-100 dark:hover:bg-gray-700 border border-gray-200 dark:border-gray-700 text-gray-600 dark:text-gray-300 text-sm font-medium whitespace-nowrap">Footwear</button>
                    <button
                      class="px-4 py-2 rounded-full bg-white dark:bg-gray-800 hover:bg-gray-100 dark:hover:bg-gray-700 border border-gray-200 dark:border-gray-700 text-gray-600 dark:text-gray-300 text-sm font-medium whitespace-nowrap">Bags</button>
                    <button
                      class="px-4 py-2 rounded-full bg-white dark:bg-gray-800 hover:bg-gray-100 dark:hover:bg-gray-700 border border-gray-200 dark:border-gray-700 text-gray-600 dark:text-gray-300 text-sm font-medium whitespace-nowrap">Sale</button>
                  </div>
                </nav>
                
                <div class="w-ful bg-white flex flex-row justify-between items-center">
                  <div class="flex items-end gap-1 overflow-x-auto no-scrollbar -mb-px px-1">
                    <button
                      class="relative bg-white dark:bg-gray-900 text-blue-600 border border-gray-200 dark:border-gray-800 border-b-white dark:border-b-gray-900 rounded-t-lg px-4 py-2.5 text-md animate-bounce font-medium flex items-center gap-2 z-10 shadow-sm">
                      <span class="material-symbols-outlined text-lg">shopping_cart</span>
                      <span class="max-w-[120px] truncate">Sarah M.</span>
                      <span
                        class="ml-1 text-gray-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-full p-0.5 transition-colors cursor-pointer">
                        <span class="material-symbols-outlined text-base block">close</span>
                      </span>
                    </button>
                    <button
                      class="bg-transparent hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-500 dark:text-gray-400 border border-transparent hover:border-gray-200 dark:hover:border-gray-700 border-b-transparent rounded-t-lg px-4 py-2.5 text-sm font-medium flex items-center gap-2 mb-px transition-colors">
                      <span>Walk-in #3</span>
                    </button>
                    <button
                      class="ml-1 p-2 mb-1.5 text-gray-400 hover:text-blue-600 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-md transition-colors"
                      title="Add new order">
                      <span class="material-symbols-outlined text-xl">add</span>
                    </button>
                  </div>
                  <div class="relative w-full sm:w-72 mb-3">
                    <div class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
                      <span class="material-symbols-outlined text-gray-400">person_search</span>
                    </div>
                    <input
                      class="block w-full rounded-lg border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 pl-10 pr-4 py-2 text-sm focus:border-blue-600 focus:ring-blue-600 dark:text-white dark:placeholder-gray-400 transition-colors"
                      placeholder="Search or add customer..." type="text" />
                  </div>
                </div>

                <div
                  class="grid grid-cols-2 md:grid-cols-3 gap-6 bg-white dark:bg-gray-900 pt-2"
                  data-${this.identifier}-target="products"
                >
                </div>

              </div>
              <aside
                class="w-96 flex-shrink-0 bg-white dark:bg-gray-900 border-l border-gray-200 dark:border-gray-800 flex flex-col">

                <div class="p-6 border-b border-gray-200 dark:border-gray-800">
                  <h2 class="text-xl font-bold text-gray-900 dark:text-white">Current Order</h2>
                </div>

                <div class="flex-1 p-6 overflow-y-auto">
                  <div
                    data-${this.identifier}-target="selectedProducts"
                    class="flex flex-col gap-4"
                  >
                    
                  </div>
                </div>
                <div class="p-6 border-t border-gray-200 dark:border-gray-800">
                  <div class="flex flex-col gap-3 mb-6">
                    <div class="flex justify-between text-sm">
                      <span class="text-gray-600 dark:text-gray-300">Subtotal</span>
                      <span class="font-medium" data-${this.identifier}-target="totalSelectedProductsPrice">$0</span>
                    </div>
                    <div class="flex justify-between text-sm">
                      <span class="text-gray-600 dark:text-gray-300">Discount</span>
                      <button class="text-indigo-600 font-medium text-sm">Add Discount</button>
                    </div>
                    <div class="flex justify-between text-sm">
                      <span class="text-gray-600 dark:text-gray-300">Tax (5%)</span>
                      <span class="font-medium">$19.00</span>
                    </div>
                    <div class="flex justify-between text-lg font-bold mt-2">
                      <span>Total</span>
                      <span>$399.00</span>
                    </div>
                  </div>
                  <div class="flex flex-col gap-3">
                    <button
                      class="w-full bg-indigo-600 text-white font-semibold py-3 rounded-lg flex items-center justify-center gap-2 hover:bg-indigo-700 transition-colors">
                      <span class="material-symbols-outlined">payments</span>
                      Process Payment
                    </button>
                    <div class="grid grid-cols-2 gap-3">
                      <button
                        class="w-full bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-200 font-semibold py-3 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors">Hold</button>
                      <button
                        class="w-full bg-red-100 dark:bg-red-900/40 text-red-600 dark:text-red-400 font-semibold py-3 rounded-lg hover:bg-red-200 dark:hover:bg-red-900/60 transition-colors">Cancel</button>
                    </div>
                  </div>
                </div>
              </aside>
            </div>
          </main>
        </div>

      </div>
    `
  }
}
