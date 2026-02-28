import * as Helpers from "controllers/helpers"
import Retail_Management_LayoutController from "controllers/retail/management/layout_controller"

export default class Retail_Management_Subscriptions_IndexController extends Retail_Management_LayoutController {

  connect() {
    super.connect()
    this.load()
  }

  async load() {
    const data = await Helpers.fetchJson()
    const subscriptions = data.subscriptions || []
    this.render(subscriptions)
  }

  render(items) {
    const tbody = this.element.querySelector("tbody")
    if (!tbody) return

    if (!items || items.length === 0) {
      tbody.innerHTML = `
        <tr>
          <td colspan="6" class="p-8 text-center text-gray-500 dark:text-gray-400">
            No subscriptions found
          </td>
        </tr>
      `
      return
    }

    tbody.innerHTML = items.map(item => this.rowHTML(item)).join("")
  }

  rowHTML(item) {
    const entityType = item.seller_type || item.buyer_type || "Unknown"
    const entityName = item.name || "Unnamed"
    const entityDesc = item.description || entityType

    return `
      <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors group">
        <td class="p-4">
          <div class="flex items-center gap-3">
            ${this.entityIconHTML(entityType)}
            <div class="flex flex-col">
              <span class="text-sm font-medium text-gray-900 dark:text-white">${entityName}</span>
              <span class="text-xs text-gray-500 dark:text-gray-400">${entityDesc}</span>
            </div>
          </div>
        </td>
        <td class="p-4 text-sm text-gray-700 dark:text-gray-300">
          ${item.subscription_plan_id ? `Plan #${item.subscription_plan_id.slice(0,8)}` : "—"}
        </td>
        <td class="p-4 text-sm text-gray-500 dark:text-gray-400">
          ${item.created_at ? new Date(item.created_at).toLocaleDateString() : "—"}
        </td>
        <td class="p-4 text-sm text-gray-500 dark:text-gray-400">—</td>
        <td class="p-4">
          ${this.statusHTML(item.lifecycle_status, item.workflow_status)}
        </td>
        <td class="p-4 text-right">
          <div class="flex items-center justify-end gap-2">
            <button
              class="p-1.5 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
              title="View Details">
              <span class="material-symbols-outlined text-[20px]">visibility</span>
            </button>
            <button
              class="p-1.5 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
              title="Edit Subscription">
              <span class="material-symbols-outlined text-[20px]">edit</span>
            </button>
            <button
              class="p-1.5 text-gray-500 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
              title="Cancel Subscription">
              <span class="material-symbols-outlined text-[20px]">cancel</span>
            </button>
          </div>
        </td>
      </tr>
    `
  }

  entityIconHTML(type) {
    const icons = {
      "Company": "business",
      "Customer":     "person",
      "Company":      "domain",
      "Branch":       "store"
    }
    const icon = icons[type] || "business"
    const color = type.includes("Company") ? "purple" : "blue"

    return `
      <div class="bg-${color}-100 dark:bg-${color}-900/30 text-${color}-600 dark:text-${color}-400 p-2 rounded-lg">
        <span class="material-symbols-outlined">${icon}</span>
      </div>
    `
  }

  statusHTML(lifecycle, workflow) {
    const status = lifecycle || workflow || "unknown"
    const styles = {
      "active":    "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400 border-green-200 dark:border-green-800",
      "draft":     "bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400 border-yellow-200 dark:border-yellow-800",
      "cancelled": "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400 border-red-200 dark:border-red-800",
      "expired":   "bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300 border-gray-200 dark:border-gray-600",
      "unknown":   "bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300 border-gray-200 dark:border-gray-600"
    }
    const dots = {
      "active":    "bg-green-500",
      "draft":     "bg-yellow-500",
      "cancelled": "bg-red-500",
      "expired":   "bg-gray-500",
      "unknown":   "bg-gray-500"
    }

    const style = styles[status.toLowerCase()] || styles["unknown"]
    const dot   = dots[status.toLowerCase()]   || dots["unknown"]

    return `
      <span class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium border ${style}">
        <div class="w-1.5 h-1.5 rounded-full ${dot}"></div>
        ${status.charAt(0).toUpperCase() + status.slice(1)}
      </span>
    `
  }

  contentHTML() {
    return `
      <div class="p-8 flex flex-col flex-1 overflow-hidden">
        <div class="flex-shrink-0 flex flex-wrap justify-between gap-3 mb-8">
          <div class="flex flex-col gap-1">
            <h1 class="text-gray-900 dark:text-white text-3xl font-bold leading-tight tracking-tight">Company & Branch
              Subscriptions</h1>
            <p class="text-gray-500 dark:text-gray-400 text-base font-normal leading-normal">Manage billing cycles,
              plans, and statuses for all registered entities.</p>
          </div>
        </div>

        <div
          class="flex-1 bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 shadow-sm flex flex-col overflow-hidden">
          <div
            class="p-4 border-b border-gray-200 dark:border-gray-800 flex flex-wrap gap-4 items-center justify-between">
            <div class="flex flex-wrap items-center gap-4">
              <div class="relative">
                <span
                  class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500 dark:text-gray-400 material-symbols-outlined text-[20px]">filter_alt</span>
                <select
                  class="pl-10 pr-8 py-2 bg-gray-50 dark:bg-gray-800 border-gray-200 dark:border-gray-700 rounded-lg text-sm text-gray-700 dark:text-gray-200 focus:ring-blue-600 focus:border-blue-600">
                  <option>All Statuses</option>
                  <option>Active</option>
                  <option>Expired</option>
                  <option>Trial</option>
                </select>
              </div>
              <div class="relative">
                <span
                  class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500 dark:text-gray-400 material-symbols-outlined text-[20px]">layers</span>
                <select
                  class="pl-10 pr-8 py-2 bg-gray-50 dark:bg-gray-800 border-gray-200 dark:border-gray-700 rounded-lg text-sm text-gray-700 dark:text-gray-200 focus:ring-blue-600 focus:border-blue-600">
                  <option>All Plans</option>
                  <option>Retail Starter</option>
                  <option>Enterprise Gold</option>
                  <option>Education Plus</option>
                  <option>Hospitality Pro</option>
                </select>
              </div>
              <div class="relative">
                <span
                  class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500 dark:text-gray-400 material-symbols-outlined text-[20px]">domain</span>
                <select
                  class="pl-10 pr-8 py-2 bg-gray-50 dark:bg-gray-800 border-gray-200 dark:border-gray-700 rounded-lg text-sm text-gray-700 dark:text-gray-200 focus:ring-blue-600 focus:border-blue-600">
                  <option>All Entities</option>
                  <option>Branches Only</option>
                  <option>Branches Only</option>
                </select>
              </div>
            </div>
            <div>
              <button
                class="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors text-sm font-medium shadow-md">
                <span class="material-symbols-outlined text-[20px]">add_circle</span>
                Add New Subscription
              </button>
            </div>
          </div>

          <div class="overflow-x-auto custom-scrollbar flex-1">
            <table class="w-full text-left border-collapse">
              <thead class="bg-gray-50 dark:bg-gray-800/50 sticky top-0 z-10">
                <tr>
                  <th class="p-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider w-1/4">
                    Associated Entity</th>
                  <th class="p-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Plan
                    Name</th>
                  <th class="p-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Start
                    Date</th>
                  <th class="p-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">End
                    Date</th>
                  <th class="p-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Status
                  </th>
                  <th
                    class="p-4 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider text-right">
                    Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-200 dark:divide-gray-800">
                <tr>
                  <td colspan="6" class="p-8 text-center text-gray-500 dark:text-gray-400">
                    <div class="flex flex-col items-center justify-center gap-2">
                      <span class="material-symbols-outlined animate-spin text-3xl">progress_activity</span>
                      <span>Loading subscriptions...</span>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="p-4 border-t border-gray-200 dark:border-gray-800 flex items-center justify-between">
            <span class="text-sm text-gray-500 dark:text-gray-400">Showing 1-5 of 86 subscriptions</span>
            <div class="flex gap-2">
              <button
                class="p-2 rounded-lg border border-gray-200 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-800 text-gray-500 disabled:opacity-50">
                <span class="material-symbols-outlined text-[18px]">chevron_left</span>
              </button>
              <button
                class="p-2 rounded-lg border border-gray-200 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-800 text-gray-500">
                <span class="material-symbols-outlined text-[18px]">chevron_right</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    `
  }

}
