import Retail_Management_LayoutController from "controllers/retail/management/layout_controller"

export default class Retail_Management_Employees_IndexController extends Retail_Management_LayoutController {

  contentHTML() {
    return `
      <div class="p-8 overflow-y-auto">
        <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-6">
          <div class="flex flex-wrap items-center gap-3 w-full sm:w-auto">
            <div class="relative min-w-[140px]">
              <select
                class="form-select w-full pl-3 pr-8 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:ring-blue-600 focus:border-blue-600">
                <option>Department</option>
                <option>Sales</option>
                <option>Logistics</option>
                <option>Management</option>
                <option>Customer Support</option>
              </select>
            </div>
            <div class="relative min-w-[140px]">
              <select
                class="form-select w-full pl-3 pr-8 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:ring-blue-600 focus:border-blue-600">
                <option>Role</option>
                <option>Manager</option>
                <option>Associate</option>
                <option>Intern</option>
                <option>Supervisor</option>
              </select>
            </div>
            <div class="relative min-w-[140px]">
              <select
                class="form-select w-full pl-3 pr-8 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:ring-blue-600 focus:border-blue-600">
                <option>Employment Status</option>
                <option>Full-time</option>
                <option>Part-time</option>
                <option>Contract</option>
                <option>On Leave</option>
              </select>
            </div>
          </div>
          <button
            class="flex items-center justify-center gap-2 px-5 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm shadow-sm whitespace-nowrap">
            <span class="material-symbols-outlined text-[20px]">add</span>
            Add New Employee
          </button>
        </div>

        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr
                  class="text-sm text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Employee Name</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Employee ID</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Department</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Role</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Contact Information</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Status</th>
                  <th class="py-4 px-6 font-medium text-right whitespace-nowrap">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-200 dark:divide-slate-800">
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-4">
                      <div
                        class="w-10 h-10 rounded-full bg-slate-100 dark:bg-slate-800 bg-cover bg-center border border-slate-200 dark:border-slate-700">
                      </div>
                      <div>
                        <p class="font-medium text-slate-900 dark:text-white text-base">Sarah Johnson</p>
                        <p class="text-xs text-slate-500 mt-0.5">Joined Jan 2023</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300 font-mono">EMP-0012</td>
                  <td class="py-4 px-6 text-sm text-slate-900 dark:text-white">Sales</td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">Senior Associate</td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">sarah.j@skycom.com</td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400 border border-green-200 dark:border-green-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-green-600 dark:bg-green-400"></span> Active
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">edit</span></button>
                      <button
                        class="p-2 text-slate-500 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">delete</span></button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-4">
                      <div
                        class="w-10 h-10 rounded-full bg-slate-100 dark:bg-slate-800 bg-cover bg-center border border-slate-200 dark:border-slate-700">
                      </div>
                      <div>
                        <p class="font-medium text-slate-900 dark:text-white text-base">Michael Chen</p>
                        <p class="text-xs text-slate-500 mt-0.5">Joined Mar 2022</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300 font-mono">EMP-0045</td>
                  <td class="py-4 px-6 text-sm text-slate-900 dark:text-white">Management</td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">Store Manager</td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">michael.c@skycom.com</td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400 border border-green-200 dark:border-green-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-green-600 dark:bg-green-400"></span> Active
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">edit</span></button>
                      <button
                        class="p-2 text-slate-500 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">delete</span></button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-4">
                      <div
                        class="w-10 h-10 rounded-full bg-slate-100 dark:bg-slate-800 bg-cover bg-center border border-slate-200 dark:border-slate-700">
                      </div>
                      <div>
                        <p class="font-medium text-slate-900 dark:text-white text-base">Emily Rodriguez</p>
                        <p class="text-xs text-slate-500 mt-0.5">Joined Aug 2023</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300 font-mono">EMP-0089</td>
                  <td class="py-4 px-6 text-sm text-slate-900 dark:text-white">Customer Support</td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">Specialist</td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">emily.r@skycom.com</td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400 border border-yellow-200 dark:border-yellow-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-yellow-500 dark:bg-yellow-400"></span> On Leave
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">edit</span></button>
                      <button
                        class="p-2 text-slate-500 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">delete</span></button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-4">
                      <div
                        class="w-10 h-10 rounded-full bg-slate-100 dark:bg-slate-800 bg-cover bg-center border border-slate-200 dark:border-slate-700">
                      </div>
                      <div>
                        <p class="font-medium text-slate-900 dark:text-white text-base">David Kim</p>
                        <p class="text-xs text-slate-500 mt-0.5">Joined Nov 2023</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300 font-mono">EMP-0102</td>
                  <td class="py-4 px-6 text-sm text-slate-900 dark:text-white">Logistics</td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">Inventory Clerk</td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">david.k@skycom.com</td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-400 border border-slate-200 dark:border-slate-700">
                      <span class="w-1.5 h-1.5 rounded-full bg-slate-500 dark:bg-slate-400"></span> Probation
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">edit</span></button>
                      <button
                        class="p-2 text-slate-500 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"><span
                          class="material-symbols-outlined text-[20px]">delete</span></button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="p-4 border-t border-slate-200 dark:border-slate-800 flex items-center justify-between">
            <span class="text-sm text-slate-500 dark:text-slate-400">Showing 1 to 4 of 128 employees</span>
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
