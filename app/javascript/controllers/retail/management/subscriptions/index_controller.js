import Retail_Management_LayoutController from "controllers/retail/management/layout_controller"

export default class Retail_Management_Subscriptions_IndexController extends Retail_Management_LayoutController {

  contentHTML() {
    return `
      <div class="p-8 flex flex-col flex-1 overflow-hidden">
        <div class="flex-shrink-0 flex flex-wrap justify-between gap-3 mb-8">
          <div class="flex flex-col gap-1">
            <h1 class="text-gray-900 dark:text-white text-3xl font-bold leading-tight tracking-tight">Company & Branch
              Subscriptions</h1>
            <p class="text-gray-500 dark:text-gray-400 text-base font-normal leading-normal">Manage billing cycles,
              plans, and statuses for all registered entities.</p>
          </div>
        </div>

        <div
          class="flex-1 bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 shadow-sm flex flex-col overflow-hidden">
          <div
            class="p-4 border-b border-gray-200 dark:border-gray-800 flex flex-wrap gap-4 items-center justify-between">
            <div class="flex flex-wrap items-center gap-4">
              <div class="relative">
                <span
                  class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500 dark:text-gray-400 material-symbols-outlined text-[20px]">filter_alt</span>
                <select
                  class="pl-10 pr-8 py-2 bg-gray-50 dark:bg-gray-800 border-gray-200 dark:border-gray-700 rounded-lg text-sm text-gray-700 dark:text-gray-200 focus:ring-blue-600 focus:border-blue-600">
                  <option>All Statuses</option>
                  <option>Active</option>
                  <option>Expired</option>
                  <option>Trial</option>
                </select>
              </div>
              <div class="relative">
                <span
                  class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500 dark:text-gray-400 material-symbols-outlined text-[20px]">layers</span>
                <select
                  class="pl-10 pr-8 py-2 bg-gray-50 dark:bg-gray-800 border-gray-200 dark:border-gray-700 rounded-lg text-sm text-gray-700 dark:text-gray-200 focus:ring-blue-600 focus:border-blue-600">
                  <option>All Plans</option>
                  <option>Retail Starter</option>
                  <option>Enterprise Gold</option>
                  <option>Education Plus</option>
                  <option>Hospitality Pro</option>
                </select>
              </div>
              <div class="relative">
                <span
                  class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500 dark:text-gray-400 material-symbols-outlined text-[20px]">domain</span>
                <select
                  class="pl-10 pr-8 py-2 bg-gray-50 dark:bg-gray-800 border-gray-200 dark:border-gray-700 rounded-lg text-sm text-gray-700 dark:text-gray-200 focus:ring-blue-600 focus:border-blue-600">
                  <option>All Entities</option>
                  <option>Companies Only</option>
                  <option>Branches Only</option>
                </select>
              </div>
            </div>
            <div>
              <button
                class="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors text-sm font-medium shadow-md">
                <span class="material-symbols-outlined text-[20px]">add_circle</span>
                Add New Subscription
              </button>
            </div>
          </div>

          <div class="overflow-x-auto custom-scrollbar flex-1">
            <table class="w-full text-left border-collapse">
              <thead class="bg-gray-50 dark:bg-gray-800/50 sticky top-0 z-10">
                <tr>
                  <th class="p-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider w-1/4">
                    Associated Entity</th>
                  <th class="p-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Plan
                    Name</th>
                  <th class="p-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Start
                    Date</th>
                  <th class="p-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">End
                    Date</th>
                  <th class="p-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Status
                  </th>
                  <th
                    class="p-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider text-right">
                    Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-200 dark:divide-gray-800">
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors group">
                  <td class="p-4">
                    <div class="flex items-center gap-3">
                      <div class="bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 p-2 rounded-lg">
                        <span class="material-symbols-outlined">business</span>
                      </div>
                      <div class="flex flex-col">
                        <span class="text-sm font-medium text-gray-900 dark:text-white">Skycom Retail HQ</span>
                        <span class="text-xs text-gray-500">Company</span>
                      </div>
                    </div>
                  </td>
                  <td class="p-4 text-sm text-gray-700 dark:text-gray-300">Enterprise Gold</td>
                  <td class="p-4 text-sm text-gray-500 dark:text-gray-400">Jan 01, 2023</td>
                  <td class="p-4 text-sm text-gray-500 dark:text-gray-400">Dec 31, 2023</td>
                  <td class="p-4">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400 border border-green-200 dark:border-green-800">
                      <div class="w-1.5 h-1.5 rounded-full bg-green-500"></div> Active
                    </span>
                  </td>
                  <td class="p-4 text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-1.5 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="View Details">
                        <span class="material-symbols-outlined text-[20px]">visibility</span>
                      </button>
                      <button
                        class="p-1.5 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Edit Subscription">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </button>
                      <button
                        class="p-1.5 text-gray-500 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                        title="Cancel Subscription">
                        <span class="material-symbols-outlined text-[20px]">cancel</span>
                      </button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors group">
                  <td class="p-4">
                    <div class="flex items-center gap-3">
                      <div
                        class="bg-purple-100 dark:bg-purple-900/30 text-purple-600 dark:text-purple-400 p-2 rounded-lg">
                        <span class="material-symbols-outlined">store</span>
                      </div>
                      <div class="flex flex-col">
                        <span class="text-sm font-medium text-gray-900 dark:text-white">Downtown Outlet</span>
                        <span class="text-xs text-gray-500">Branch (Skycom Retail)</span>
                      </div>
                    </div>
                  </td>
                  <td class="p-4 text-sm text-gray-700 dark:text-gray-300">Retail Starter</td>
                  <td class="p-4 text-sm text-gray-500 dark:text-gray-400">Oct 01, 2023</td>
                  <td class="p-4 text-sm text-gray-500 dark:text-gray-400">Nov 01, 2023</td>
                  <td class="p-4">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400 border border-blue-200 dark:border-blue-800">
                      <div class="w-1.5 h-1.5 rounded-full bg-blue-500"></div> Trial
                    </span>
                  </td>
                  <td class="p-4 text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-1.5 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="View Details">
                        <span class="material-symbols-outlined text-[20px]">visibility</span>
                      </button>
                      <button
                        class="p-1.5 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Edit Subscription">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </button>
                      <button
                        class="p-1.5 text-gray-500 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                        title="Cancel Subscription">
                        <span class="material-symbols-outlined text-[20px]">cancel</span>
                      </button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors group">
                  <td class="p-4">
                    <div class="flex items-center gap-3">
                      <div class="bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 p-2 rounded-lg">
                        <span class="material-symbols-outlined">business</span>
                      </div>
                      <div class="flex flex-col">
                        <span class="text-sm font-medium text-gray-900 dark:text-white">Northwest Educare</span>
                        <span class="text-xs text-gray-500">Company</span>
                      </div>
                    </div>
                  </td>
                  <td class="p-4 text-sm text-gray-700 dark:text-gray-300">Education Plus</td>
                  <td class="p-4 text-sm text-gray-500 dark:text-gray-400">Sep 15, 2022</td>
                  <td class="p-4 text-sm text-gray-500 dark:text-gray-400">Sep 15, 2023</td>
                  <td class="p-4">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400 border border-red-200 dark:border-red-800">
                      <div class="w-1.5 h-1.5 rounded-full bg-red-500"></div> Expired
                    </span>
                  </td>
                  <td class="p-4 text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-1.5 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="View Details">
                        <span class="material-symbols-outlined text-[20px]">visibility</span>
                      </button>
                      <button
                        class="p-1.5 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Renew Subscription">
                        <span class="material-symbols-outlined text-[20px]">autorenew</span>
                      </button>
                      <button
                        class="p-1.5 text-gray-500 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                        title="Remove">
                        <span class="material-symbols-outlined text-[20px]">delete</span>
                      </button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors group">
                  <td class="p-4">
                    <div class="flex items-center gap-3">
                      <div
                        class="bg-purple-100 dark:bg-purple-900/30 text-purple-600 dark:text-purple-400 p-2 rounded-lg">
                        <span class="material-symbols-outlined">store</span>
                      </div>
                      <div class="flex flex-col">
                        <span class="text-sm font-medium text-gray-900 dark:text-white">City Center Spa</span>
                        <span class="text-xs text-gray-500">Branch (Urban Wellness)</span>
                      </div>
                    </div>
                  </td>
                  <td class="p-4 text-sm text-gray-700 dark:text-gray-300">Service Pro</td>
                  <td class="p-4 text-sm text-gray-500 dark:text-gray-400">Mar 10, 2023</td>
                  <td class="p-4 text-sm text-gray-500 dark:text-gray-400">Mar 09, 2024</td>
                  <td class="p-4">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400 border border-green-200 dark:border-green-800">
                      <div class="w-1.5 h-1.5 rounded-full bg-green-500"></div> Active
                    </span>
                  </td>
                  <td class="p-4 text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-1.5 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="View Details">
                        <span class="material-symbols-outlined text-[20px]">visibility</span>
                      </button>
                      <button
                        class="p-1.5 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Edit Subscription">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </button>
                      <button
                        class="p-1.5 text-gray-500 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                        title="Cancel Subscription">
                        <span class="material-symbols-outlined text-[20px]">cancel</span>
                      </button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors group">
                  <td class="p-4">
                    <div class="flex items-center gap-3">
                      <div class="bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 p-2 rounded-lg">
                        <span class="material-symbols-outlined">business</span>
                      </div>
                      <div class="flex flex-col">
                        <span class="text-sm font-medium text-gray-900 dark:text-white">Metro Hospital</span>
                        <span class="text-xs text-gray-500">Company</span>
                      </div>
                    </div>
                  </td>
                  <td class="p-4 text-sm text-gray-700 dark:text-gray-300">Health Connect</td>
                  <td class="p-4 text-sm text-gray-500 dark:text-gray-400">Aug 01, 2023</td>
                  <td class="p-4 text-sm text-gray-500 dark:text-gray-400">Jul 31, 2024</td>
                  <td class="p-4">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400 border border-green-200 dark:border-green-800">
                      <div class="w-1.5 h-1.5 rounded-full bg-green-500"></div> Active
                    </span>
                  </td>
                  <td class="p-4 text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-1.5 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="View Details">
                        <span class="material-symbols-outlined text-[20px]">visibility</span>
                      </button>
                      <button
                        class="p-1.5 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Edit Subscription">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </button>
                      <button
                        class="p-1.5 text-gray-500 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                        title="Cancel Subscription">
                        <span class="material-symbols-outlined text-[20px]">cancel</span>
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="p-4 border-t border-gray-200 dark:border-gray-800 flex items-center justify-between">
            <span class="text-sm text-gray-500 dark:text-gray-400">Showing 1-5 of 86 subscriptions</span>
            <div class="flex gap-2">
              <button
                class="p-2 rounded-lg border border-gray-200 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-800 text-gray-500 disabled:opacity-50">
                <span class="material-symbols-outlined text-[18px]">chevron_left</span>
              </button>
              <button
                class="p-2 rounded-lg border border-gray-200 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-800 text-gray-500">
                <span class="material-symbols-outlined text-[18px]">chevron_right</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    `
  }

}
