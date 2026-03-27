import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Products_IndexController extends Companies_LayoutController {
  static targets = ["productsList"]

  async connect() {
    super.connect()
    const response = await fetchJson();
    this.products = response.products || []
    this.renderContent()
  }
  
  contentHTML() {
    return `
      <div class="p-8 overflow-y-auto">
        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">

          <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-6">
            <div class="flex flex-wrap items-center gap-3 w-full sm:w-auto">
              <select class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:border-blue-600 focus:ring-blue-600 w-full sm:w-auto">
                <option selected="">Category: All</option>
                <option value="apparel">Apparel</option>
              </select>
              <select class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:border-blue-600 focus:ring-blue-600 w-full sm:w-auto">
                <option selected="">Stock Level: All</option>
                <option value="in_stock">In Stock</option>
                <option value="low_stock">Low Stock</option>
                <option value="out_of_stock">Out of Stock</option>
              </select>
            </div>
            <button 
              data-action="click->${this.identifier}#openAddProductModal"
              class="flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm whitespace-nowrap">
              <span class="material-symbols-outlined text-[20px]">add</span>
              Add New Product
            </button>
          </div>

          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Product Name</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">SKU</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Price</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Stock Quantity</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Status</th>
                  <th class="py-4 px-6 font-medium text-right whitespace-nowrap">Actions</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="productsList" class="divide-y divide-slate-200 dark:divide-slate-800">
                ${this.productsHTML()}
              </tbody>
            </table>
          </div>

          <div class="p-4 border-t border-slate-200 dark:border-slate-800 flex items-center justify-between">
            <span class="text-sm text-slate-500 dark:text-slate-400">Showing ${this.products.length} products</span>
            <div class="flex items-center gap-2">
              <button class="px-3 py-1 text-sm border border-slate-200 dark:border-slate-700 rounded-lg text-slate-400 cursor-not-allowed" disabled>Previous</button>
              <button class="px-3 py-1 text-sm border border-slate-200 dark:border-slate-700 rounded-lg text-slate-500 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors">Next</button>
            </div>
          </div>
        </div>
      </div>
    `
  }

  productsHTML() {
    if (this.products.length === 0) {
      return `<tr><td colspan="6" class="text-center py-4 text-slate-500">No products found</td></tr>`
    }
    return this.products.map(product => `
      <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
        <td class="py-4 px-6 text-sm">
          <div class="flex items-center gap-4">
            <div class="w-12 h-12 rounded-lg bg-slate-100 dark:bg-slate-800 border border-slate-200 dark:border-slate-700">
            </div>
            <div>
              <p 
                 class="font-medium text-slate-900 dark:text-white cursor-pointer hover:underline"
                 data-action="click->${this.identifier}#showProductDetails"
              >
                ${product.name}
              </p>
              <p class="text-xs text-slate-500">Category • Type</p>
            </div>
          </div>
        </td>
        <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300 font-mono">${product.sku || 'N/A'}</td>
        <td class="py-4 px-6 text-sm font-medium text-slate-900 dark:text-white">${product.price ? `$${product.price}` : 'N/A'}</td>
        <td class="py-4 px-6 text-sm">
          <div class="flex items-center gap-2">
            <span class="text-slate-900 dark:text-white font-medium">${product.stock_quantity || 0}</span>
            <span class="text-slate-400 text-xs">units</span>
          </div>
        </td>
        <td class="py-4 px-6 text-sm">
          ${Helpers.statusBadge(product.lifecycle_status)}
        </td>
        <td class="py-4 px-6 text-sm text-right">
          <div class="flex items-center justify-end gap-2">
            <button class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg"><span
                class="material-symbols-outlined text-[20px]">edit</span></button>
          </div>
        </td>
      </tr>
    `).join('')
  }
}
