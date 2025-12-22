import Retail_Management_LayoutController from "controllers/retail/management/layout_controller"

export default class Retail_Management_Reports_IndexController extends Retail_Management_LayoutController {

  contentHTML() {
    return `
      <div class="p-8 flex flex-col flex-1 overflow-hidden">
        <div class="flex-shrink-0 flex flex-wrap justify-between gap-3 mb-8">
          <div class="flex flex-col gap-1">
            <h1 class="text-slate-900 dark:text-white text-3xl font-bold tracking-tight">Reported Issues</h1>
            <p class="text-slate-500 dark:text-slate-400 text-base">Track and resolve reported problems across all
              verticals.</p>
          </div>
          <button
            class="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors text-sm font-medium shadow-md">
            <span class="material-symbols-outlined text-[20px]">add</span> Report Issue
          </button>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6 mb-8">
          <div
            class="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col gap-4 shadow-sm">
            <div class="flex justify-between items-start">
              <div>
                <p class="text-sm font-medium text-slate-500">Total Issues</p>
                <h3 class="text-2xl font-bold">142</h3>
              </div>
              <div class="p-2 bg-blue-50 dark:bg-blue-900/20 text-blue-600 rounded-lg"><span
                  class="material-symbols-outlined">bug_report</span></div>
            </div>
          </div>
          <div
            class="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col gap-4 shadow-sm">
            <div class="flex justify-between items-start">
              <div>
                <p class="text-sm font-medium text-slate-500">Critical</p>
                <h3 class="text-2xl font-bold">8</h3>
              </div>
              <div class="p-2 bg-red-50 dark:bg-red-900/20 text-red-600 rounded-lg"><span
                  class="material-symbols-outlined">dangerous</span></div>
            </div>
          </div>
          <div
            class="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col gap-4 shadow-sm">
            <div class="flex justify-between items-start">
              <div>
                <p class="text-sm font-medium text-slate-500">Unassigned</p>
                <h3 class="text-2xl font-bold">15</h3>
              </div>
              <div class="p-2 bg-amber-50 dark:bg-amber-900/20 text-amber-600 rounded-lg"><span
                  class="material-symbols-outlined">person_search</span></div>
            </div>
          </div>
          <div
            class="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col gap-4 shadow-sm">
            <div class="flex justify-between items-start">
              <div>
                <p class="text-sm font-medium text-slate-500">Resolved Today</p>
                <h3 class="text-2xl font-bold">24</h3>
              </div>
              <div class="p-2 bg-green-50 dark:bg-green-900/20 text-green-600 rounded-lg"><span
                  class="material-symbols-outlined">check_circle</span></div>
            </div>
          </div>
        </div>

        <div
          class="flex-1 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex flex-col overflow-hidden">
          <div
            class="p-4 border-b border-slate-200 dark:border-slate-800 flex flex-wrap gap-4 items-center justify-between">
            <div class="flex flex-wrap items-center gap-4">
              <div class="relative">
                <span
                  class="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 material-symbols-outlined text-[20px]">filter_list</span>
                <select
                  class="pl-10 pr-8 py-2 bg-slate-50 dark:bg-slate-800 border border-slate-300 dark:border-slate-700 rounded-lg text-sm focus:ring-blue-500 focus:border-blue-500">
                  <option>All Priorities</option>
                  <option>Critical</option>
                  <option>High</option>
                </select>
              </div>
              <div class="relative">
                <span
                  class="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 material-symbols-outlined text-[20px]">info</span>
                <select
                  class="pl-10 pr-8 py-2 bg-slate-50 dark:bg-slate-800 border border-slate-300 dark:border-slate-700 rounded-lg text-sm focus:ring-blue-500 focus:border-blue-500">
                  <option>All Status</option>
                  <option>Open</option>
                  <option>Fixed</option>
                </select>
              </div>
            </div>
            <button
              class="flex items-center gap-2 px-4 py-2 border border-slate-300 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800 rounded-lg text-sm font-medium">
              <span class="material-symbols-outlined text-[20px]">download</span> Export Report
            </button>
          </div>

          <div class="overflow-x-auto custom-scrollbar flex-1">
            <table class="w-full text-left border-collapse">
              <thead class="bg-slate-50 dark:bg-slate-800/50 sticky top-0 z-10">
                <tr>
                  <th class="p-4 text-xs font-semibold text-slate-500 uppercase tracking-wider">Issue ID</th>
                  <th class="p-4 text-xs font-semibold text-slate-500 uppercase tracking-wider w-1/3">Subject</th>
                  <th class="p-4 text-xs font-semibold text-slate-500 uppercase tracking-wider">Vertical</th>
                  <th class="p-4 text-xs font-semibold text-slate-500 uppercase tracking-wider">Priority</th>
                  <th class="p-4 text-xs font-semibold text-slate-500 uppercase tracking-wider">Status</th>
                  <th class="p-4 text-xs font-semibold text-slate-500 uppercase tracking-wider text-right">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-200 dark:divide-slate-800">
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 group">
                  <td class="p-4 text-sm font-medium text-blue-600">#ISS-2049</td>
                  <td class="p-4 text-sm font-medium text-slate-900 dark:text-white">POS Terminal sync failure during
                    checkout</td>
                  <td class="p-4 text-sm text-slate-600 dark:text-slate-300">Retail</td>
                  <td class="p-4"><span
                      class="px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800 border border-red-200">Critical</span>
                  </td>
                  <td class="p-4"><span
                      class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 border border-blue-200">
                      <div class="w-1.5 h-1.5 rounded-full bg-blue-500"></div>Open
                    </span></td>
                  <td class="p-4 text-right"><button class="p-1.5 text-slate-400 hover:text-blue-600"><span
                        class="material-symbols-outlined text-[20px]">visibility</span></button></td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 group">
                  <td class="p-4 text-sm font-medium text-blue-600">#ISS-2048</td>
                  <td class="p-4 text-sm font-medium text-slate-900 dark:text-white">Student portal login timeout issue
                  </td>
                  <td class="p-4 text-sm text-slate-600 dark:text-slate-300">Education</td>
                  <td class="p-4"><span
                      class="px-2.5 py-0.5 rounded-full text-xs font-medium bg-orange-100 text-orange-800 border border-orange-200">High</span>
                  </td>
                  <td class="p-4"><span
                      class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium bg-amber-100 text-amber-800 border border-amber-200">
                      <div class="w-1.5 h-1.5 rounded-full bg-amber-500"></div>Investigating
                    </span></td>
                  <td class="p-4 text-right"><button class="p-1.5 text-slate-400 hover:text-blue-600"><span
                        class="material-symbols-outlined text-[20px]">visibility</span></button></td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 group">
                  <td class="p-4 text-sm font-medium text-blue-600">#ISS-2045</td>
                  <td class="p-4 text-sm font-medium text-slate-900 dark:text-white">Inventory count mismatch in
                    Warehouse B</td>
                  <td class="p-4 text-sm text-slate-600 dark:text-slate-300">Logistics</td>
                  <td class="p-4"><span
                      class="px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 border border-blue-200">Medium</span>
                  </td>
                  <td class="p-4"><span
                      class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 border border-green-200">
                      <div class="w-1.5 h-1.5 rounded-full bg-green-500"></div>Fixed
                    </span></td>
                  <td class="p-4 text-right"><button class="p-1.5 text-slate-400 hover:text-blue-600"><span
                        class="material-symbols-outlined text-[20px]">visibility</span></button></td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 group">
                  <td class="p-4 text-sm font-medium text-blue-600">#ISS-2042</td>
                  <td class="p-4 text-sm font-medium text-slate-900 dark:text-white">Update tax rates for Q4</td>
                  <td class="p-4 text-sm text-slate-600 dark:text-slate-300">Finance</td>
                  <td class="p-4"><span
                      class="px-2.5 py-0.5 rounded-full text-xs font-medium bg-slate-100 text-slate-800 border border-slate-200">Low</span>
                  </td>
                  <td class="p-4"><span
                      class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 border border-blue-200">
                      <div class="w-1.5 h-1.5 rounded-full bg-blue-500"></div>Open
                    </span></td>
                  <td class="p-4 text-right"><button class="p-1.5 text-slate-400 hover:text-blue-600"><span
                        class="material-symbols-outlined text-[20px]">visibility</span></button></td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 group">
                  <td class="p-4 text-sm font-medium text-blue-600">#ISS-2039</td>
                  <td class="p-4 text-sm font-medium text-slate-900 dark:text-white">Patient record duplication error
                  </td>
                  <td class="p-4 text-sm text-slate-600 dark:text-slate-300">Healthcare</td>
                  <td class="p-4"><span
                      class="px-2.5 py-0.5 rounded-full text-xs font-medium bg-orange-100 text-orange-800 border border-orange-200">High</span>
                  </td>
                  <td class="p-4"><span
                      class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 border border-green-200">
                      <div class="w-1.5 h-1.5 rounded-full bg-green-500"></div>Fixed
                    </span></td>
                  <td class="p-4 text-right"><button class="p-1.5 text-slate-400 hover:text-blue-600"><span
                        class="material-symbols-outlined text-[20px]">visibility</span></button></td>
                </tr>
              </tbody>
            </table>
          </div>

          <div class="p-4 border-t border-slate-200 dark:border-slate-800 flex items-center justify-between">
            <span class="text-sm text-slate-500">Showing 1-5 of 142 issues</span>
            <div class="flex gap-2">
              <button
                class="p-2 rounded-lg border border-slate-300 dark:border-slate-700 hover:bg-slate-50 text-slate-500">
                <span class="material-symbols-outlined text-[18px]">chevron_left</span>
              </button>
              <button
                class="p-2 rounded-lg border border-slate-300 dark:border-slate-700 hover:bg-slate-50 text-slate-500">
                <span class="material-symbols-outlined text-[18px]">chevron_right</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    `
  }

}
