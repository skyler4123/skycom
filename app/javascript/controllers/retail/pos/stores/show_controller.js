import Retail_Pos_LayoutController from "controllers/retail/pos/layout_controller"
import { pathname } from "controllers/helpers"

export default class Retail_Pos_Stores_ShowController extends Retail_Pos_LayoutController {
  static targets = ['products', "product", "selectedProduct", "selectedProducts", "totalSelectedProductsPrice"]
  static values = {
    products: { type: Array, default: [] },
    selectedProducts: { type: Array, default: [] },
    totalSelectedProductsPrice: { type: Number, default: 0 },
  }

  init() {
    this.initValues()
  }

  async initValues() {
    this.productsValue = await this.fetchProducts()
  }

  async fetchProducts() {
    const productsUrl = pathname() + '/products'
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

  productsValueChanged(value, previousValue) {
    this.productsTarget.innerHTML = this.productsHTML()
  }

  findProductById(id) {
    return this.productsValue.find(product => product.id === id)
  }

  findSelectedProductById(id) {
    return this.selectedProductsValue.find(product => product.id === id)
  }

  toggleOrder(event) {
    const { productId } = event.params
    const product = this.findProductById(productId)
    if (!product) return

    const index = this.selectedProductsValue.findIndex(p => p.id === product.id)

    if (index > -1) {
      // Product is already selected, so remove it.
      this.selectedProductsValue = [...this.selectedProductsValue.slice(0, index), ...this.selectedProductsValue.slice(index + 1)]
    } else {
      this.selectedProductsValue = [...this.selectedProductsValue, { ...product, quantity: 1 }]
    }
  }

  selectedProductsValueChanged(value, previousValue) {
    if (previousValue === undefined) return
    this.productTargets.forEach((productTarget) => {
      const productTargetId = productTarget.getAttribute(`data-${this.identifier}-product-id-param`)
      const product = this.findSelectedProductById(productTargetId)
      if (product) {
        productTarget.setAttribute('open', '')
      } else {
        productTarget.removeAttribute('open')
      }
    })
    this.selectedProductsTarget.innerHTML = this.selectedProductsHTML()
    this.totalSelectedProductsPriceValue = this.totalSelectedProductsPrice()
  }

  selectedProductsHTML() {
    return this.selectedProductsValue.map(product => {
      return this.selectedProductHTML(product)
    }).join('')
  }

  toggleOpenAttribute(element) {
    // add/remove attribute "open", not classList
    if (element.hasAttribute('open')) {
      element.removeAttribute('open')
    } else {
      element.setAttribute('open', '')
    }
  }

  totalSelectedProductsPrice() {
    return this.selectedProductsValue.reduce((total, product) => {
      return  (total + product.price * product.quantity)
    }, 0)
  }

  totalSelectedProductsPriceValueChanged(value, previousValue) {
    this.totalSelectedProductsPriceTarget.innerHTML = `$${value}`
  }

  increaseQuantityByOne(event) {
    const { productId } = event.params
    const product = this.findSelectedProductById(productId)
    if (!product) return

    const index = this.selectedProductsValue.findIndex(p => p.id === product.id)
    if (index > -1) {
      const updatedProducts = [...this.selectedProductsValue]
      const productToUpdate = { ...updatedProducts[index] }
      productToUpdate.quantity++
      updatedProducts[index] = productToUpdate
      this.selectedProductsValue = updatedProducts
    }
  }

  decreaseQuantityByOne(event) {
    const { productId } = event.params
    const product = this.findSelectedProductById(productId)
    if (!product) return

    const index = this.selectedProductsValue.findIndex(p => p.id === product.id)
    if (index > -1) {
      const product = this.selectedProductsValue[index]
      if (product.quantity - 1 <= 0) {
        this.selectedProductsValue = [...this.selectedProductsValue.slice(0, index), ...this.selectedProductsValue.slice(index + 1)]
      } else {
        const updatedProducts = [...this.selectedProductsValue]
        const productToUpdate = { ...product, quantity: product.quantity - 1 }
        updatedProducts[index] = productToUpdate
        this.selectedProductsValue = updatedProducts
      }
    }
  }

  productsHTML() {
    return `
      ${this.productsValue.map(product => {
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

  selectedProductHTML(product) {
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
        <p class="font-semibold text-sm w-16 text-right">$${product.price * product.quantity}</p>
      </div>
    `
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

                <div
                  class="grid grid-cols-2 md:grid-cols-3 gap-6"
                  data-${this.identifier}-target="products"
                >
                </div>

              </div>
              <aside
                class="w-96 flex-shrink-0 bg-white dark:bg-gray-900 border-l border-gray-200 dark:border-gray-800 flex flex-col">
                <div class="p-6 border-b border-gray-200 dark:border-gray-800">
                  <h2 class="text-xl font-bold text-gray-900 dark:text-white mb-4">Current Order</h2>
                  <div class="flex items-center gap-3">
                    <div class="flex-1 flex items-center bg-gray-100 dark:bg-gray-800 rounded-lg p-2">
                      <span class="material-symbols-outlined text-gray-500 mr-2">person</span>
                      <p class="text-sm font-medium">Guest</p>
                    </div>
                    <button
                      class="flex items-center justify-center h-10 w-10 bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 rounded-lg transition-colors">
                      <span class="material-symbols-outlined">person_add</span>
                    </button>
                  </div>
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
