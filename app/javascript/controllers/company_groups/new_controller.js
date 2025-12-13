import LayoutController from "controllers/layout_controller"
import { csrfTokenTag } from "controllers/helpers"

export default class CompanyGroup_NewController extends LayoutController {

  contentHTML() {
    return `
      <main class="w-full h-full flex justify-center items-center">
        <div
          class="flex flex-col w-4/5 p-8 gap-8 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
          <div class="flex flex-col gap-2">
            <h1 class="text-slate-900 dark:text-slate-100 text-3xl font-bold leading-tight tracking-[-0.015em]">
              Create Your Retail Company</h1>
            <p class="text-slate-600 dark:text-slate-400 text-base font-normal">Set up your
              workspace to manage inventory, sales, and more.</p>
          </div>

          <!-- Form -->
          <form
          action="/company_groups"
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
                  id="companyName" name="company_group[name]" placeholder="e.g. Skyline Boutique" type="text" />
              </div>
              <div class="flex flex-col gap-2">
                <label class="text-slate-900 dark:text-slate-100 text-sm font-bold leading-tight" for="phoneNumber">Phone
                  Number <span class="text-red-500">*</span></label>
                <input
                  class="flex w-full min-w-0 flex-1 resize-none overflow-hidden rounded-lg text-slate-900 dark:text-slate-100 focus:outline-0 focus:ring-0 border border-slate-300 dark:border-slate-700 bg-white dark:bg-gray-950 focus:border-indigo-600 h-12 px-4 text-base font-normal leading-normal placeholder:text-slate-400"
                  id="phoneNumber" name="company_group[phone_number]" placeholder="+1 (555) 123-4567" type="tel" />
              </div>
            </div>

            <div class="flex flex-col gap-2 h-18">
              <label class="text-slate-900 dark:text-slate-100 text-sm font-bold leading-tight" for="companyAddress">Company
                Address <span class="text-red-500">*</span></label>
              <input
                class="flex w-full min-w-0 flex-1 resize-none overflow-hidden rounded-lg text-slate-900 dark:text-slate-100 focus:outline-0 focus:ring-0 border border-slate-300 dark:border-slate-700 bg-white dark:bg-gray-950 focus:border-indigo-600 h-12 px-4 text-base font-normal leading-normal placeholder:text-slate-400"
                id="companyAddress" name="company_group[address]" placeholder="123 Retail Ave, Commerce City" type="text" />
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div class="flex flex-col gap-2">
                <label class="text-slate-900 dark:text-slate-100 text-sm font-bold leading-tight" for="retailCategory">Retail
                  Category <span class="text-red-500">*</span></label>
                <div class="relative">
                  <select
                    class="flex w-full min-w-0 flex-1 resize-none overflow-hidden rounded-lg text-slate-900 dark:text-slate-100 focus:outline-0 focus:ring-0 border border-slate-300 dark:border-slate-700 bg-white dark:bg-gray-950 focus:border-indigo-600 h-12 px-4 text-base font-normal leading-normal appearance-none"
                    id="retailCategory" name="company_group[business_type]">
                    <option disabled="" selected="" value="">Select a category</option>
                    <option value="fashion">Fashion & Apparel</option>
                    <option value="electronics">Electronics & Gadgets</option>
                    <option value="grocery">Grocery & Supermarket</option>
                    <option value="home">Home & Garden</option>
                    <option value="beauty">Health & Beauty</option>
                    <option value="other">Other</option>
                  </select>
                  <div class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-4 text-slate-500">
                    <span class="material-symbols-outlined">expand_more</span>
                  </div>
                </div>
              </div>
              <div class="flex flex-col gap-2">
                <label class="text-slate-900 dark:text-slate-100 text-sm font-bold leading-tight" for="storeCount">Number of
                  Locations <span class="text-red-500">*</span></label>
                <input
                  class="flex w-full min-w-0 flex-1 resize-none overflow-hidden rounded-lg text-slate-900 dark:text-slate-100 focus:outline-0 focus:ring-0 border border-slate-300 dark:border-slate-700 bg-white dark:bg-gray-950 focus:border-indigo-600 h-12 px-4 text-base font-normal leading-normal placeholder:text-slate-400"
                  id="storeCount" name="company_group[company_count]" min="1" placeholder="1" type="number" />
              </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div class="flex flex-col gap-2">
                <label class="text-slate-900 dark:text-slate-100 text-sm font-bold leading-tight" for="currencyCode">Default
                  Currency <span class="text-red-500">*</span></label>
                <div class="relative">
                  <select
                    class="flex w-full min-w-0 flex-1 resize-none overflow-hidden rounded-lg text-slate-900 dark:text-slate-100 focus:outline-0 focus:ring-0 border border-slate-300 dark:border-slate-700 bg-white dark:bg-gray-950 focus:border-indigo-600 h-12 px-4 text-base font-normal leading-normal appearance-none"
                    id="currencyCode" name="company_group[currency]">
                    <option disabled="" selected="" value="">Select currency</option>
                    <option value="USD">USD - U.S. Dollar</option>
                    <option value="EUR">EUR - Euro</option>
                    <option value="GBP">GBP - British Pound</option>
                    <option value="VND">VND - Vietnamese Dong</option>
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

              <div class="flex flex-col gap-2">
                <label class="text-slate-900 dark:text-slate-100 text-sm font-bold leading-tight" for="timezone">Timezone
                  <span class="text-red-500">*</span></label>
                <div class="relative">
                  <select
                    class="flex w-full min-w-0 flex-1 resize-none overflow-hidden rounded-lg text-slate-900 dark:text-slate-100 focus:outline-0 focus:ring-0 border border-slate-300 dark:border-slate-700 bg-white dark:bg-gray-950 focus:border-indigo-600 h-12 px-4 text-base font-normal leading-normal appearance-none"
                    id="timezone" name="company_group[timezone]">
                    <option disabled="" selected="" value="">Select timezone</option>
                    <option value="America/New_York">Eastern Time (EST)</option>
                    <option value="Europe/London">London Time (GMT)</option>
                    <option value="Asia/Ho_Chi_Minh">Ho Chi Minh Time (ICT)</option>
                  </select>
                  <div class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-4 text-slate-500">
                    <span class="material-symbols-outlined">expand_more</span>
                  </div>
                </div>
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
