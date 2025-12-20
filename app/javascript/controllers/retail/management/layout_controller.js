import ApplicationController from "controllers/application_controller"
import { currentCompanyGroup, companyGroups, capitalize, openPopover, poll } from "controllers/helpers"

export default class Retail_Management_LayoutController extends ApplicationController {
  static targets = ["profileDropdown"]
  static values = {
    pagination: { type: Object, default: {} },
    flash: { type: Object, default: {} },
    data: { type: Object, default: {} },
    isOpenProfileDropdown: { type: Boolean, default: false },
    openHeaderSubmenuName: { type: String, default: "" },
    
  }

  initBindings() {
    this.companyGroups = companyGroups()
    // this.currentCompanyGroup
  }

  initLayout() {
    // Poll until the currentCompanyGroup can be determined from the URL.
    // This handles race conditions during redirects where the JS loads
    // before the URL is updated.
    poll(() => {
      this.currentCompanyGroup = currentCompanyGroup();
      if (this.currentCompanyGroup) {
        this.element.className = 'min-h-screen flex flex-col';
        this.element.innerHTML = this.layoutHTML();
        return true; // Stop polling
      }
      return false; // Continue polling
    });
  }

  openCompanyGroupDropdown(event) {
   event.preventDefault();
    openPopover({
      parentElement: event.currentTarget,
      html: this.companyGroupDropdownHTML(),
      position: "bottom-right",
    })
  }

  companyGroupDropdownHTML() {
    return `
      <div class="flex flex-col gap-y-6 w-64 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-md shadow-lg z-50 p-2">
        ${this.companyGroups.map((companyGroup) => `
          <a href="${companyGroup.url}" class="flex items-center gap-3 px-3 py-2 rounded-lg text-gray-800 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 ${this.currentCompanyGroup.id === companyGroup.id ? 'bg-gray-100 dark:bg-gray-700' : ''}">
            <div class="flex flex-col">
              <span class="text-sm font-medium">${companyGroup.name}</span>
            </div>
          </a>`).join("")}
      </div>
    `
  }
  
