import Retail_Management_LayoutController from "controllers/retail/management/layout_controller"

export default class Retail_Management_Inventories_IndexController extends Retail_Management_LayoutController {

  contentHTML() {
    return `
      <div class="p-8 overflow-y-auto">

        <div class="flex flex-col xl:flex-row items-start xl:items-center justify-between gap-4 mb-6">
          <div class="flex flex-wrap items-center gap-3 w-full xl:w-auto">
            <div class="relative min-w-[140px] flex-1 sm:flex-none">
              <select
                class="w-full pl-3 pr-8 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:ring-2 focus:ring-blue-500">
                <option>Category</option>
                <option>Electronics</option>
                <option>Furniture</option>
                <option>Sport & Fitness</option>
                <option>Accessories</option>
              </select>
            </div>
            <div class="relative min-w-[140px] flex-1 sm:flex-none">
              <select
                class="w-full pl-3 pr-8 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:ring-2 focus:ring-blue-500">
                <option>Stock Status</option>
                <option>In Stock</option>
                <option>Low Stock</option>
                <option>Out of Stock</option>
              </select>
            </div>
            <div class="relative min-w-[140px] flex-1 sm:flex-none">
              <select
                class="w-full pl-3 pr-8 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:ring-2 focus:ring-blue-500">
                <option>Branch/Location</option>
                <option>Main Warehouse</option>
                <option>Downtown Store</option>
                <option>Westside Branch</option>
              </select>
            </div>
            <div class="relative min-w-[140px] flex-1 sm:flex-none">
              <select
                class="w-full pl-3 pr-8 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:ring-2 focus:ring-blue-500">
                <option>Brand</option>
                <option>Urban Trends</option>
                <option>Nike</option>
                <option>Adidas</option>
                <option>Sony</option>
              </select>
            </div>
          </div>
          <button
            class="flex items-center justify-center gap-2 px-5 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm shadow-sm w-full sm:w-auto">
            <span class="material-symbols-outlined text-[20px]">add</span>
            Add New Item
          </button>
        </div>

        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr
                  class="text-sm text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium whitespace-nowrap">SKU/ID</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Product Name</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Category</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Current Stock</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Unit Price</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Stock Status</th>
                  <th class="py-4 px-6 font-medium text-right whitespace-nowrap">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-200 dark:divide-slate-800">
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300 font-mono">#INV-2045</td>
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-4">
                      <div
                        class="w-10 h-10 rounded-lg bg-slate-100 border border-slate-200 dark:border-slate-700 bg-cover bg-center">
                      </div>
                      <div>
                        <p class="font-medium text-slate-900 dark:text-white text-base">Premium Yoga Mat</p>
                        <p class="text-xs text-slate-500 mt-0.5">Urban Fitness</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm font-medium text-slate-900 dark:text-white">Sport & Fitness</td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">142</td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">$29.99</td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400 border border-green-200 dark:border-green-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-green-600 dark:bg-green-400"></span> In Stock
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">edit</span></button>
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">swap_vert</span></button>
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">history</span></button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300 font-mono">#INV-2046</td>
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-4">
                      <div
                        class="w-10 h-10 rounded-lg bg-slate-100 border border-slate-200 dark:border-slate-700 bg-cover bg-center">
                      </div>
                      <div>
                        <p class="font-medium text-slate-900 dark:text-white text-base">Ergonomic Office Chair</p>
                        <p class="text-xs text-slate-500 mt-0.5">Furniture Pro</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm font-medium text-slate-900 dark:text-white">Furniture</td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">8</td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">$249.50</td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400 border border-yellow-200 dark:border-yellow-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-yellow-600 dark:bg-yellow-400"></span> Low Stock
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">edit</span></button>
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">swap_vert</span></button>
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">history</span></button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300 font-mono">#INV-2047</td>
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-4">
                      <div
                        class="w-10 h-10 rounded-lg bg-slate-100 border border-slate-200 dark:border-slate-700 bg-cover bg-center">
                      </div>
                      <div>
                        <p class="font-medium text-slate-900 dark:text-white text-base">Running Sneakers v2</p>
                        <p class="text-xs text-slate-500 mt-0.5">Nike</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm font-medium text-slate-900 dark:text-white">Sport & Fitness</td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">0</td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">$119.00</td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-400 border border-slate-200 dark:border-slate-700">
                      <span class="w-1.5 h-1.5 rounded-full bg-slate-500 dark:bg-slate-400"></span> Out of Stock
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">edit</span></button>
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">swap_vert</span></button>
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">history</span></button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300 font-mono">#INV-2048</td>
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-4">
                      <div
                        class="w-10 h-10 rounded-lg bg-slate-100 border border-slate-200 dark:border-slate-700 bg-cover bg-center">
                      </div>
                      <div>
                        <p class="font-medium text-slate-900 dark:text-white text-base">Bluetooth Speaker</p>
                        <p class="text-xs text-slate-500 mt-0.5">Sony</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm font-medium text-slate-900 dark:text-white">Electronics</td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">56</td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">$79.00</td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400 border border-green-200 dark:border-green-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-green-600 dark:bg-green-400"></span> In Stock
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">edit</span></button>
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">swap_vert</span></button>
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">history</span></button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="p-4 border-t border-slate-200 dark:border-slate-800 flex items-center justify-between">
            <span class="text-sm text-slate-500 dark:text-slate-400">Showing 1 to 4 of 286 items</span>
            <div class="flex items-center gap-2">
              <button
                class="px-3 py-1 text-sm border border-slate-200 dark:border-slate-700 rounded-lg text-slate-500 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800 disabled:opacity-50"
                disabled="">Previous</button>
              <button
                class="px-3 py-1 text-sm border border-slate-200 dark:border-slate-700 rounded-lg text-slate-500 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800">Next</button>
            </div>
          </div>
        </div>
      </div>
    `
  }

}
