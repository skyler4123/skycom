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
    this.element.className = "min-h-screen bg-background "
    this.element.innerHTML = this.layoutHTML()
  }

  renderContent() {
    if (!this.hasContentTarget) return
    this.contentTarget.innerHTML = this.contentHTML()
  }

  layoutHTML() {
    const user = currentUser()
    const isActive = (path) => window.location.pathname.startsWith(path)
      ? 'bg-primary/10 text-primary '
      : 'text-muted-foreground hover:bg-muted '

    return `
      <div class="flex h-screen overflow-hidden text-foreground">
        <!-- Sidebar -->
        <aside class="w-64 bg-card border-r border-line flex flex-col shrink-0">
          <div class="h-16 flex items-center px-6 border-b border-line">
            <span class="text-lg font-bold text-foreground">Skycom Admin</span>
          </div>
          <nav class="flex-1 overflow-y-auto p-4 space-y-1">
            <a href="/admin/companies"
              class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors cursor-pointer ${isActive('/admin/companies')}">
              <span class="material-symbols-outlined text-[20px]">business</span>
              Companies
            </a>
            <a href="/admin/company_credits"
              class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors cursor-pointer ${isActive('/admin/company_credits')}">
              <span class="material-symbols-outlined text-[20px]">card_giftcard</span>
              Company Credits
            </a>
            <a href="/admin/promo_campaigns"
              class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors cursor-pointer ${isActive('/admin/promo_campaigns')}">
              <span class="material-symbols-outlined text-[20px]">campaign</span>
              Promotions
            </a>
            <a href="/admin/payment_methods"
              class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors cursor-pointer ${isActive('/admin/payment_methods')}">
              <span class="material-symbols-outlined text-[20px]">payments</span>
              Payment Methods
            </a>
            <a href="/admin/company_tickets"
              class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors cursor-pointer ${isActive('/admin/company_tickets')}">
              <span class="material-symbols-outlined text-[20px]">support_agent</span>
              Company Tickets
            </a>
            <a href="#"
              class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium text-muted-foreground cursor-not-allowed">
              <span class="material-symbols-outlined text-[20px]">group</span>
              Users
              <span class="text-[10px] px-1.5 py-0.5 bg-muted rounded text-muted-foreground ml-auto">Soon</span>
            </a>
          </nav>
          <div class="p-4 border-t border-line">
            <div class="flex items-center gap-3">
              <div class="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center shrink-0">
                <span class="text-sm font-bold text-primary">${(user?.name || 'A')[0].toUpperCase()}</span>
              </div>
              <div class="min-w-0 flex-1">
                <p class="text-sm font-medium text-foreground truncate">${user?.name || 'Admin'}</p>
                <p class="text-xs text-muted-foreground truncate">${user?.email || ''}</p>
              </div>
            </div>
            <a data-controller="sign-out" data-action="click->sign-out#handleClick" href="/sign_out"
              class="mt-3 flex items-center gap-2 px-3 py-2 text-sm text-muted-foreground hover:text-danger hover:bg-danger/10 rounded-lg transition-colors cursor-pointer">
              <span class="material-symbols-outlined text-[18px]!">logout</span>
              Sign out
            </a>
          </div>
        </aside>

        <!-- Main content -->
        <div class="flex-1 flex flex-col overflow-hidden">
          <header class="h-16 bg-card border-b border-line flex items-center justify-between px-6 shrink-0">
            <h1 class="text-lg font-bold text-foreground"></h1>
            <div class="flex items-center gap-2">
              <button class="flex cursor-pointer items-center justify-center overflow-hidden rounded-full h-10 w-10 p-2 hover:bg-muted text-muted-foreground" ${Helpers.darkmodeTrigger()}></button>
            </div>
          </header>
          <main class="flex-1 overflow-y-auto" data-${this.identifier}-target="content"></main>
        </div>
      </div>
    `
  }
}
