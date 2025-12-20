import Retail_Management_LayoutController from "controllers/retail/management/layout_controller"

export default class Retail_Management_Schedules_IndexController extends Retail_Management_LayoutController {

  contentHTML() {
    return `
      <div class="p-8 overflow-y-auto">
        <div class="flex flex-wrap justify-between gap-3 mb-8">
          <div class="flex flex-col gap-1">
            <h1 class="text-slate-900 dark:text-white text-3xl font-bold leading-tight tracking-tight">Schedule
              Management</h1>
            <p class="text-slate-500 dark:text-slate-400 text-base font-normal leading-normal">Manage schedules for
              employees, appointments, classes, and shifts.</p>
          </div>
        </div>

        <div
          class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col mb-8">
          <div class="p-6 border-b border-slate-200 dark:border-slate-800 flex items-center justify-between">
            <h2 class="text-slate-900 dark:text-white text-xl font-bold leading-tight">Calendar Overview</h2>
            <div class="flex gap-2">
              <button class="p-2 text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg">
                <span class="material-symbols-outlined">chevron_left</span>
              </button>
              <span class="flex items-center px-2 font-medium text-slate-700 dark:text-slate-300">Oct 23 - Oct 29,
                2023</span>
              <button class="p-2 text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg">
                <span class="material-symbols-outlined">chevron_right</span>
              </button>
            </div>
          </div>
          <div class="p-6 overflow-x-auto">
            <div class="min-w-[800px] grid grid-cols-7 gap-4">
              <div class="text-center mb-2"><span class="block text-sm font-medium text-slate-500">Mon 23</span></div>
              <div class="text-center mb-2"><span class="block text-sm font-medium text-slate-900 dark:text-white">Tue
                  24</span></div>
              <div class="text-center mb-2"><span class="block text-sm font-medium text-slate-500">Wed 25</span></div>
              <div class="text-center mb-2"><span class="block text-sm font-medium text-slate-500">Thu 26</span></div>
              <div class="text-center mb-2"><span class="block text-sm font-medium text-slate-500">Fri 27</span></div>
              <div class="text-center mb-2"><span class="block text-sm font-medium text-slate-500">Sat 28</span></div>
              <div class="text-center mb-2"><span class="block text-sm font-medium text-slate-500">Sun 29</span></div>

              <div
                class="h-48 bg-slate-50 dark:bg-slate-800/50 rounded-lg p-2 flex flex-col gap-2 border border-slate-100 dark:border-slate-700">
              </div>
              <div
                class="h-48 bg-slate-50 dark:bg-slate-800/50 rounded-lg p-2 flex flex-col gap-2 border border-slate-100 dark:border-slate-700">
                <div
                  class="p-2 rounded bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200 text-xs font-medium border-l-4 border-blue-500 cursor-pointer hover:opacity-80">
                  09:00 AM - Team Sync</div>
                <div
                  class="p-2 rounded bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200 text-xs font-medium border-l-4 border-green-500 cursor-pointer hover:opacity-80">
                  02:00 PM - Interview</div>
              </div>
              <div
                class="h-48 bg-slate-50 dark:bg-slate-800/50 rounded-lg p-2 flex flex-col gap-2 border border-slate-100 dark:border-slate-700">
                <div
                  class="p-2 rounded bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200 text-xs font-medium border-l-4 border-purple-500 cursor-pointer hover:opacity-80">
                  11:00 AM - Client Mtg</div>
              </div>
              <div
                class="h-48 bg-slate-50 dark:bg-slate-800/50 rounded-lg p-2 flex flex-col gap-2 border border-slate-100 dark:border-slate-700">
                <div
                  class="p-2 rounded bg-amber-100 text-amber-800 dark:bg-amber-900 dark:text-amber-200 text-xs font-medium border-l-4 border-amber-500 cursor-pointer hover:opacity-80">
                  01:00 PM - Lunch Shift</div>
              </div>
              <div
                class="h-48 bg-slate-50 dark:bg-slate-800/50 rounded-lg p-2 flex flex-col gap-2 border border-slate-100 dark:border-slate-700">
                <div
                  class="p-2 rounded bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200 text-xs font-medium border-l-4 border-blue-500 cursor-pointer hover:opacity-80">
                  09:30 AM - Review</div>
              </div>
              <div
                class="h-48 bg-slate-50 dark:bg-slate-800/50 rounded-lg p-2 flex flex-col gap-2 border border-slate-100 dark:border-slate-700">
              </div>
              <div
                class="h-48 bg-slate-50 dark:bg-slate-800/50 rounded-lg p-2 flex flex-col gap-2 border border-slate-100 dark:border-slate-700">
              </div>
            </div>
          </div>
        </div>

        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">
          <div
            class="p-6 border-b border-slate-200 dark:border-slate-800 flex flex-col xl:flex-row xl:items-center justify-between gap-4">
            <h2 class="text-slate-900 dark:text-white text-xl font-bold leading-tight tracking-tight">All Schedules</h2>
            <div class="flex flex-wrap items-center gap-3">
              <select
                class="px-3 pr-10 py-2 text-sm border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:border-blue-600 focus:ring-blue-600 w-full sm:w-auto">
                <option selected="">Employee: All</option>
                <option value="sarah">Sarah Connor</option>
                <option value="john">John Doe</option>
              </select>
              <select
                class="px-3 pr-10 py-2 text-sm border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:border-blue-600 focus:ring-blue-600 w-full sm:w-auto">
                <option selected="">Type: All Types</option>
                <option value="daily">Daily</option>
              </select>
              <select
                class="px-3 pr-10 py-2 text-sm border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:border-blue-600 focus:ring-blue-600 w-full sm:w-auto">
                <option selected="">Status: All</option>
                <option value="active">Active</option>
              </select>
              <select
                class="px-3 pr-10 py-2 text-sm border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:border-blue-600 focus:ring-blue-600 w-full sm:w-auto">
                <option selected="">Date: This Week</option>
                <option value="next_week">Next Week</option>
              </select>
              <button
                class="flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm whitespace-nowrap">
                <span class="material-symbols-outlined text-[20px]">add_circle</span>
                Create New Schedule
              </button>
            </div>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr
                  class="text-sm text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Schedule Name / ID</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Type</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Associated Resource</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Start & End Time</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Status</th>
                  <th class="py-4 px-6 font-medium text-right whitespace-nowrap">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-200 dark:divide-slate-800">
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex flex-col">
                      <span class="font-medium text-slate-900 dark:text-white">Engineering Weekly Sync</span>
                      <span class="text-xs text-slate-500 font-mono">SCH-2023-001</span>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-blue-50 text-blue-700 dark:bg-blue-900/20 dark:text-blue-400 border border-blue-100 dark:border-blue-800">Weekly</span>
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-8 h-8 rounded-full bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center text-blue-600 dark:text-blue-400 text-xs font-bold">
                        SC</div>
                      <p class="font-medium text-slate-900 dark:text-white text-sm">Sarah Connor</p>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">
                    <div class="flex flex-col gap-1">
                      <span class="text-sm">Oct 24, 2023</span>
                      <span class="text-xs text-slate-500">09:00 AM - 10:00 AM</span>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400 border border-green-200 dark:border-green-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-green-600 dark:bg-green-400"></span> Active
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg"><span
                          class="material-symbols-outlined text-[20px]">visibility</span></button>
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg"><span
                          class="material-symbols-outlined text-[20px]">edit</span></button>
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg"><span
                          class="material-symbols-outlined text-[20px]">archive</span></button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="p-4 border-t border-slate-200 dark:border-slate-800 flex items-center justify-between">
            <span class="text-sm text-slate-500 dark:text-slate-400">Showing 1 to 4 of 32 schedules</span>
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
