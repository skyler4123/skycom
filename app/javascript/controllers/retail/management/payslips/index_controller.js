import Retail_Management_LayoutController from "controllers/retail/management/layout_controller"

export default class Retail_Management_Payslips_IndexController extends Retail_Management_LayoutController {

  contentHTML() {
    return `
      <div class="p-8 h-full flex flex-col">
        <div class="flex flex-wrap justify-between items-end gap-4 mb-8">
          <div class="flex flex-col gap-1">
            <h1 class="text-slate-900 dark:text-white text-3xl font-bold tracking-tight">Role & Policy Management</h1>
            <p class="text-slate-500 dark:text-slate-400 text-base">Configure RBAC rules and permissions.</p>
          </div>
          <div class="flex items-center gap-3">
            <div class="relative">
              <span class="absolute inset-y-0 left-0 flex items-center pl-3 text-slate-400">
                <span class="material-symbols-outlined text-[20px]">search</span>
              </span>
              <input
                class="pl-10 pr-4 py-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 text-sm focus:ring-blue-600 focus:border-blue-600 w-64"
                placeholder="Filter roles..." type="text" />
            </div>
            <button
              class="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 transition-colors shadow-sm">
              <span class="material-symbols-outlined text-[18px]">add</span> Add New Role
            </button>
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-4 gap-6 flex-1 min-h-0">
          <div
            class="lg:col-span-1 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col overflow-hidden shadow-sm">
            <div class="p-4 border-b border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-800/50">
              <h2 class="text-xs font-bold uppercase text-slate-500 tracking-wider">Defined Roles</h2>
            </div>
            <div class="overflow-y-auto flex-1 p-2 space-y-1">
              <button
                class="w-full flex items-center justify-between p-3 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-100 dark:border-blue-800/50 text-blue-600">
                <div class="flex items-center gap-3">
                  <span class="material-symbols-outlined">shield_person</span>
                  <div class="text-left">
                    <p class="font-medium text-sm">Manager</p>
                    <p class="text-xs opacity-70">14 Active Users</p>
                  </div>
                </div>
                <span class="material-symbols-outlined text-[18px]">chevron_right</span>
              </button>
              <button
                class="w-full flex items-center justify-between p-3 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-700 dark:text-slate-300">
                <div class="flex items-center gap-3"><span
                    class="material-symbols-outlined text-slate-400">admin_panel_settings</span>
                  <p class="text-sm">Super Admin</p>
                </div>
              </button>
              <button
                class="w-full flex items-center justify-between p-3 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-700 dark:text-slate-300">
                <div class="flex items-center gap-3"><span
                    class="material-symbols-outlined text-slate-400">storefront</span>
                  <p class="text-sm">Seller / POS</p>
                </div>
              </button>
              <button
                class="w-full flex items-center justify-between p-3 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-700 dark:text-slate-300">
                <div class="flex items-center gap-3"><span
                    class="material-symbols-outlined text-slate-400">school</span>
                  <p class="text-sm">Teacher</p>
                </div>
              </button>
              <button
                class="w-full flex items-center justify-between p-3 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-700 dark:text-slate-300">
                <div class="flex items-center gap-3"><span
                    class="material-symbols-outlined text-slate-400">support_agent</span>
                  <p class="text-sm">Support Staff</p>
                </div>
              </button>
              <button
                class="w-full flex items-center justify-between p-3 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-700 dark:text-slate-300">
                <div class="flex items-center gap-3"><span
                    class="material-symbols-outlined text-slate-400">inventory</span>
                  <p class="text-sm">Inventory Clerk</p>
                </div>
              </button>
            </div>
          </div>

          <div
            class="lg:col-span-3 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col overflow-hidden shadow-sm">
            <div
              class="p-4 border-b border-slate-200 dark:border-slate-800 flex justify-between items-center bg-slate-50 dark:bg-slate-800/50">
              <div class="flex items-center gap-2">
                <h2 class="text-base font-bold text-slate-900 dark:text-white">Permissions for: <span
                    class="text-blue-600">Manager</span></h2>
              </div>
              <div class="flex gap-3">
                <button class="text-slate-500 hover:text-slate-700 text-sm font-medium">Reset Default</button>
                <button
                  class="px-4 py-1.5 bg-slate-900 hover:bg-slate-800 dark:bg-white dark:hover:bg-slate-200 text-white dark:text-slate-900 text-sm font-medium rounded-lg">Save
                  Changes</button>
              </div>
            </div>
            <div class="flex-1 overflow-auto">
              <table class="w-full text-left border-collapse">
                <thead class="bg-slate-50 dark:bg-slate-800 border-b border-slate-200 dark:border-slate-800">
                  <tr>
                    <th class="p-4 text-slate-500 text-xs uppercase w-1/3">Resource Name</th>
                    <th class="p-4 text-slate-500 text-xs uppercase text-center">Create</th>
                    <th class="p-4 text-slate-500 text-xs uppercase text-center">Read</th>
                    <th class="p-4 text-slate-500 text-xs uppercase text-center">Update</th>
                    <th class="p-4 text-slate-500 text-xs uppercase text-center">Delete</th>
                    <th class="p-4 text-slate-500 text-xs uppercase text-center">Execute</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-slate-100 dark:divide-slate-800">
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                    <td class="p-4 text-sm font-medium flex items-center gap-2"><span
                        class="material-symbols-outlined text-slate-400 text-[20px]">shopping_bag</span> Products
                      Catalog</td>
                    <td class="p-4 text-center"><input checked type="checkbox"
                        class="rounded border-slate-300 text-blue-600 h-5 w-5" /></td>
                    <td class="p-4 text-center"><input checked type="checkbox"
                        class="rounded border-slate-300 text-blue-600 h-5 w-5" /></td>
                    <td class="p-4 text-center"><input checked type="checkbox"
                        class="rounded border-slate-300 text-blue-600 h-5 w-5" /></td>
                    <td class="p-4 text-center"><input type="checkbox"
                        class="rounded border-slate-300 text-blue-600 h-5 w-5" /></td>
                    <td class="p-4 text-center"><input disabled type="checkbox"
                        class="rounded border-slate-200 bg-slate-100 h-5 w-5" /></td>
                  </tr>
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                    <td class="p-4 text-sm font-medium flex items-center gap-2"><span
                        class="material-symbols-outlined text-slate-400 text-[20px]">badge</span> Employees & Staff</td>
                    <td class="p-4 text-center"><input checked type="checkbox"
                        class="rounded border-slate-300 text-blue-600 h-5 w-5" /></td>
                    <td class="p-4 text-center"><input checked type="checkbox"
                        class="rounded border-slate-300 text-blue-600 h-5 w-5" /></td>
                    <td class="p-4 text-center"><input checked type="checkbox"
                        class="rounded border-slate-300 text-blue-600 h-5 w-5" /></td>
                    <td class="p-4 text-center"><input type="checkbox"
                        class="rounded border-slate-300 text-blue-600 h-5 w-5" /></td>
                    <td class="p-4 text-center"><input disabled type="checkbox"
                        class="rounded border-slate-200 bg-slate-100 h-5 w-5" /></td>
                  </tr>
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                    <td class="p-4 text-sm font-medium flex items-center gap-2"><span
                        class="material-symbols-outlined text-slate-400 text-[20px]">group</span> Customer Data</td>
                    <td class="p-4 text-center"><input checked type="checkbox"
                        class="rounded border-slate-300 text-blue-600 h-5 w-5" /></td>
                    <td class="p-4 text-center"><input checked type="checkbox"
                        class="rounded border-slate-300 text-blue-600 h-5 w-5" /></td>
                    <td class="p-4 text-center"><input checked type="checkbox"
                        class="rounded border-slate-300 text-blue-600 h-5 w-5" /></td>
                    <td class="p-4 text-center"><input checked type="checkbox"
                        class="rounded border-slate-300 text-blue-600 h-5 w-5" /></td>
                    <td class="p-4 text-center"><input disabled type="checkbox"
                        class="rounded border-slate-200 bg-slate-100 h-5 w-5" /></td>
                  </tr>
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                    <td class="p-4 text-sm font-medium flex items-center gap-2"><span
                        class="material-symbols-outlined text-slate-400 text-[20px]">receipt_long</span> Invoices</td>
                    <td class="p-4 text-center"><input type="checkbox"
                        class="rounded border-slate-300 text-blue-600 h-5 w-5" /></td>
                    <td class="p-4 text-center"><input checked type="checkbox"
                        class="rounded border-slate-300 text-blue-600 h-5 w-5" /></td>
                    <td class="p-4 text-center"><input type="checkbox"
                        class="rounded border-slate-300 text-blue-600 h-5 w-5" /></td>
                    <td class="p-4 text-center"><input type="checkbox"
                        class="rounded border-slate-300 text-blue-600 h-5 w-5" /></td>
                    <td class="p-4 text-center"><input checked type="checkbox"
                        class="rounded border-slate-300 text-blue-600 h-5 w-5" /></td>
                  </tr>
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                    <td class="p-4 text-sm font-medium flex items-center gap-2"><span
                        class="material-symbols-outlined text-slate-400 text-[20px]">analytics</span> Analytics</td>
                    <td class="p-4 text-center"><input disabled type="checkbox"
                        class="rounded border-slate-200 bg-slate-100 h-5 w-5" /></td>
                    <td class="p-4 text-center"><input checked type="checkbox"
                        class="rounded border-slate-300 text-blue-600 h-5 w-5" /></td>
                    <td class="p-4 text-center"><input disabled type="checkbox"
                        class="rounded border-slate-200 bg-slate-100 h-5 w-5" /></td>
                    <td class="p-4 text-center"><input disabled type="checkbox"
                        class="rounded border-slate-200 bg-slate-100 h-5 w-5" /></td>
                    <td class="p-4 text-center"><input checked type="checkbox"
                        class="rounded border-slate-300 text-blue-600 h-5 w-5" /></td>
                  </tr>
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                    <td class="p-4 text-sm font-medium flex items-center gap-2"><span
                        class="material-symbols-outlined text-slate-400 text-[20px]">settings</span> System</td>
                    <td class="p-4 text-center"><input type="checkbox"
                        class="rounded border-slate-300 text-blue-600 h-5 w-5" /></td>
                    <td class="p-4 text-center"><input checked type="checkbox"
                        class="rounded border-slate-300 text-blue-600 h-5 w-5" /></td>
                    <td class="p-4 text-center"><input type="checkbox"
                        class="rounded border-slate-300 text-blue-600 h-5 w-5" /></td>
                    <td class="p-4 text-center"><input type="checkbox"
                        class="rounded border-slate-300 text-blue-600 h-5 w-5" /></td>
                    <td class="p-4 text-center"><input type="checkbox"
                        class="rounded border-slate-300 text-blue-600 h-5 w-5" /></td>
                  </tr>
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                    <td class="p-4 text-sm font-medium flex items-center gap-2"><span
                        class="material-symbols-outlined text-slate-400 text-[20px]">calendar_month</span> Bookings</td>
                    <td class="p-4 text-center"><input checked type="checkbox"
                        class="rounded border-slate-300 text-blue-600 h-5 w-5" /></td>
                    <td class="p-4 text-center"><input checked type="checkbox"
                        class="rounded border-slate-300 text-blue-600 h-5 w-5" /></td>
                    <td class="p-4 text-center"><input checked type="checkbox"
                        class="rounded border-slate-300 text-blue-600 h-5 w-5" /></td>
                    <td class="p-4 text-center"><input checked type="checkbox"
                        class="rounded border-slate-300 text-blue-600 h-5 w-5" /></td>
                    <td class="p-4 text-center"><input disabled type="checkbox"
                        class="rounded border-slate-200 bg-slate-100 h-5 w-5" /></td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    `
  }

}
