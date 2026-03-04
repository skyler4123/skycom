import * as Helpers from "controllers/helpers"
import { Controller } from "@hotwired/stimulus"


export default class Companies_Branches_NewBranchModalController extends Controller {
  connect() {
    console.log(this)
    this.element.innerHTML = this.modalHTML()
  }

  modalHTML() {
    const modalId = `add-branch-modal-${Helpers.randomId()}`
    return `
      <div id="${modalId}" class="flex justify-center items-center">
        <form
          action="${Helpers.new_company_branches_path(currentCompany.id)}"
          method="post"
          class="w-full max-w-4xl"
        >
          ${Helpers.formPostSecurityTags()}

          <div class="bg-white dark:bg-slate-900 rounded-2xl shadow-xl overflow-hidden ring-1 ring-slate-200 dark:ring-slate-700">
            <!-- Header -->
            <div class="flex flex-row justify-between bg-slate-50 dark:bg-slate-800/70 px-8 py-5 border-b border-slate-200 dark:border-slate-700">
              <h2 class="text-2xl font-semibold text-slate-900 dark:text-white flex items-center gap-3">
                <span class="inline-flex items-center justify-center w-10 h-10 rounded-full bg-blue-100 dark:bg-blue-900/50 text-blue-600 dark:text-blue-400">
                  <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h-4m-6 0H5m4 0h6m2-8h4m-4-4h4m-8 4h.01M9 8h.01"/>
                  </svg>
                </span>
                Add New Branch
              </h2>
              <button 
                class="flex items-center justify-center w-8 h-8 rounded-full hover:bg-slate-200 dark:hover:bg-slate-700 text-slate-500 transition-colors cursor-pointer" 
                ${Helpers.closeModalAction()}
              >
                <span class="material-symbols-outlined text-2xl">close</span>
              </button>
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
                    <label for="branch_name" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                      Branch Name <span class="text-red-500">*</span>
                    </label>
                    <input
                      type="text"
                      name="branch[name]"
                      id="branch_name"
                      required
                      placeholder="Enter branch name"
                      class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                    />
                  </div>

                  <div>
                    <label for="branch_phone_number" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                      Phone Number
                    </label>
                    <input
                      type="tel"
                      name="branch[phone_number]"
                      id="branch_phone_number"
                      placeholder="+1 (555) 000-0000"
                      class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                    />
                  </div>

                  <div class="md:col-span-2 lg:col-span-3">
                    <label for="branch_description" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                      Description
                    </label>
                    <textarea
                      name="branch[description]"
                      id="branch_description"
                      rows="3"
                      placeholder="Optional description of the branch..."
                      class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all resize-none"
                    ></textarea>
                  </div>
                </div>
              </section>

              <!-- Location -->
              <section>
                <h3 class="text-lg font-medium text-slate-900 dark:text-white mb-5 flex items-center gap-2">
                  <span class="w-1 h-6 bg-green-500 rounded-full"></span>
                  Location
                </h3>
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  <div class="lg:col-span-3">
                    <label for="branch_address_line_1" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                      Address Line 1
                    </label>
                    <input
                      type="text"
                      name="branch[address_line_1]"
                      id="branch_address_line_1"
                      placeholder="Street address"
                      class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                    />
                  </div>

                  <div>
                    <label for="branch_city" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">City</label>
                    <input type="text" name="branch[city]" id="branch_city" placeholder="City" class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"/>
                  </div>

                  <div>
                    <label for="branch_postal_code" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Postal Code</label>
                    <input type="text" name="branch[postal_code]" id="branch_postal_code" placeholder="ZIP/Postal" class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"/>
                  </div>

                  <div>
                    <label for="branch_country" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Country</label>
                    <input type="text" name="branch[country]" id="branch_country" placeholder="Country" class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"/>
                  </div>

                  <div>
                    <label for="branch_timezone" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Timezone</label>
                    <input type="text" name="branch[timezone]" id="branch_timezone" placeholder="e.g., America/New_York" class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"/>
                  </div>
                </div>
              </section>

              <!-- Business Details -->
              <section>
                <h3 class="text-lg font-medium text-slate-900 dark:text-white mb-5 flex items-center gap-2">
                  <span class="w-1 h-6 bg-purple-500 rounded-full"></span>
                  Business Details
                </h3>
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  <div>
                    <label for="branch_registration_number" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Registration Number</label>
                    <input type="text" name="branch[registration_number]" id="branch_registration_number" class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"/>
                  </div>

                  <div>
                    <label for="branch_vat_id" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">VAT ID</label>
                    <input type="text" name="branch[vat_id]" id="branch_vat_id" class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"/>
                  </div>

                  <div>
                    <label for="branch_tax_id" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Tax ID</label>
                    <input type="text" name="branch[tax_id]" id="branch_tax_id" class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"/>
                  </div>

                  <div>
                    <label for="branch_ownership_type" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Ownership Type</label>
                    <input type="text" name="branch[ownership_type]" id="branch_ownership_type" placeholder="e.g., Franchise" class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"/>
                  </div>

                  <div>
                    <label for="branch_business_type" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Business Type</label>
                    <input type="text" name="branch[business_type]" id="branch_business_type" placeholder="e.g., Retail" class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"/>
                  </div>

                  <div>
                    <label for="branch_currency" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Currency</label>
                    <input type="text" name="branch[currency]" id="branch_currency" placeholder="USD" class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"/>
                  </div>

                  <div>
                    <label for="branch_fiscal_year_end_month" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Fiscal Year End Month</label>
                    <input type="number" name="branch[fiscal_year_end_month]" id="branch_fiscal_year_end_month" min="1" max="12" placeholder="12" class="w-full px-4 py-3 bg-slate-50 dark:bg-slate-800/50 border border-slate-300 dark:border-slate-600 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"/>
                  </div>
                </div>
              </section>
            </div>

            <!-- Footer -->
            <div class="bg-slate-50 dark:bg-slate-800/70 px-8 py-5 border-t border-slate-200 dark:border-slate-700 flex justify-end gap-4">
              <button
                type="button"
                class="px-6 py-3 text-slate-700 dark:text-slate-300 bg-white dark:bg-slate-700 border border-slate-300 dark:border-slate-600 rounded-xl font-medium hover:bg-slate-100 dark:hover:bg-slate-600 transition-all"
                ${Helpers.closeModalAction()}
              >
                Cancel
              </button>
              <button
                type="submit"
                class="px-6 py-3 bg-blue-600 hover:bg-blue-700 text-white rounded-xl font-medium shadow-md hover:shadow-lg transition-all"
              >
                Save Branch
              </button>
            </div>
          </div>
        </form>
      </div>
    `
  }
}
