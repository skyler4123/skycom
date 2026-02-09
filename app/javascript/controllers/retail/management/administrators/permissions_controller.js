import { Controller } from "@hotwired/stimulus"

export default class Retail_Management_Administrators_PermissionsController extends Controller {
  connect() {
    this.element.innerHTML = this.html()
  }

  html() {
    return `
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
    `
  }
}
