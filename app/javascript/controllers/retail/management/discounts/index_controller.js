import Retail_Management_LayoutController from "controllers/retail/management/layout_controller"

export default class Retail_Management_Discounts_IndexController extends Retail_Management_LayoutController {

  contentHTML() {
    return `
      <div class="p-8 overflow-y-auto">
        <div class="flex flex-wrap justify-between gap-3 mb-8">
          <div class="flex flex-col gap-1">
            <h1 class="text-gray-900 dark:text-white text-3xl font-bold leading-tight tracking-tight">Discount
              Management</h1>
            <p class="text-gray-500 dark:text-gray-400 text-base font-normal leading-normal">Manage discounts and
              promotional offers across different verticals.</p>
          </div>
        </div>
        <div class="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 flex flex-col">
          <div
            class="p-6 border-b border-gray-200 dark:border-gray-800 flex flex-col xl:flex-row xl:items-center justify-between gap-4">
            <h2 class="text-gray-900 dark:text-white text-xl font-bold leading-tight tracking-tight">All Discounts</h2>
            <div class="flex flex-wrap items-center gap-3">
              <div class="relative">
                <select
                  class="form-select pl-3 pr-10 py-2 text-sm border-gray-200 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-300 focus:border-blue-600 focus:ring-blue-600 w-full sm:w-auto">
                  <option selected="">Discount Type: All</option>
                  <option value="percentage">Percentage</option>
                  <option value="fixed">Fixed Amount</option>
                  <option value="bogo">Buy One Get One</option>
                </select>
              </div>
              <div class="relative">
                <select
                  class="form-select pl-3 pr-10 py-2 text-sm border-gray-200 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-300 focus:border-blue-600 focus:ring-blue-600 w-full sm:w-auto">
                  <option selected="">Status: All</option>
                  <option value="active">Active</option>
                  <option value="scheduled">Scheduled</option>
                  <option value="expired">Expired</option>
                </select>
              </div>
              <div class="relative">
                <select
                  class="form-select pl-3 pr-10 py-2 text-sm border-gray-200 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-300 focus:border-blue-600 focus:ring-blue-600 w-full sm:w-auto">
                  <option selected="">Applicable Vertical: All</option>
                  <option value="retail">Retail</option>
                  <option value="food">Food Service</option>
                  <option value="education">Education</option>
                  <option value="hospital">Hospital</option>
                </select>
              </div>
              <button
                class="flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm whitespace-nowrap">
                <span class="material-symbols-outlined text-[20px]">add_circle</span>
                Create New Discount
              </button>
            </div>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr
                  class="text-sm text-gray-500 dark:text-gray-400 bg-gray-50 dark:bg-gray-800/50 border-b border-gray-200 dark:border-gray-700">
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Discount Name / Code</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Type</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Value</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Start / End Date</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Usage Count</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Status</th>
                  <th class="py-4 px-6 font-medium text-right whitespace-nowrap">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-200 dark:divide-gray-800">
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 rounded-lg bg-green-100 dark:bg-green-900/30 flex items-center justify-center text-green-600 dark:text-green-400">
                        <span class="material-symbols-outlined">percent</span>
                      </div>
                      <div>
                        <p class="font-medium text-gray-900 dark:text-white">Summer Sale</p>
                        <p class="text-xs text-gray-500 font-mono">SUMMER23</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    Percentage
                  </td>
                  <td class="py-4 px-6 text-sm font-medium text-gray-900 dark:text-white">
                    20% Off
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    <div class="flex items-center gap-2">
                      <span class="material-symbols-outlined text-lg text-gray-400">calendar_today</span>
                      Jun 01 - Aug 31
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    4,520
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400 border border-green-200 dark:border-green-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-green-600 dark:bg-green-400"></span>
                      Active
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="View Details">
                        <span class="material-symbols-outlined text-[20px]">visibility</span>
                      </button>
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Edit">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </button>
                      <button
                        class="p-2 text-gray-500 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                        title="Deactivate">
                        <span class="material-symbols-outlined text-[20px]">block</span>
                      </button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 rounded-lg bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center text-blue-600 dark:text-blue-400">
                        <span class="material-symbols-outlined">attach_money</span>
                      </div>
                      <div>
                        <p class="font-medium text-gray-900 dark:text-white">New User Bonus</p>
                        <p class="text-xs text-gray-500 font-mono">WELCOME10</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    Fixed Amount
                  </td>
                  <td class="py-4 px-6 text-sm font-medium text-gray-900 dark:text-white">
                    $10.00 Off
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    <div class="flex items-center gap-2">
                      <span class="material-symbols-outlined text-lg text-gray-400">calendar_today</span>
                      Jan 01 - Dec 31
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    856
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400 border border-blue-200 dark:border-blue-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-blue-600 dark:bg-blue-400"></span>
                      Active
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="View Details">
                        <span class="material-symbols-outlined text-[20px]">visibility</span>
                      </button>
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Edit">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </button>
                      <button
                        class="p-2 text-gray-500 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                        title="Deactivate">
                        <span class="material-symbols-outlined text-[20px]">block</span>
                      </button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 rounded-lg bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center text-purple-600 dark:text-purple-400">
                        <span class="material-symbols-outlined">shopping_bag</span>
                      </div>
                      <div>
                        <p class="font-medium text-gray-900 dark:text-white">Buy 1 Get 1 Coffee</p>
                        <p class="text-xs text-gray-500 font-mono">BOGOCOF</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    Buy One Get One
                  </td>
                  <td class="py-4 px-6 text-sm font-medium text-gray-900 dark:text-white">
                    Free Item
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    <div class="flex items-center gap-2">
                      <span class="material-symbols-outlined text-lg text-gray-400">calendar_today</span>
                      Sep 01 - Sep 30
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    2,100
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-400 border border-gray-200 dark:border-gray-700">
                      <span class="w-1.5 h-1.5 rounded-full bg-gray-500 dark:bg-gray-400"></span>
                      Expired
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="View Details">
                        <span class="material-symbols-outlined text-[20px]">visibility</span>
                      </button>
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Edit">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </button>
                      <button
                        class="p-2 text-gray-500 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                        title="Deactivate">
                        <span class="material-symbols-outlined text-[20px]">block</span>
                      </button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 rounded-lg bg-orange-100 dark:bg-orange-900/30 flex items-center justify-center text-orange-600 dark:text-orange-400">
                        <span class="material-symbols-outlined">stars</span>
                      </div>
                      <div>
                        <p class="font-medium text-gray-900 dark:text-white">Black Friday</p>
                        <p class="text-xs text-gray-500 font-mono">BLKFRIDAY</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    Percentage
                  </td>
                  <td class="py-4 px-6 text-sm font-medium text-gray-900 dark:text-white">
                    50% Off
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    <div class="flex items-center gap-2">
                      <span class="material-symbols-outlined text-lg text-gray-400">calendar_today</span>
                      Nov 24 - Nov 26
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    0
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400 border border-amber-200 dark:border-amber-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-amber-600 dark:bg-amber-400"></span>
                      Scheduled
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="View Details">
                        <span class="material-symbols-outlined text-[20px]">visibility</span>
                      </button>
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Edit">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </button>
                      <button
                        class="p-2 text-gray-500 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                        title="Deactivate">
                        <span class="material-symbols-outlined text-[20px]">block</span>
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="p-4 border-t border-gray-200 dark:border-gray-800 flex items-center justify-between">
            <span class="text-sm text-gray-500 dark:text-gray-400">Showing 1 to 4 of 48 discounts</span>
            <div class="flex items-center gap-2">
              <button
                class="px-3 py-1 text-sm border border-gray-200 dark:border-gray-700 rounded-lg text-gray-500 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-800 disabled:opacity-50"
                disabled="">Previous</button>
              <button
                class="px-3 py-1 text-sm border border-gray-200 dark:border-gray-700 rounded-lg text-gray-500 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-800">Next</button>
            </div>
          </div>
        </div>
      </div>
    `
  }

}
