import * as Helpers from "controllers/helpers"
import Retail_Management_LayoutController from "controllers/retail/management/layout_controller"

export default class Retail_Management_Services_IndexController extends Retail_Management_LayoutController {
  static targets = ["servicesList"]

  /** @type {Service[]} */
  services = []

  async initialize() {
    super.initialize()
    const response = await Helpers.fetchJson();
    this.services = response.services || []
    this.render()
  }

  render() {
    if (!this.hasServicesListTarget) return
    this.servicesListTarget.innerHTML = this.servicesHTML()
  }

  showServiceDetails(event) {
    const serviceName = event.currentTarget.textContent.trim()
    const service = this.services.find(s => s.name === serviceName)

    if (!service) return

    const modalId = `service-details-modal-${Helpers.randomId()}`

    const modalHTML = `
      <div id="${modalId}" class="flex justify-center items-center">
        <div class="w-full max-w-2xl bg-white dark:bg-slate-900 rounded-xl shadow-lg overflow-hidden border border-slate-200 dark:border-slate-800">
          <div class="p-6 border-b border-slate-200 dark:border-slate-800">
            <h2 class="text-xl font-semibold text-slate-900 dark:text-white">Service Details - ${service.name}</h2>
          </div>
          <div class="p-6">
            <p class="text-sm text-slate-600 dark:text-slate-300 mb-4"><strong>Description:</strong> ${service.description || 'N/A'}</p>
            <p class="text-sm text-slate-600 dark:text-slate-300 mb-4"><strong>Code:</strong> ${service.code || 'N/A'}</p>
            <p class="text-sm text-slate-600 dark:text-slate-300 mb-4"><strong>Duration:</strong> ${service.duration ? `${service.duration} minutes` : 'N/A'}</p>
            <p class="text-sm text-slate-600 dark:text-slate-300 mb-4"><strong>Business Type:</strong> ${Helpers.capitalize(service.business_type)}</p>
            <p class="text-sm text-slate-600 dark:text-slate-300 mb-4"><strong>Status:</strong> ${Helpers.statusBadge(service.lifecycle_status)}</p>
          </div>
          <div class="p-6 border-t border-slate-200 dark:border-slate-800 flex justify-end">
            <button
              class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm"
              data-action="click->modal#close">Close</button>
          </div>
        </div>
      </div>
    `

    Helpers.openModal({ html: modalHTML })
  }

  /**
   * Opens a modal with a form to add a new service.
   */
  openAddServiceModal() {
    const modalId = `add-service-modal-${Helpers.randomId()}`

    const modalHTML = `
      <div id="${modalId}" class="flex justify-center items-center">
        <form
          action="${Helpers.retail_management_services_path()}"
          method="post"
          class="w-full max-w-4xl"
        >
          ${Helpers.formPostSecurityTags()}

          <div class="bg-white dark:bg-slate-900 rounded-2xl shadow-xl overflow-hidden ring-1 ring-slate-200 dark:ring-slate-700">
            <!-- Header -->
            <div class="bg-slate-50 dark:bg-slate-800/70 px-8 py-5 border-b border-slate-200 dark:border-slate-700">
              <h2 class="text-2xl font-semibold text-slate-900 dark:text-white flex items-center gap-3">
                <span class="inline-flex items-center justify-center w-10 h-10 rounded-full bg-blue-100 dark:bg-blue-900/50 text-blue-600 dark:text-blue-400">
                  <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/>
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                  </svg>
                </span>
                Add New Service
              </h2>
            </div>

            <!-- Form Body -->
            <div class="p-8 space-y-10 max-h-[75vh] overflow-y-auto">

              <!-- Basic Information -->
              <section>
                <h3 class="text-lg font-medium text-slate-900 dark:text-white mb-5 flex items-center gap-2">
                  <span class="w-1 h-6 bg-blue-500 rounded-full"></span>
                  Basic Information
                </h3>
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  <div class="lg:col-span-2">
                    <label for="service_name" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                      Service Name <span class="text-red-500">*</span>
                    </label>
                    <input
                      type="text"
                      name="service[name]"
                      id="service_name"
                      required
                      placeholder="Enter service name"
                      class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                    />
                  </div>

                  <div>
                    <label for="service_code" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                      Service Code
                    </label>
                    <input
                      type="text"
                      name="service[code]"
                      id="service_code"
                      placeholder="SRV-001"
                      class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                    />
                  </div>

                  <div>
                    <label for="service_duration" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                      Duration (minutes)
                    </label>
                    <input
                      type="number"
                      name="service[duration]"
                      id="service_duration"
                      placeholder="60"
                      class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                    />
                  </div>

                  <div>
                    <label for="service_business_type" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                      Business Type <span class="text-red-500">*</span>
                    </label>
                    <select
                      name="service[business_type]"
                      id="service_business_type"
                      required
                      class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                    >
                      <option value="">Select business type</option>
                      <option value="b2b">B2B</option>
                      <option value="b2c">B2C</option>
                    </select>
                  </div>

                  <div class="md:col-span-2 lg:col-span-3">
                    <label for="service_description" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                      Description
                    </label>
                    <textarea
                      name="service[description]"
                      id="service_description"
                      rows="3"
                      placeholder="Optional description of the service..."
                      class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all resize-none"
                    ></textarea>
                  </div>
                </div>
              </section>
            </div>

            <!-- Footer -->
            <div class="bg-slate-50 dark:bg-slate-800/70 px-8 py-5 border-t border-slate-200 dark:border-slate-700 flex justify-end gap-3">
              <button
                type="button"
                class="px-6 py-2.5 text-sm font-medium text-slate-700 dark:text-slate-300 bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-600 rounded-xl hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors"
                data-action="click->modal#close"
              >
                Cancel
              </button>
              <button
                type="submit"
                class="px-6 py-2.5 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded-xl transition-colors"
              >
                Create Service
              </button>
            </div>
          </div>
        </form>
      </div>
    `

    Helpers.openModal({ html: modalHTML })
  }

