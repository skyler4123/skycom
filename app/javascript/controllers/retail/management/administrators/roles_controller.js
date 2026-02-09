import { Controller } from "@hotwired/stimulus"

export default class Retail_Management_Administrators_RolesController extends Controller {
  connect() {
    this.element.innerHTML = this.html()
  }

  html() {
    return `
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
    `
  }
}
