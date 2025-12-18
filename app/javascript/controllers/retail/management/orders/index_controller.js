import Retail_Management_LayoutController from "controllers/retail/management/layout_controller"

export default class Retail_Management_Orders_IndexController extends Retail_Management_LayoutController {

  contentHTML() {
    return `
      <div class="p-8 overflow-y-auto">
        <div class="flex flex-col xl:flex-row items-start xl:items-center justify-between gap-4 mb-6">
          <div class="flex flex-wrap items-center gap-3 w-full xl:w-auto">
            <div class="relative min-w-[140px] flex-1 sm:flex-none">
              <select
                class="w-full pl-3 pr-8 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:ring-2 focus:ring-blue-600 focus:border-blue-600">
                <option>Order Status</option>
                <option>Pending</option>
                <option>Processing</option>
                <option>Shipped</option>
                <option>Delivered</option>
                <option>Cancelled</option>
              </select>
            </div>
            <div class="relative min-w-[140px] flex-1 sm:flex-none">
              <select
                class="w-full pl-3 pr-8 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:ring-2 focus:ring-blue-600 focus:border-blue-600">
                <option>Payment Status</option>
                <option>Paid</option>
                <option>Unpaid</option>
                <option>Refunded</option>
                <option>Failed</option>
              </select>
            </div>
            <div class="relative min-w-[140px] flex-1 sm:flex-none">
              <select
                class="w-full pl-3 pr-8 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:ring-2 focus:ring-blue-600 focus:border-blue-600">
                <option>Date Range</option>
                <option>Today</option>
                <option>Last 7 Days</option>
                <option>Last 30 Days</option>
                <option>This Year</option>
              </select>
            </div>
            <div class="relative min-w-[140px] flex-1 sm:flex-none">
              <select
                class="w-full pl-3 pr-8 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:ring-2 focus:ring-blue-600 focus:border-blue-600">
                <option>Customer</option>
                <option>VIP Members</option>
                <option>New Customers</option>
                <option>Returning</option>
              </select>
            </div>
          </div>
          <button
            class="flex items-center justify-center gap-2 px-5 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm shadow-sm w-full sm:w-auto">
            <span class="material-symbols-outlined text-[20px]">add</span>
            Add New Order
          </button>
        </div>

        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr
                  class="text-sm text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Order ID</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Customer Name</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Order Date</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Total Amount</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Order Status</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Payment Status</th>
                  <th class="py-4 px-6 font-medium text-right whitespace-nowrap">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-200 dark:divide-slate-800">
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300 font-mono">#ORD-7782</td>
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-4">
                      <div
                        class="w-10 h-10 rounded-full bg-slate-100 border border-slate-200 dark:border-slate-700 bg-cover bg-center">
                      </div>
                      <div>
                        <p class="font-medium text-slate-900 dark:text-white text-base">Sarah Johnson</p>
                        <p class="text-xs text-slate-500 mt-0.5">sarah.j@example.com</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">
                    Oct 24, 2023 <span class="text-xs text-slate-400 block">10:45 AM</span>
                  </td>
                  <td class="py-4 px-6 text-sm font-medium text-slate-900 dark:text-white">$120.50</td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400 border border-yellow-200 dark:border-yellow-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-yellow-500 dark:bg-yellow-400"></span> Pending
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300">Paid</span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">visibility</span></button>
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">edit</span></button>
                      <button
                        class="p-2 text-slate-500 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">cancel</span></button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300 font-mono">#ORD-7783</td>
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-4">
                      <div
                        class="w-10 h-10 rounded-full bg-slate-100 border border-slate-200 dark:border-slate-700 bg-cover bg-center">
                      </div>
                      <div>
                        <p class="font-medium text-slate-900 dark:text-white text-base">Michael Chen</p>
                        <p class="text-xs text-slate-500 mt-0.5">m.chen@example.com</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">
                    Oct 23, 2023 <span class="text-xs text-slate-400 block">02:15 PM</span>
                  </td>
                  <td class="py-4 px-6 text-sm font-medium text-slate-900 dark:text-white">$450.00</td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400 border border-green-200 dark:border-green-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-green-600 dark:bg-green-400"></span> Delivered
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300">Paid</span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">visibility</span></button>
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">edit</span></button>
                      <button
                        class="p-2 text-slate-500 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">cancel</span></button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300 font-mono">#ORD-7784</td>
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-4">
                      <div
                        class="w-10 h-10 rounded-full bg-slate-100 border border-slate-200 dark:border-slate-700 bg-cover bg-center">
                      </div>
                      <div>
                        <p class="font-medium text-slate-900 dark:text-white text-base">Emily Rodriguez</p>
                        <p class="text-xs text-slate-500 mt-0.5">emily.r@example.com</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">
                    Oct 23, 2023 <span class="text-xs text-slate-400 block">09:30 AM</span>
                  </td>
                  <td class="py-4 px-6 text-sm font-medium text-slate-900 dark:text-white">$89.99</td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-400 border border-slate-200 dark:border-slate-700">
                      <span class="w-1.5 h-1.5 rounded-full bg-slate-500 dark:bg-slate-400"></span> Cancelled
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300">Refunded</span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">visibility</span></button>
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">edit</span></button>
                      <button
                        class="p-2 text-slate-500 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">cancel</span></button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300 font-mono">#ORD-7785</td>
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-4">
                      <div
                        class="w-10 h-10 rounded-full bg-slate-100 border border-slate-200 dark:border-slate-700 bg-cover bg-center">
                      </div>
                      <div>
                        <p class="font-medium text-slate-900 dark:text-white text-base">David Kim</p>
                        <p class="text-xs text-slate-500 mt-0.5">david.k@example.com</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">
                    Oct 22, 2023 <span class="text-xs text-slate-400 block">04:45 PM</span>
                  </td>
                  <td class="py-4 px-6 text-sm font-medium text-slate-900 dark:text-white">$210.25</td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400 border border-blue-200 dark:border-blue-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-blue-600 dark:bg-blue-400"></span> Shipped
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-orange-100 text-orange-800 dark:bg-orange-900/30 dark:text-orange-300">Unpaid</span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">visibility</span></button>
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">edit</span></button>
                      <button
                        class="p-2 text-slate-500 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">cancel</span></button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="p-4 border-t border-slate-200 dark:border-slate-800 flex items-center justify-between">
            <span class="text-sm text-slate-500 dark:text-slate-400">Showing 1 to 4 of 42 orders</span>
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
