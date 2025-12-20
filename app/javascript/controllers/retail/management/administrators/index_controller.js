import Retail_Management_LayoutController from "controllers/retail/management/layout_controller"

export default class Retail_Management_Administrators_IndexController extends Retail_Management_LayoutController {

  contentHTML() {
    return `
      <div class="p-8 h-full flex flex-col">
        <div class="flex flex-wrap justify-between items-end gap-4 mb-8">
          <div class="flex flex-col gap-1">
            <h1 class="text-gray-900 dark:text-white text-3xl font-bold leading-tight tracking-tight">Role & Policy
              Management</h1>
            <p class="text-gray-500 dark:text-gray-400 text-base font-normal">Configure RBAC rules, assign policies, and
              manage permissions across verticals.</p>
          </div>
          <div class="flex items-center gap-3">
            <div class="relative">
              <span class="absolute inset-y-0 left-0 flex items-center pl-3 text-gray-400">
                <span class="material-symbols-outlined text-xl">search</span>
              </span>
              <input
                class="pl-10 pr-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-900 text-sm focus:ring-2 focus:ring-blue-500 focus:outline-none w-64"
                placeholder="Filter roles..." type="text" />
            </div>
            <button
              class="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 transition-colors shadow-sm">
              <span class="material-symbols-outlined text-lg">add</span>
              Add New Role
            </button>
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-4 gap-6 flex-1 min-h-0">
          <div
            class="lg:col-span-1 bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 flex flex-col overflow-hidden shadow-sm">
            <div class="p-4 border-b border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-800/50">
              <h2 class="text-xs font-bold uppercase text-gray-500 tracking-wider">Defined Roles</h2>
            </div>
            <div class="overflow-y-auto flex-1 p-2 space-y-1">
              <button
                class="w-full flex items-center justify-between p-3 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800/50 text-blue-600 transition-all">
                <div class="flex items-center gap-3">
                  <span class="material-symbols-outlined">shield_person</span>
                  <div class="text-left">
                    <p class="font-medium text-sm">Manager</p>
                    <p class="text-xs opacity-70">14 Active Users</p>
                  </div>
                </div>
                <span class="material-symbols-outlined text-lg">chevron_right</span>
              </button>
              <button
                class="w-full flex items-center justify-between p-3 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800 text-gray-700 dark:text-gray-300 transition-all">
                <div class="flex items-center gap-3">
                  <span class="material-symbols-outlined text-gray-400">admin_panel_settings</span>
                  <div class="text-left">
                    <p class="font-medium text-sm">Super Admin</p>
                    <p class="text-xs text-gray-400">3 Active Users</p>
                  </div>
                </div>
              </button>
              <button
                class="w-full flex items-center justify-between p-3 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800 text-gray-700 dark:text-gray-300 transition-all">
                <div class="flex items-center gap-3">
                  <span class="material-symbols-outlined text-gray-400">storefront</span>
                  <div class="text-left">
                    <p class="font-medium text-sm">Seller / POS</p>
                    <p class="text-xs text-gray-400">42 Active Users</p>
                  </div>
                </div>
              </button>
            </div>
          </div>

          <div
            class="lg:col-span-3 bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 flex flex-col overflow-hidden shadow-sm">
            <div
              class="p-4 border-b border-gray-200 dark:border-gray-800 flex justify-between items-center bg-gray-50 dark:bg-gray-800/50">
              <div class="flex items-center gap-2">
                <h2 class="text-base font-bold text-gray-900 dark:text-white">Permissions for: <span
                    class="text-blue-600">Manager</span></h2>
                <span
                  class="px-2 py-0.5 rounded-full bg-green-100 text-green-700 text-xs font-medium border border-green-200">Active</span>
              </div>
              <div class="flex gap-3">
                <button class="text-gray-500 hover:text-gray-700 text-sm font-medium">Reset Default</button>
                <button
                  class="px-4 py-1.5 bg-gray-900 hover:bg-gray-800 dark:bg-white dark:hover:bg-gray-200 text-white dark:text-gray-900 text-sm font-medium rounded-lg transition-colors">Save
                  Changes</button>
              </div>
            </div>
            <div class="flex-1 overflow-auto">
              <table class="w-full text-left border-collapse">
                <thead class="bg-white dark:bg-gray-900 sticky top-0 z-10">
                  <tr>
                    <th
                      class="p-4 border-b border-gray-200 dark:border-gray-800 font-medium text-gray-500 text-xs uppercase w-1/3">
                      Resource Name</th>
                    <th
                      class="p-4 border-b border-gray-200 dark:border-gray-800 font-medium text-gray-500 text-xs uppercase text-center w-24">
                      Create</th>
                    <th
                      class="p-4 border-b border-gray-200 dark:border-gray-800 font-medium text-gray-500 text-xs uppercase text-center w-24">
                      Read</th>
                    <th
                      class="p-4 border-b border-gray-200 dark:border-gray-800 font-medium text-gray-500 text-xs uppercase text-center w-24">
                      Update</th>
                    <th
                      class="p-4 border-b border-gray-200 dark:border-gray-800 font-medium text-gray-500 text-xs uppercase text-center w-24">
                      Delete</th>
                    <th
                      class="p-4 border-b border-gray-200 dark:border-gray-800 font-medium text-gray-500 text-xs uppercase text-center w-24">
                      Execute</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 dark:divide-gray-800">
                  <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                    <td class="p-4 text-sm font-medium text-gray-900 dark:text-white flex items-center gap-2">
                      <span class="material-symbols-outlined text-gray-400 text-xl">shopping_bag</span>
                      Products Catalog
                    </td>
                    <td class="p-4 text-center">
                      <input checked type="checkbox"
                        class="accent-blue-600 h-5 w-5 cursor-pointer border-gray-300 rounded" />
                    </td>
                    <td class="p-4 text-center">
                      <input checked type="checkbox"
                        class="accent-blue-600 h-5 w-5 cursor-pointer border-gray-300 rounded" />
                    </td>
                    <td class="p-4 text-center">
                      <input checked type="checkbox"
                        class="accent-blue-600 h-5 w-5 cursor-pointer border-gray-300 rounded" />
                    </td>
                    <td class="p-4 text-center">
                      <input type="checkbox" class="accent-blue-600 h-5 w-5 cursor-pointer border-gray-300 rounded" />
                    </td>
                    <td class="p-4 text-center">
                      <input disabled type="checkbox"
                        class="bg-gray-100 h-5 w-5 cursor-not-allowed border-gray-200 rounded" />
                    </td>
                  </tr>
                  <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                    <td class="p-4 text-sm font-medium text-gray-900 dark:text-white flex items-center gap-2">
                      <span class="material-symbols-outlined text-gray-400 text-xl">badge</span>
                      Employees & Staff
                    </td>
                    <td class="p-4 text-center"><input checked type="checkbox"
                        class="accent-blue-600 h-5 w-5 border-gray-300 rounded" /></td>
                    <td class="p-4 text-center"><input checked type="checkbox"
                        class="accent-blue-600 h-5 w-5 border-gray-300 rounded" /></td>
                    <td class="p-4 text-center"><input checked type="checkbox"
                        class="accent-blue-600 h-5 w-5 border-gray-300 rounded" /></td>
                    <td class="p-4 text-center"><input type="checkbox"
                        class="accent-blue-600 h-5 w-5 border-gray-300 rounded" /></td>
                    <td class="p-4 text-center"><input disabled type="checkbox"
                        class="bg-gray-100 h-5 w-5 border-gray-200 rounded" /></td>
                  </tr>
                  <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                    <td class="p-4 text-sm font-medium text-gray-900 dark:text-white flex items-center gap-2">
                      <span class="material-symbols-outlined text-gray-400 text-xl">settings</span>
                      System Settings
                    </td>
                    <td class="p-4 text-center"><input type="checkbox"
                        class="accent-blue-600 h-5 w-5 border-gray-300 rounded" /></td>
                    <td class="p-4 text-center"><input checked type="checkbox"
                        class="accent-blue-600 h-5 w-5 border-gray-300 rounded" /></td>
                    <td class="p-4 text-center"><input type="checkbox"
                        class="accent-blue-600 h-5 w-5 border-gray-300 rounded" /></td>
                    <td class="p-4 text-center"><input type="checkbox"
                        class="accent-blue-600 h-5 w-5 border-gray-300 rounded" /></td>
                    <td class="p-4 text-center"><input checked type="checkbox"
                        class="accent-blue-600 h-5 w-5 border-gray-300 rounded" /></td>
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
