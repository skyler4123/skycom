import Retail_Management_LayoutController from "controllers/retail/management/layout_controller"

export default class Retail_Management_Payments_IndexController extends Retail_Management_LayoutController {

  contentHTML() {
    return `
      <div class="p-8 overflow-y-auto">


        <div class="flex flex-col xl:flex-row items-start xl:items-center justify-between gap-4 mb-6">
          <div class="flex flex-wrap items-center gap-3 w-full xl:w-auto">
            <div class="relative min-w-[160px] flex-1 sm:flex-none">
              <select
                class="w-full pl-3 pr-8 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:ring-2 focus:ring-blue-500">
                <option>Payment Method</option>
                <option>Credit Card</option>
                <option>Cash</option>
                <option>Bank Transfer</option>
                <option>Digital Wallet</option>
              </select>
            </div>
            <div class="relative min-w-[160px] flex-1 sm:flex-none">
              <select
                class="w-full pl-3 pr-8 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:ring-2 focus:ring-blue-500">
                <option>Payment Status</option>
                <option>Completed</option>
                <option>Failed</option>
                <option>Refunded</option>
                <option>Pending</option>
              </select>
            </div>
            <div class="relative min-w-[160px] flex-1 sm:flex-none">
              <select
                class="w-full pl-3 pr-8 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:ring-2 focus:ring-blue-500">
                <option>Date Range</option>
                <option>Today</option>
                <option>Yesterday</option>
                <option>This Week</option>
                <option>Last Week</option>
                <option>This Month</option>
              </select>
            </div>
            <div class="relative min-w-[160px] flex-1 sm:flex-none">
              <select
                class="w-full pl-3 pr-8 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:ring-2 focus:ring-blue-500">
                <option>Customer</option>
                <option>All Customers</option>
                <option>VIP Members</option>
                <option>New Customers</option>
                <option>Recurring</option>
              </select>
            </div>
          </div>
          <button
            class="flex items-center justify-center gap-2 px-5 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm shadow-sm w-full sm:w-auto">
            <span class="material-symbols-outlined text-[20px]">add</span>
            Process New Payment
          </button>
        </div>

        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr
                  class="text-sm text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Transaction ID</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Customer Name</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Date</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Amount</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Payment Method</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Status</th>
                  <th class="py-4 px-6 font-medium text-right whitespace-nowrap">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-200 dark:divide-slate-800">
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300 font-mono">#TRX-2024-852</td>
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
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">Oct 24, 2023</td>
                  <td class="py-4 px-6 text-sm font-medium text-slate-900 dark:text-white">$1,250.00</td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">
                    <div class="flex items-center gap-2">
                      <span class="material-symbols-outlined text-slate-400 text-[18px]">credit_card</span>
                      <span>Credit Card</span>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400 border border-green-200 dark:border-green-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-green-500 dark:bg-green-400"></span> Completed
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">receipt_long</span></button>
                      <button
                        class="p-2 text-slate-500 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">undo</span></button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300 font-mono">#TRX-2024-853</td>
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
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">Oct 25, 2023</td>
                  <td class="py-4 px-6 text-sm font-medium text-slate-900 dark:text-white">$450.00</td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">
                    <div class="flex items-center gap-2">
                      <span class="material-symbols-outlined text-slate-400 text-[18px]">account_balance</span>
                      <span>Bank Transfer</span>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400 border border-yellow-200 dark:border-yellow-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-yellow-600 dark:bg-yellow-400"></span> Pending
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">receipt_long</span></button>
                      <button
                        class="p-2 text-slate-500 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">undo</span></button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300 font-mono">#TRX-2024-854</td>
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
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">Oct 26, 2023</td>
                  <td class="py-4 px-6 text-sm font-medium text-slate-900 dark:text-white">$2,100.00</td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">
                    <div class="flex items-center gap-2">
                      <span class="material-symbols-outlined text-slate-400 text-[18px]">credit_card</span>
                      <span>Credit Card</span>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400 border border-red-200 dark:border-red-700">
                      <span class="w-1.5 h-1.5 rounded-full bg-red-500 dark:bg-red-400"></span> Failed
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">receipt_long</span></button>
                      <button
                        class="p-2 text-slate-500 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">undo</span></button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300 font-mono">#TRX-2024-855</td>
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
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">Oct 27, 2023</td>
                  <td class="py-4 px-6 text-sm font-medium text-slate-900 dark:text-white">$150.00</td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">
                    <div class="flex items-center gap-2">
                      <span class="material-symbols-outlined text-slate-400 text-[18px]">payments</span>
                      <span>Cash</span>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-400 border border-slate-200 dark:border-slate-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-slate-600 dark:bg-slate-400"></span> Refunded
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">receipt_long</span></button>
                      <button
                        class="p-2 text-slate-500 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">undo</span></button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="p-4 border-t border-slate-200 dark:border-slate-800 flex items-center justify-between">
            <span class="text-sm text-slate-500 dark:text-slate-400">Showing 1 to 4 of 324 payments</span>
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
