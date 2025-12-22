import Retail_Management_LayoutController from "controllers/retail/management/layout_controller"

export default class Retail_Management_Products_IndexController extends Retail_Management_LayoutController {

  contentHTML() {
    return `
<div class="p-8 overflow-y-auto">

        <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-6">
          <div class="flex flex-wrap items-center gap-3 w-full sm:w-auto">
            <select
              class="pl-3 pr-8 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:ring-blue-600 focus:border-blue-600">
              <option>Category</option>
              <option>Apparel</option>
            </select>
            <select
              class="pl-3 pr-8 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:ring-blue-600 focus:border-blue-600">
              <option>Stock Level</option>
            </select>
          </div>
          <button
            class="flex items-center justify-center gap-2 px-5 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm shadow-sm whitespace-nowrap">
            <span class="material-symbols-outlined text-[20px]">add</span>
            Add New Product
          </button>
        </div>

        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr
                  class="text-sm text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Product Name</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">SKU</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Price</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Stock Quantity</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Status</th>
                  <th class="py-4 px-6 font-medium text-right whitespace-nowrap">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-200 dark:divide-slate-800">
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-4">
                      <div
                        class="w-12 h-12 rounded-lg bg-slate-100 dark:bg-slate-800 border border-slate-200 dark:border-slate-700">
                      </div>
                      <div>
                        <p class="font-medium text-slate-900 dark:text-white text-base">Classic Cotton T-Shirt</p>
                        <p class="text-xs text-slate-500 mt-0.5">Apparel • Unisex</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300 font-mono">TS-001-BLK</td>
                  <td class="py-4 px-6 text-sm font-medium text-slate-900 dark:text-white">$24.99</td>
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-2">
                      <span class="text-slate-900 dark:text-white font-medium">150</span>
                      <span class="text-slate-400 text-xs">units</span>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400 border border-green-200 dark:border-green-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-green-600"></span> Active
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg"><span
                          class="material-symbols-outlined text-[20px]">edit</span></button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-4">
                      <div
                        class="w-12 h-12 rounded-lg bg-slate-100 dark:bg-slate-800 border border-slate-200 dark:border-slate-700">
                      </div>
                      <div>
                        <p class="font-medium text-slate-900 dark:text-white text-base">Slim Fit Denim Jeans</p>
                        <p class="text-xs text-slate-500 mt-0.5">Apparel • Mens</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300 font-mono">JN-550-IND</td>
                  <td class="py-4 px-6 text-sm font-medium text-slate-900 dark:text-white">$59.50</td>
                  <td class="py-4 px-6 text-sm text-orange-600 dark:text-orange-400 font-medium">12 Low Stock</td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400 border border-green-200 dark:border-green-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-green-600"></span> Active
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg"><span
                          class="material-symbols-outlined text-[20px]">edit</span></button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-4">
                      <div
                        class="w-12 h-12 rounded-lg bg-slate-100 dark:bg-slate-800 border border-slate-200 dark:border-slate-700">
                      </div>
                      <div>
                        <p class="font-medium text-slate-900 dark:text-white text-base">Urban Leather Backpack</p>
                        <p class="text-xs text-slate-500 mt-0.5">Accessories • Bags</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300 font-mono">BP-LTH-BRN</td>
                  <td class="py-4 px-6 text-sm font-medium text-slate-900 dark:text-white">$120.00</td>
                  <td class="py-4 px-6 text-sm text-slate-900 dark:text-white font-medium">45 units</td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-400 border border-slate-200 dark:border-slate-700">
                      <span class="w-1.5 h-1.5 rounded-full bg-slate-500"></span> Draft
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg"><span
                          class="material-symbols-outlined text-[20px]">edit</span></button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-4">
                      <div
                        class="w-12 h-12 rounded-lg bg-slate-100 dark:bg-slate-800 border border-slate-200 dark:border-slate-700">
                      </div>
                      <div>
                        <p class="font-medium text-slate-900 dark:text-white text-base">Running Sneakers</p>
                        <p class="text-xs text-slate-500 mt-0.5">Footwear • Sport</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300 font-mono">SNK-RUN-002</td>
                  <td class="py-4 px-6 text-sm font-medium text-slate-900 dark:text-white">$85.00</td>
                  <td class="py-4 px-6 text-sm text-red-600 dark:text-red-400 font-medium">0 Out of Stock</td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400 border border-red-200 dark:border-red-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-red-600"></span> Archived
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg"><span
                          class="material-symbols-outlined text-[20px]">edit</span></button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <div class="p-4 border-t border-slate-200 dark:border-slate-800 flex items-center justify-between">
            <span class="text-sm text-slate-500 dark:text-slate-400">Showing 1 to 4 of 32 products</span>
            <div class="flex items-center gap-2">
              <button
                class="px-3 py-1 text-sm border border-slate-200 dark:border-slate-700 rounded-lg text-slate-400 cursor-not-allowed"
                disabled>Previous</button>
              <button
                class="px-3 py-1 text-sm border border-slate-200 dark:border-slate-700 rounded-lg text-slate-500 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors">Next</button>
            </div>
          </div>
        </div>
      </div>
    `
  }

}
