import { Controller } from "@hotwired/stimulus"

export default class Admin_LayoutController extends Controller {
  static targets = ["content"]

  connect() {
    this.id = randomId()
    this.element.id = this.id

    poll(() => {
      if (currentUser()) {
        this.renderLayout()
        return true
      }
      return false
    })
  }

  renderLayout() {
    this.element.className = "min-h-screen bg-slate-50 dark:bg-slate-950"
    this.element.innerHTML = this.layoutHTML()
  }

  renderContent() {
    if (!this.hasContentTarget) return
    this.contentTarget.innerHTML = this.contentHTML()
  }

  layoutHTML() {
    const user = currentUser()
    const isActive = (path) => window.location.pathname.startsWith(path)
      ? 'bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400'
      : 'text-slate-600 hover:bg-slate-100 dark:text-slate-400 dark:hover:bg-slate-800'

    return `
      <div class="flex h-screen overflow-hidden">
        <!-- Sidebar -->
        <aside class="w-64 bg-white dark:bg-slate-900 border-r border-slate-200 dark:border-slate-800 flex flex-col shrink-0">
          <div class="h-16 flex items-center px-6 border-b border-slate-200 dark:border-slate-800">
            <span class="text-lg font-bold text-slate-900 dark:text-white">Skycom Admin</span>
          </div>
          <nav class="flex-1 overflow-y-auto p-4 space-y-1">
            <a href="/admin/companies"
              class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors cursor-pointer ${isActive('/admin/companies')}">
              <span class="material-symbols-outlined text-[20px]">business</span>
              Companies
            </a>
            <a href="#"
              class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium text-slate-400 cursor-not-allowed">
              <span class="material-symbols-outlined text-[20px]">group</span>
              Users
              <span class="text-[10px] px-1.5 py-0.5 bg-slate-100 dark:bg-slate-800 rounded text-slate-400 ml-auto">Soon</span>
            </a>
          </nav>
          <div class="p-4 border-t border-slate-200 dark:border-slate-800">
            <div class="flex items-center gap-3">
              <div class="w-8 h-8 rounded-full bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center shrink-0">
                <span class="text-sm font-bold text-blue-600 dark:text-blue-400">${(user?.name || 'A')[0].toUpperCase()}</span>
              </div>
              <div class="min-w-0 flex-1">
                <p class="text-sm font-medium text-slate-900 dark:text-white truncate">${user?.name || 'Admin'}</p>
                <p class="text-xs text-slate-500 truncate">${user?.email || ''}</p>
              </div>
            </div>
            <a href="/sign_out"
              class="mt-3 flex items-center gap-2 px-3 py-2 text-sm text-slate-500 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors cursor-pointer">
              <span class="material-symbols-outlined text-[18px]">logout</span>
              Sign out
            </a>
          </div>
        </aside>

        <!-- Main content -->
        <div class="flex-1 flex flex-col overflow-hidden">
          <header class="h-16 bg-white dark:bg-slate-900 border-b border-slate-200 dark:border-slate-800 flex items-center justify-between px-6 shrink-0">
            <h1 class="text-lg font-bold text-slate-900 dark:text-white"></h1>
          </header>
          <main class="flex-1 overflow-y-auto" data-${this.identifier}-target="content"></main>
        </div>
      </div>
    `
  }
}