  layoutHTML() {
    return `
      <div class="font-display bg-white dark:bg-gray-800 text-gray-800 dark:text-gray-200">
        <div class="flex h-screen">
          <!-- Sidebar -->
          <aside
            class="w-64 shrink-0 bg-white dark:bg-gray-900 border-r border-gray-200 dark:border-gray-800 flex flex-col">
            <div class="p-6 flex items-center gap-3 border-b border-gray-200 dark:border-gray-800">
              <div class="bg-primary/20 text-primary p-2 rounded-lg">
                <span class="material-symbols-outlined">storefront</span>
              </div>
              <div class="flex flex-col">
                <h1 data-action="click->${this.identifier}#openCompanyGroupDropdown" class="text-gray-900 dark:text-white text-base font-medium leading-normal cursor-pointer">${this.currentCompanyGroup.name}</h1>
                <p class="text-gray-500 dark:text-gray-400 text-sm font-normal leading-normal">${capitalize(this.currentCompanyGroup.business_type)}</p>
              </div>
            </div>
            <nav class="w-full p-4">
              <div class="flex flex-col gap-2">
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="/retail/${this.currentCompanyGroup.id}/management/dashboard"
                  ${this.openByPathname()}/
                >
                  <span class="material-symbols-outlined">dashboard</span>
                  <p class="text-sm font-medium leading-normal" ${this.translate("Dashboard")}>Dashboard</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="/retail/${this.currentCompanyGroup.id}/management/branches"
                  ${this.openByPathname()}/
                >
                  <span class="material-symbols-outlined">apartment</span>
                  <p class="text-sm font-medium leading-normal">Branches</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="/retail/${this.currentCompanyGroup.id}/management/departments"
                  ${this.openByPathname()}/
                >
                  <span class="material-symbols-outlined">family_group</span>
                  <p class="text-sm font-medium leading-normal">Departments</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="/retail/${this.currentCompanyGroup.id}/management/products"
                  ${this.openByPathname()}/
                >
                  <span class="material-symbols-outlined">inventory_2</span>
                  <p class="text-sm font-medium leading-normal">Products</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="/retail/${this.currentCompanyGroup.id}/management/orders"
                  ${this.openByPathname()}/
                >
                  <span class="material-symbols-outlined">order_approve</span>
                  <p class="text-sm font-medium leading-normal">Orders</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="/retail/${this.currentCompanyGroup.id}/management/bookings"
                  ${this.openByPathname()}/
                >
                  <span class="material-symbols-outlined">calendar_month</span>
                  <p class="text-sm font-medium leading-normal">Bookings</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="/retail/${this.currentCompanyGroup.id}/management/payments"
                  ${this.openByPathname()}/
                >
                  <span class="material-symbols-outlined">payments</span>
                  <p class="text-sm font-medium leading-normal">Payments</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="/retail/${this.currentCompanyGroup.id}/management/employees"
                  ${this.openByPathname()}/
                >
                  <span class="material-symbols-outlined">groups</span>
                  <p class="text-sm font-medium leading-normal">Employees</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="/retail/${this.currentCompanyGroup.id}/management/inventories"
                  ${this.openByPathname()}/
                >
                  <span class="material-symbols-outlined">inventory</span>
                  <p class="text-sm font-medium leading-normal">Inventories</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="/retail/${this.currentCompanyGroup.id}/management/customers"
                  ${this.openByPathname()}/
                >
                  <span class="material-symbols-outlined">person_add</span>
                  <p class="text-sm font-medium leading-normal">Customers</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="/retail/${this.currentCompanyGroup.id}/management/invoices"
                  ${this.openByPathname()}/
                >
                  <span class="material-symbols-outlined">receipt_long</span>
                  <p class="text-sm font-medium leading-normal">Invoices</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="/retail/${this.currentCompanyGroup.id}/management/schedules"
                  ${this.openByPathname()}/
                >
                  <span class="material-symbols-outlined">calendar_month</span>
                  <p class="text-sm font-medium leading-normal">Schedules</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="/retail/${this.currentCompanyGroup.id}/management/attendances"
                  ${this.openByPathname()}/
                >
                  <span class="material-symbols-outlined">fact_check</span>
                  <p class="text-sm font-medium leading-normal">Attendances</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="/retail/${this.currentCompanyGroup.id}/management/reports"
                  ${this.openByPathname()}/
                >
                  <span class="material-symbols-outlined">report_problem</span>
                  <p class="text-sm font-medium leading-normal">Reports</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="/retail/${this.currentCompanyGroup.id}/management/documents"
                  ${this.openByPathname()}/
                >
                  <span class="material-symbols-outlined">description</span>
                  <p class="text-sm font-medium leading-normal">Documents</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="/retail/${this.currentCompanyGroup.id}/management/announcements"
                  ${this.openByPathname()}/
                >
                  <span class="material-symbols-outlined">campaign</span>
                  <p class="text-sm font-medium leading-normal">Announcements</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="/retail/${this.currentCompanyGroup.id}/management/events"
                  ${this.openByPathname()}/
                >
                  <span class="material-symbols-outlined">event</span>
                  <p class="text-sm font-medium leading-normal">Events</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="/retail/${this.currentCompanyGroup.id}/management/discounts"
                  ${this.openByPathname()}/
                >
                  <span class="material-symbols-outlined">percent</span>
                  <p class="text-sm font-medium leading-normal">Discounts</p>
                </a>
                                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="/retail/${this.currentCompanyGroup.id}/management/tasks"
                  ${this.openByPathname()}/
                >
                  <span class="material-symbols-outlined">check_box</span>
                  <p class="text-sm font-medium leading-normal">Tasks</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="/retail/${this.currentCompanyGroup.id}/management/payslips"
                  ${this.openByPathname()}/
                >
                  <span class="material-symbols-outlined">receipt</span>
                  <p class="text-sm font-medium leading-normal">Payslips</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  href="/retail/${this.currentCompanyGroup.id}/management/facilities"
                  ${this.openByPathname()}/
                >
                  <span class="material-symbols-outlined">warehouse</span>
                  <p class="text-sm font-medium leading-normal">Facilities</p>
                </a>
              </div>
            </nav>
            <div class="p-4 border-t border-gray-200 dark:border-gray-800">
              <div class="flex flex-col gap-2">
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  ${this.openByPathname()}
                  href="/retail/${this.currentCompanyGroup.id}/management/settings"
                >
                  <span class="material-symbols-outlined">settings</span>
                  <p class="text-sm font-medium leading-normal">Settings</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
                  ${this.openByPathname()}
                  href="/retail/${this.currentCompanyGroup.id}/management/administrators"
                >
                  <span class="material-symbols-outlined">admin_panel_settings</span>
                  <p class="text-sm font-medium leading-normal">Administrator</p>
                </a>
              </div>
            </div>
          </aside>
          <!-- End Sidebar -->
          <!-- Main Content -->
          <main class="flex-1 flex flex-col overflow-auto">
            <!-- Header -->
            <header
              class="shrink-0 flex items-center justify-between whitespace-nowrap border-b border-gray-200 dark:border-gray-800 px-8 py-4 bg-white dark:bg-gray-900">
              <div class="flex items-center gap-8">
                <label class="flex flex-col min-w-40 h-10! w-80">
                  <div class="flex w-full flex-1 items-stretch rounded-lg h-full">
                    <div
                      class="text-gray-500 flex bg-gray-100 dark:bg-gray-800 items-center justify-center pl-4 rounded-l-lg border-r-0">
                      <span class="material-symbols-outlined">search</span>
                    </div>
                    <input
                      class="form-input flex w-full min-w-0 flex-1 resize-none overflow-hidden rounded-lg text-gray-900 dark:text-white focus:outline-0 focus:ring-0 border-none bg-gray-100 dark:bg-gray-800 h-full placeholder:text-gray-500 px-4 rounded-l-none border-l-0 pl-2 text-base font-normal leading-normal"
                      placeholder="Search for products, customers..." value="" />
                  </div>
                </label>
              </div>
              <div class="flex flex-1 justify-end gap-4 items-center">
                <button
                  class="flex cursor-pointer items-center justify-center overflow-hidden rounded-full h-10 w-10 p-2 hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-600 dark:text-gray-300"
                  ${this.darkmode()}
                </button>
                <button
                  class="flex cursor-pointer items-center justify-center overflow-hidden rounded-full h-10 w-10 hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-600 dark:text-gray-300"
                  ${this.triggerLanguageDropdown()}
                >
                  <span ${this.languageCodeTextTarget()}></span>
                </button>
                <button
                  class="flex cursor-pointer items-center justify-center overflow-hidden rounded-full h-10 w-10 hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-600 dark:text-gray-300">
                  <span class="material-symbols-outlined">notifications</span>
                </button>
                <button
                  class="flex cursor-pointer items-center justify-center overflow-hidden rounded-full h-10 w-10 hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-600 dark:text-gray-300">
                  <span class="material-symbols-outlined">settings</span>
                </button>
                <div class="bg-center bg-no-repeat aspect-square bg-cover rounded-full size-10"
                  data-alt="User profile picture"
                  style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuBYk6_5wqHwhOUyfqIOzuw7uF6nG1B2aHcNfqPXgheh0TJNM9wgrKtU__k7USaOwDZLXPpvIrYvaXBnMbO7rmZHK15vMirHZqrK0UBZ18vJdiQZlmTrGe8wch8p3G7GXSetuz5njKmy7Hb6XGw18g0stonxhwtIcuuEqzZVHxbviNLuy4i_B8JHC1x_JlbUrZoIV2QQqyAprbH-jems99h8nqDZ6D6FBmq8JDrKIfaBYkl3mR0cYldl3c0gaNynjiRNKDKfaUcIKBc");'>
                </div>
              </div>
            </header>
            <!-- End Header -->
            <!-- Main Content -->
            ${this.contentHTML()}
            <!-- End Main Content -->
          </main>
          <!-- End Main Content -->
        </div>
      </div>
    `
  }

}