  contentHTML() {
    return `
      <div class="p-8 overflow-y-auto">
        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">

          <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-6">
            <div class="flex flex-wrap items-center gap-3 w-full sm:w-auto">
              <select class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:border-blue-600 focus:ring-blue-600 w-full sm:w-auto">
                <option selected="">Category: All</option>
                <option value="consultation">Consultation</option>
                <option value="repair">Repair</option>
                <option value="installation">Installation</option>
              </select>
              <select class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:border-blue-600 focus:ring-blue-600 w-full sm:w-auto">
                <option selected="">Business Type: All</option>
                <option value="b2b">B2B</option>
                <option value="b2c">B2C</option>
              </select>
            </div>
            <button
              data-action="click->${this.identifier}#openAddServiceModal"
              class="flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm whitespace-nowrap">
              <span class="material-symbols-outlined text-[20px]">add</span>
              Add New Service
            </button>
          </div>

          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Service Name</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Code</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Duration</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Business Type</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Status</th>
                  <th class="py-4 px-6 font-medium text-right whitespace-nowrap">Actions</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="servicesList" class="divide-y divide-slate-200 dark:divide-slate-800">
                ${this.servicesHTML()}
              </tbody>
            </table>
          </div>

          <div class="p-4 border-t border-slate-200 dark:border-slate-800 flex items-center justify-between">
            <span class="text-sm text-slate-500 dark:text-slate-400">Showing ${this.services.length} services</span>
            <div class="flex items-center gap-2">
              <button class="px-3 py-1 text-sm border border-slate-200 dark:border-slate-700 rounded-lg text-slate-400 cursor-not-allowed" disabled>Previous</button>
              <button class="px-3 py-1 text-sm border border-slate-200 dark:border-slate-700 rounded-lg text-slate-500 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors">Next</button>
            </div>
          </div>
        </div>
      </div>
    `
  }

  servicesHTML() {
    if (this.services.length === 0) {
      return `<tr><td colspan="6" class="text-center py-4 text-slate-500">No services found</td></tr>`
    }
    return this.services.map(service => `
      <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
        <td class="py-4 px-6 text-sm">
          <div class="flex items-center gap-4">
            <div class="w-12 h-12 rounded-lg bg-slate-100 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 flex items-center justify-center">
              <span class="material-symbols-outlined text-slate-400">build</span>
            </div>
            <div>
              <p
                 class="font-medium text-slate-900 dark:text-white cursor-pointer hover:underline"
                 data-action="click->${this.identifier}#showServiceDetails"
              >
                ${service.name}
              </p>
              <p class="text-xs text-slate-500">${service.description ? service.description.substring(0, 50) + (service.description.length > 50 ? '...' : '') : 'No description'}</p>
            </div>
          </div>
        </td>
        <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300 font-mono">${service.code || 'N/A'}</td>
        <td class="py-4 px-6 text-sm font-medium text-slate-900 dark:text-white">${service.duration ? `${service.duration} min` : 'N/A'}</td>
        <td class="py-4 px-6 text-sm">
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
            service.business_type === 'b2b'
              ? 'bg-blue-100 text-blue-800 dark:bg-blue-900/50 dark:text-blue-300'
              : 'bg-green-100 text-green-800 dark:bg-green-900/50 dark:text-green-300'
          }">
            ${Helpers.capitalize(service.business_type)}
          </span>
        </td>
        <td class="py-4 px-6 text-sm">
          ${Helpers.statusBadge(service.lifecycle_status)}
        </td>
        <td class="py-4 px-6 text-sm text-right">
          <div class="flex items-center justify-end gap-2">
            <button class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg"><span
                class="material-symbols-outlined text-[20px]">edit</span></button>
          </div>
        </td>
      </tr>
    `).join('')
  }
}
