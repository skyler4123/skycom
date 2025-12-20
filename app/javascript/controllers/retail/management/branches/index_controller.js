import Retail_Management_LayoutController from "controllers/retail/management/layout_controller"

export default class Retail_Management_Branches_IndexController extends Retail_Management_LayoutController {

  contentHTML() {
    return `
      <div class="p-8 overflow-y-auto">
        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">
          <div
            class="p-6 border-b border-slate-200 dark:border-slate-800 flex flex-col xl:flex-row xl:items-center justify-between gap-4">
            <div class="flex flex-wrap items-center gap-3">
              <select
                class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:border-blue-600 focus:ring-blue-600 w-full sm:w-auto">
                <option selected="">Status: All</option>
                <option value="active">Active</option>
              </select>
              <select
                class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:border-blue-600 focus:ring-blue-600 w-full sm:w-auto">
                <option selected="">Region: All</option>
              </select>
              <button
                class="flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm whitespace-nowrap">
                <span class="material-symbols-outlined text-[20px]">add</span>
                Add New Branch
              </button>
            </div>
          </div>

          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr
                  class="text-sm text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Branch Name</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Address</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Contact Info</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Manager</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Status</th>
                  <th class="py-4 px-6 font-medium text-right whitespace-nowrap">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-200 dark:divide-slate-800">
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 rounded-lg bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-slate-500">
                        <span class="material-symbols-outlined">store</span>
                      </div>
                      <div>
                        <p class="font-medium text-slate-900 dark:text-white">Downtown Flagship</p>
                        <p class="text-xs text-slate-500">ID: #BR-001</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">123 Market St,<br />San Francisco, CA
                    94103</td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">
                    <div class="flex flex-col gap-1">
                      <div class="flex items-center gap-2">
                        <span class="material-symbols-outlined text-sm text-slate-400">call</span>
                        <span>(415) 555-0123</span>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-3">
                      <div class="bg-slate-200 rounded-full h-8 w-8"></div>
                      <span class="text-slate-900 dark:text-white">Olivia Martin</span>
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
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 rounded-lg bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-slate-500">
                        <span class="material-symbols-outlined">shopping_bag</span>
                      </div>
                      <div>
                        <p class="font-medium text-slate-900 dark:text-white">Westside Mall</p>
                        <p class="text-xs text-slate-500">ID: #BR-002</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">4500 Westfield Dr,<br />Los Angeles,
                    CA 90008</td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">
                    <div class="flex items-center gap-2">
                      <span class="material-symbols-outlined text-sm text-slate-400">call</span>
                      <span>(323) 555-0892</span>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-3">
                      <div class="bg-slate-200 rounded-full h-8 w-8"></div>
                      <span class="text-slate-900 dark:text-white">Liam Johnson</span>
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
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 rounded-lg bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-slate-500">
                        <span class="material-symbols-outlined">local_shipping</span>
                      </div>
                      <div>
                        <p class="font-medium text-slate-900 dark:text-white">North Distribution</p>
                        <p class="text-xs text-slate-500">ID: #BR-003</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">88 Industrial Pkwy,<br />Seattle, WA
                    98101</td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">
                    <div class="flex items-center gap-2">
                      <span class="material-symbols-outlined text-sm text-slate-400">call</span>
                      <span>(206) 555-9981</span>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-3">
                      <div class="bg-slate-200 rounded-full h-8 w-8"></div>
                      <span class="text-slate-900 dark:text-white">Noah Williams</span>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400 border border-yellow-200 dark:border-yellow-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-yellow-600"></span> Maintenance
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
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 rounded-lg bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-slate-500">
                        <span class="material-symbols-outlined">storefront</span>
                      </div>
                      <div>
                        <p class="font-medium text-slate-900 dark:text-white">Eastside Pop-up</p>
                        <p class="text-xs text-slate-500">ID: #BR-004</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">200 Broadway,<br />New York, NY 10038
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">
                    <div class="flex items-center gap-2">
                      <span class="material-symbols-outlined text-sm text-slate-400">call</span>
                      <span>(212) 555-4421</span>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-3">
                      <div class="bg-slate-200 rounded-full h-8 w-8"></div>
                      <span class="text-slate-900 dark:text-white">Emma Brown</span>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-400 border border-slate-200 dark:border-slate-700">
                      <span class="w-1.5 h-1.5 rounded-full bg-slate-500"></span> Inactive
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
            <span class="text-sm text-slate-500 dark:text-slate-400">Showing 1 to 4 of 12 branches</span>
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
