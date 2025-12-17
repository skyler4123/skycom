import LayoutController from "controllers/layout_controller"
import { csrfTokenTag } from "controllers/helpers"
import { CURRENCIES, TIMEZONES, COUNTRIES } from "controllers/constants"
import { ROUTES } from "controllers/routes"

export default class CompanyGroup_NewController extends LayoutController {

  contentHTML() {
    return `
      <main class="w-full h-full flex justify-center items-center">
        <div
          class="flex flex-col w-4/5 p-8 gap-8 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
          <div class="flex flex-col gap-2">
            <h1 class="text-slate-900 dark:text-slate-100 text-3xl font-bold leading-tight tracking-[-0.015em]">
              Create Your Company</h1>
            <p class="text-slate-600 dark:text-slate-400 text-base font-normal">Set up your
              workspace to manage inventory, sales, and more.</p>
          </div>

          <!-- Form -->
          <form
            action="${ROUTES.createCompanyGroupPath}"
            data-method="post
            accept-charset="UTF-8"
            method="post"
            class="flex flex-col gap-6">
            ${csrfTokenTag()}
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6 h-18">
              <div class="flex flex-col gap-2">
                <label class="text-slate-900 dark:text-slate-100 text-sm font-bold leading-tight" for="companyName">Company
                  Name <span class="text-red-500">*</span></label>
                <input
                  class="flex w-full min-w-0 flex-1 resize-none overflow-hidden rounded-lg text-slate-900 dark:text-slate-100 focus:outline-0 focus:ring-0 border border-slate-300 dark:border-slate-700 bg-white dark:bg-gray-950 focus:border-indigo-600 h-12 px-4 text-base font-normal leading-normal placeholder:text-slate-400"
                  id="companyName" name="company_group[name]" placeholder="e.g. Skyline Boutique" type="text" required />
              </div>
              <div class="flex flex-col gap-2">
                <label class="text-slate-900 dark:text-slate-100 text-sm font-bold leading-tight" for="phoneNumber">Phone
                  Number <span class="text-red-500">*</span></label>
                <input
                  class="flex w-full min-w-0 flex-1 resize-none overflow-hidden rounded-lg text-slate-900 dark:text-slate-100 focus:outline-0 focus:ring-0 border border-slate-300 dark:border-slate-700 bg-white dark:bg-gray-950 focus:border-indigo-600 h-12 px-4 text-base font-normal leading-normal placeholder:text-slate-400"
                  id="phoneNumber" name="company_group[phone_number]" placeholder="+1 (555) 123-4567" type="tel" required />
              </div>
            </div>

            <div class="flex flex-col gap-2">
              <label class="text-slate-900 dark:text-slate-100 text-sm font-bold leading-tight" for="country">Country
                <span class="text-red-500">*</span></label>
              <div class="relative">
                <select
                  class="flex w-full min-w-0 flex-1 resize-none overflow-hidden rounded-lg text-slate-900 dark:text-slate-100 focus:outline-0 focus:ring-0 border border-slate-300 dark:border-slate-700 bg-white dark:bg-gray-950 focus:border-indigo-600 h-12 px-4 text-base font-normal leading-normal appearance-none"
                  id="country" name="company_group[country]" required>
                  <option disabled="" selected="" value="">Select a country</option>
                  ${Object.entries(COUNTRIES).map(([code, name]) => {
                    return `<option value="${code}">${name}</option>`
                  }).join('')}
                </select>
                <div class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-4 text-slate-500">
                  <span class="material-symbols-outlined">expand_more</span>
                </div>
              </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div class="flex flex-col gap-2">
                <label class="text-slate-900 dark:text-slate-100 text-sm font-bold leading-tight" for="retailCategory">
                  Category <span class="text-red-500">*</span></label>
                <div class="relative">
                  <select
                    class="flex w-full min-w-0 flex-1 resize-none overflow-hidden rounded-lg text-slate-900 dark:text-slate-100 focus:outline-0 focus:ring-0 border border-slate-300 dark:border-slate-700 bg-white dark:bg-gray-950 focus:border-indigo-600 h-12 px-4 text-base font-normal leading-normal appearance-none"
                    id="retailCategory" name="company_group[business_type]" required>
                    <option disabled="" selected="" value="">Select a category</option>
                    <option value="retail">Retail</option>
                    <option value="education">Education</option>
                    <option value="hospital">Hospital</option>
                    <option value="restaurant">Restaurant</option>
                    <option value="fitness">Fitness</option>
                  </select>
                  <div class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-4 text-slate-500">
                    <span class="material-symbols-outlined">expand_more</span>
                  </div>
                </div>
              </div>
              
              <div class="flex flex-col gap-2">
                <label class="text-slate-900 dark:text-slate-100 text-sm font-bold leading-tight" for="timezone">Timezone
                  <span class="text-red-500">*</span></label>
                <div class="relative">
                  <select
                    class="flex w-full min-w-0 flex-1 resize-none overflow-hidden rounded-lg text-slate-900 dark:text-slate-100 focus:outline-0 focus:ring-0 border border-slate-300 dark:border-slate-700 bg-white dark:bg-gray-950 focus:border-indigo-600 h-12 px-4 text-base font-normal leading-normal appearance-none"
                    id="timezone" name="company_group[timezone]" required>
                    <option disabled="" selected="" value="">Select timezone</option>
                    ${Object.entries(TIMEZONES).map(([key, value]) => {
                      return `<option value="${value}">UTC ${key}</option>`
                    }).join('')}
                  </select>
                  <div class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-4 text-slate-500">
                    <span class="material-symbols-outlined">expand_more</span>
                  </div>
                </div>
              </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div class="flex flex-col gap-2">
                <label class="text-slate-900 dark:text-slate-100 text-sm font-bold leading-tight" for="currencyCode">Default
                  Currency <span class="text-red-500">*</span></label>
                <div class="relative">
                  <select
                    class="flex w-full min-w-0 flex-1 resize-none overflow-hidden rounded-lg text-slate-900 dark:text-slate-100 focus:outline-0 focus:ring-0 border border-slate-300 dark:border-slate-700 bg-white dark:bg-gray-950 focus:border-indigo-600 h-12 px-4 text-base font-normal leading-normal appearance-none"
                    id="currencyCode" name="company_group[currency]" required>
                    <option disabled="" selected="" value="">Select currency</option>
                    ${Object.entries(CURRENCIES).map(([key, value]) => {
                      return `<option value="${key}">${value}</option>`
                    }).join('')}
                  </select>
                  <div class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-4 text-slate-500">
                    <span class="material-symbols-outlined">expand_more</span>
                  </div>
                </div>
              </div>

              <div class="flex flex-col gap-2">
                <label class="text-slate-900 dark:text-slate-100 text-sm font-bold leading-tight" for="taxId">Tax ID / VAT
                  Number</label>
                <input
                  class="flex w-full min-w-0 flex-1 resize-none overflow-hidden rounded-lg text-slate-900 dark:text-slate-100 focus:outline-0 focus:ring-0 border border-slate-300 dark:border-slate-700 bg-white dark:bg-gray-950 focus:border-indigo-600 h-12 px-4 text-base font-normal leading-normal placeholder:text-slate-400"
                  id="taxId" name="company_group[tax_id]" placeholder="e.g. 12-3456789" type="text" />
              </div>

            </div>

            <div class="flex flex-col gap-2">
              <label class="text-slate-900 dark:text-slate-100 text-sm font-bold leading-tight" for="description">Additional
                Details</label>
              <textarea
                class="flex w-full min-w-0 flex-1 resize-none overflow-hidden rounded-lg text-slate-900 dark:text-slate-100 focus:outline-0 focus:ring-0 border border-slate-300 dark:border-slate-700 bg-white dark:bg-gray-950 focus:border-indigo-600 min-h-[100px] p-4 text-base font-normal leading-normal placeholder:text-slate-400"
                id="description" name="company_group[description" placeholder="Describe your store or any specific needs..."></textarea>
            </div>

            <div class="pt-4">
              <button
                class="flex w-full cursor-pointer items-center justify-center overflow-hidden rounded-lg h-12 px-5 bg-indigo-600 hover:bg-blue-600 transition-colors text-white text-base font-bold leading-normal tracking-[0.015em]"
                type="submit">
                Create Company
              </button>
            </div>
          </form>
          <!-- Form -->

        </div>
      </main>
    `
  }
}
