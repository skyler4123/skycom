import Retail_Management_LayoutController from "controllers/retail/management/layout_controller"

export default class Retail_Management_Attendances_IndexController extends Retail_Management_LayoutController {

  contentHTML() {
    return `
      <div class="p-8 overflow-y-auto">
        <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-6">
          <div class="flex flex-wrap items-center gap-3 w-full sm:w-auto">
            <div class="relative min-w-[140px]">
              <select
                class="w-full pl-3 pr-8 py-2 text-sm border border-gray-200 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-300 focus:ring-2 focus:ring-blue-500 outline-none">
                <option>Department</option>
                <option>Sales</option>
                <option>Logistics</option>
                <option>Management</option>
                <option>Customer Support</option>
              </select>
            </div>
            <div class="relative min-w-[140px]">
              <select
                class="w-full pl-3 pr-8 py-2 text-sm border border-gray-200 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-300 focus:ring-2 focus:ring-blue-500 outline-none">
                <option>Date</option>
                <option>Today</option>
                <option>Yesterday</option>
                <option>Last 7 Days</option>
                <option>Last Month</option>
              </select>
            </div>
            <div class="relative min-w-[140px]">
              <select
                class="w-full pl-3 pr-8 py-2 text-sm border border-gray-200 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-300 focus:ring-2 focus:ring-blue-500 outline-none">
                <option>Status</option>
                <option>Present</option>
                <option>Absent</option>
                <option>Late</option>
                <option>On Leave</option>
              </select>
            </div>
          </div>
          <button
            class="flex items-center justify-center gap-2 px-5 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm shadow-sm whitespace-nowrap">
            <span class="material-symbols-outlined text-[20px]">add_circle</span> Record Attendance
          </button>
        </div>

        <div class="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 flex flex-col">
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr
                  class="text-sm text-gray-500 dark:text-gray-400 bg-gray-50 dark:bg-gray-800/50 border-b border-gray-200 dark:border-gray-700">
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Employee Name</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Employee ID</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Date</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Check-in Time</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Check-out Time</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Total Hours</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Status</th>
                  <th class="py-4 px-6 font-medium text-right whitespace-nowrap">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-200 dark:divide-gray-800">
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-4">
                      <div
                        class="w-10 h-10 rounded-full bg-gray-100 dark:bg-gray-800 bg-cover bg-center border border-gray-200 dark:border-gray-700">
                      </div>
                      <div>
                        <p class="font-medium text-gray-900 dark:text-white text-base">Sarah Johnson</p>
                        <p class="text-xs text-gray-500 mt-0.5">Sales Department</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300 font-mono">EMP-0012</td>
                  <td class="py-4 px-6 text-sm text-gray-900 dark:text-white">Oct 24, 2023</td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">08:55 AM</td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">05:00 PM</td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300 font-medium">8h 05m</td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400 border border-green-200 dark:border-green-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-green-600 dark:bg-green-400"></span> Present
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/30 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">edit</span></button>
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/30 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">visibility</span></button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-4">
                      <div
                        class="w-10 h-10 rounded-full bg-gray-100 dark:bg-gray-800 bg-cover bg-center border border-gray-200 dark:border-gray-700">
                      </div>
                      <div>
                        <p class="font-medium text-gray-900 dark:text-white text-base">Michael Chen</p>
                        <p class="text-xs text-gray-500 mt-0.5">Management</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300 font-mono">EMP-0045</td>
                  <td class="py-4 px-6 text-sm text-gray-900 dark:text-white">Oct 24, 2023</td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">09:15 AM</td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">06:00 PM</td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300 font-medium">8h 45m</td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400 border border-yellow-200 dark:border-yellow-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-yellow-500 dark:bg-yellow-400"></span> Late
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/30 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">edit</span></button>
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/30 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">visibility</span></button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-4">
                      <div
                        class="w-10 h-10 rounded-full bg-gray-100 dark:bg-gray-800 bg-cover bg-center border border-gray-200 dark:border-gray-700">
                      </div>
                      <div>
                        <p class="font-medium text-gray-900 dark:text-white text-base">Emily Rodriguez</p>
                        <p class="text-xs text-gray-500 mt-0.5">Support Team</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300 font-mono">EMP-0089</td>
                  <td class="py-4 px-6 text-sm text-gray-900 dark:text-white">Oct 24, 2023</td>
                  <td class="py-4 px-6 text-sm text-gray-400 dark:text-gray-500">--:--</td>
                  <td class="py-4 px-6 text-sm text-gray-400 dark:text-gray-500">--:--</td>
                  <td class="py-4 px-6 text-sm text-gray-400 dark:text-gray-500 font-medium">0h 00m</td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400 border border-blue-200 dark:border-blue-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-blue-500 dark:bg-blue-400"></span> On Leave
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/30 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">edit</span></button>
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/30 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">visibility</span></button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-4">
                      <div
                        class="w-10 h-10 rounded-full bg-gray-100 dark:bg-gray-800 bg-cover bg-center border border-gray-200 dark:border-gray-700">
                      </div>
                      <div>
                        <p class="font-medium text-gray-900 dark:text-white text-base">David Kim</p>
                        <p class="text-xs text-gray-500 mt-0.5">Logistics</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300 font-mono">EMP-0102</td>
                  <td class="py-4 px-6 text-sm text-gray-900 dark:text-white">Oct 24, 2023</td>
                  <td class="py-4 px-6 text-sm text-gray-400 dark:text-gray-500">--:--</td>
                  <td class="py-4 px-6 text-sm text-gray-400 dark:text-gray-500">--:--</td>
                  <td class="py-4 px-6 text-sm text-gray-400 dark:text-gray-500 font-medium">0h 00m</td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400 border border-red-200 dark:border-red-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-red-500 dark:bg-red-400"></span> Absent
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/30 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">edit</span></button>
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/30 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">visibility</span></button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="p-4 border-t border-gray-200 dark:border-gray-800 flex items-center justify-between">
            <span class="text-sm text-gray-500 dark:text-gray-400">Showing 1 to 4 of 128 records</span>
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
