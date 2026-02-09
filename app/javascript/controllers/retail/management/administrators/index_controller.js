import Retail_Management_LayoutController from "controllers/retail/management/layout_controller"

export default class Retail_Management_Administrators_IndexController extends Retail_Management_LayoutController {

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
            data-controller="retail--management--administrators--roles"
            class="lg:col-span-1 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col overflow-hidden shadow-sm"
          ></div>

          <div
            data-controller="retail--management--administrators--permissions"
            class="lg:col-span-3 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col overflow-hidden shadow-sm"
          ></div>
        </div>
      </div>
    `
  }

}
