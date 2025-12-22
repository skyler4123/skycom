import Retail_Management_LayoutController from "controllers/retail/management/layout_controller"

export default class Retail_Management_Payslips_IndexController extends Retail_Management_LayoutController {

  contentHTML() {
    return `
      <div class="p-8 overflow-y-auto">
        <div class="flex flex-wrap justify-between gap-3 mb-8">
          <div class="flex flex-col gap-1">
            <h1 class="text-gray-900 dark:text-white text-3xl font-bold leading-tight tracking-tight">Payslip Management
            </h1>
            <p class="text-gray-500 dark:text-gray-400 text-base font-normal leading-normal">Manage employee payslips,
              track payroll status, and handle monthly distributions.</p>
          </div>
        </div>
        <div class="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 flex flex-col">
          <div
            class="p-6 border-b border-gray-200 dark:border-gray-800 flex flex-col xl:flex-row xl:items-center justify-between gap-4">
            <h2 class="text-gray-900 dark:text-white text-xl font-bold leading-tight tracking-tight">All Payslips</h2>
            <div class="flex flex-wrap items-center gap-3">
              <div class="relative">
                <select
                  class="form-select pl-3 pr-10 py-2 text-sm border-gray-200 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-300 focus:border-blue-600 focus:ring-blue-600 w-full sm:w-auto">
                  <option selected="">Department: All</option>
                  <option value="engineering">Engineering</option>
                  <option value="sales">Sales</option>
                  <option value="marketing">Marketing</option>
                  <option value="hr">HR</option>
                </select>
              </div>
              <div class="relative">
                <select
                  class="form-select pl-3 pr-10 py-2 text-sm border-gray-200 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-300 focus:border-blue-600 focus:ring-blue-600 w-full sm:w-auto">
                  <option selected="">Period: This Month</option>
                  <option value="oct-2023">October 2023</option>
                  <option value="sep-2023">September 2023</option>
                  <option value="aug-2023">August 2023</option>
                </select>
              </div>
              <div class="relative">
                <select
                  class="form-select pl-3 pr-10 py-2 text-sm border-gray-200 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-300 focus:border-blue-600 focus:ring-blue-600 w-full sm:w-auto">
                  <option selected="">Status: All</option>
                  <option value="paid">Paid</option>
                  <option value="pending">Pending</option>
                  <option value="generated">Generated</option>
                </select>
              </div>
              <button
                class="flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm whitespace-nowrap">
                <span class="material-symbols-outlined text-[20px]">post_add</span>
                Generate New Payslips
              </button>
            </div>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr
                  class="text-sm text-gray-500 dark:text-gray-400 bg-gray-50 dark:bg-gray-800/50 border-b border-gray-200 dark:border-gray-700">
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Employee Name</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Employee ID</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Payment Period</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Net Pay</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Status</th>
                  <th class="py-4 px-6 font-medium text-right whitespace-nowrap">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-200 dark:divide-gray-800">
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 rounded-full bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center text-blue-600 dark:text-blue-400 overflow-hidden">
                        <span class="font-bold text-sm">SC</span>
                      </div>
                      <div>
                        <p class="font-medium text-gray-900 dark:text-white">Sarah Connor</p>
                        <p class="text-xs text-gray-500">Engineering Lead</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300 font-mono">
                    EMP-2049
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    <div class="flex items-center gap-2">
                      <span class="material-symbols-outlined text-lg text-gray-400">calendar_today</span>
                      Oct 2023
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm font-medium text-gray-900 dark:text-white">
                    $6,450.00
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400 border border-green-200 dark:border-green-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-green-600 dark:bg-green-400"></span>
                      Paid
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="View/Download PDF">
                        <span class="material-symbols-outlined text-[20px]">picture_as_pdf</span>
                      </button>
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Edit">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </button>
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Send to Employee">
                        <span class="material-symbols-outlined text-[20px]">send</span>
                      </button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 rounded-full bg-amber-100 dark:bg-amber-900/30 flex items-center justify-center text-amber-600 dark:text-amber-400">
                        <span class="font-bold text-sm">JD</span>
                      </div>
                      <div>
                        <p class="font-medium text-gray-900 dark:text-white">John Doe</p>
                        <p class="text-xs text-gray-500">Sales Representative</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300 font-mono">
                    EMP-3102
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    <div class="flex items-center gap-2">
                      <span class="material-symbols-outlined text-lg text-gray-400">calendar_today</span>
                      Oct 2023
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm font-medium text-gray-900 dark:text-white">
                    $3,200.00
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400 border border-amber-200 dark:border-amber-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-amber-600 dark:bg-amber-400"></span>
                      Pending
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="View/Download PDF">
                        <span class="material-symbols-outlined text-[20px]">picture_as_pdf</span>
                      </button>
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Edit">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </button>
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Send to Employee">
                        <span class="material-symbols-outlined text-[20px]">send</span>
                      </button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 rounded-full bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center text-purple-600 dark:text-purple-400">
                        <span class="font-bold text-sm">EW</span>
                      </div>
                      <div>
                        <p class="font-medium text-gray-900 dark:text-white">Emily Wong</p>
                        <p class="text-xs text-gray-500">UX Designer</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300 font-mono">
                    EMP-0885
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    <div class="flex items-center gap-2">
                      <span class="material-symbols-outlined text-lg text-gray-400">calendar_today</span>
                      Oct 2023
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm font-medium text-gray-900 dark:text-white">
                    $4,800.00
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400 border border-blue-200 dark:border-blue-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-blue-600 dark:bg-blue-400"></span>
                      Generated
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="View/Download PDF">
                        <span class="material-symbols-outlined text-[20px]">picture_as_pdf</span>
                      </button>
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Edit">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </button>
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Send to Employee">
                        <span class="material-symbols-outlined text-[20px]">send</span>
                      </button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 rounded-full bg-gray-100 dark:bg-gray-700 flex items-center justify-center text-gray-600 dark:text-gray-300">
                        <span class="material-symbols-outlined">person</span>
                      </div>
                      <div>
                        <p class="font-medium text-gray-900 dark:text-white">David Miller</p>
                        <p class="text-xs text-gray-500">Marketing Specialist</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300 font-mono">
                    EMP-1023
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    <div class="flex items-center gap-2">
                      <span class="material-symbols-outlined text-lg text-gray-400">calendar_today</span>
                      Sep 2023
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm font-medium text-gray-900 dark:text-white">
                    $3,500.00
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400 border border-green-200 dark:border-green-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-green-600 dark:bg-green-400"></span>
                      Paid
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="View/Download PDF">
                        <span class="material-symbols-outlined text-[20px]">picture_as_pdf</span>
                      </button>
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Edit">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </button>
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Send to Employee">
                        <span class="material-symbols-outlined text-[20px]">send</span>
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="p-4 border-t border-gray-200 dark:border-gray-800 flex items-center justify-between">
            <span class="text-sm text-gray-500 dark:text-gray-400">Showing 1 to 4 of 124 payslips</span>
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
