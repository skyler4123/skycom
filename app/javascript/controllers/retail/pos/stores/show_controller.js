import Retail_Pos_LayoutController from "controllers/retail/pos/layout_controller"
import { pathname } from "controllers/helpers"

export default class Retail_Pos_Stores_ShowController extends Retail_Pos_LayoutController {
  static targets = ['products', "product"]
  static values = {
    products: { type: Array, default: [] }
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

  productsHTML() {
    return `
      ${this.productsValue.map(product => {
        return `
          <div
            class="flex flex-col bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 overflow-hidden cursor-pointer hover:shadow-lg transition-shadow">
            <div class="w-full h-40 bg-cover bg-center"
              style='background-image: url("${product.image_urls[0]}")'>
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

  contentHTML() {
    return `
      <div
        class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-6"
        data-${this.identifier}-target="products"
      >
      </div>
    `
  }

  // sampleProduct() {
  //   return   {
  //     "id": "33666f3b-f19b-4c99-b133-94cb198ee921",
  //     "company_group_id": "95e04362-d4ef-4bd9-9798-e6b5468b0629",
  //     "company_id": "44d6c533-30a7-4963-9f78-527018576bf4",
  //     "brand_id": "692698fb-ec4f-4b69-b1a7-aca2d960f761",
  //     "education_type": null,
  //     "hospital_type": null,
  //     "hotel_type": null,
  //     "restaurant_type": null,
  //     "retail_type": null,
  //     "name": "Aerodynamic Granite Shirt 1",
  //     "description": "A quality product from Store 1",
  //     "code": null,
  //     "sku": null,
  //     "barcode": null,
  //     "upc": null,
  //     "ean": null,
  //     "manufacturer_code": null,
  //     "serial_number": null,
  //     "batch_number": null,
  //     "expiration_date": null,
  //     "status": "draft",
  //     "business_type": "physical",
  //     "discarded_at": null,
  //     "created_at": "2025-12-03T15:31:20.918Z",
  //     "updated_at": "2025-12-03T15:31:20.918Z"
  //   }
  // }

}
