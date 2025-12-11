import ApplicationController from "controllers/application_controller"

export default class LayoutController extends ApplicationController {
  initLayout() {
    this.element.innerHTML = this.layoutHTML()
  }

  layoutHTML() {
    return `
      <div class="bg-gray-50 dark:bg-gray-950">
        <div class="relative flex h-auto min-h-screen w-full flex-col group/design-root overflow-x-hidden">
          <div class="layout-container flex h-full grow flex-col">
            <div class="flex flex-1 justify-center">
              <div class="layout-content-container flex flex-col max-w-[960px] flex-1">
                <header class="flex items-center justify-between whitespace-nowrap px-10 py-3">
                  <div class="flex items-center gap-4 text-slate-900 dark:text-slate-100">
                    <span class="material-symbols-outlined text-2xl text-indigo-600">all_inclusive</span>
                    <h2 class="text-slate-900 dark:text-slate-100 text-lg font-bold leading-tight tracking-[-0.015em]">
                      Skycom</h2>
                  </div>
                  <div class="flex flex-1 justify-end gap-2 items-center">
                    <div class="flex items-center gap-2">
                      <div
                        class="bg-center bg-no-repeat aspect-square bg-cover rounded-full h-10 w-10 border border-slate-200 dark:border-slate-700"
                        style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuDmCMcaKuxM-L3kekIel30wVgf_J-ssrf86FqOelUJrmeAHwneIxkCor7hKn3SzOtbLg3DrSVpbI77hxo-i174Ll7V-lQ8CTCQB3H9YEA5_LSG8vyi_FynSf8l4w3lgYkc2uFLpD4U1w_DzdTIiCUzYkrAkVoZumb-iT_CjUsLofbZCfryp_hfJBATT8XUgqjbHSZdKEhdoREZiwf1ZCevLreCxK463hwZhGxwb6xu2NoSIYjbWxlfEmD5ABwPppLeyiUqyCCWWVw0");'>
                      </div>
                      <div class="flex flex-col">
                        <p class="text-slate-900 dark:text-slate-100 text-sm font-bold leading-tight">Alice
                          Smith</p>
                      </div>
                    </div>
                    <button
                      class="flex min-w-[84px] max-w-[480px] cursor-pointer items-center justify-center overflow-hidden rounded-lg h-10 px-4 bg-slate-200 dark:bg-slate-700 text-slate-900 dark:text-slate-100 text-sm font-bold leading-normal tracking-[0.015em]">
                      <span class="truncate">Sign Out</span>
                    </button>
                  </div>
                </header>
                <main class="w-full flex justify-center py-12 px-4">
                  <div
                    class="flex flex-col w-full max-w-[600px] gap-8 bg-white dark:bg-slate-900 rounded-xl p-8 border border-slate-200 dark:border-slate-800 shadow-sm">
                    <div class="flex flex-col gap-2">
                      <h1 class="text-slate-900 dark:text-slate-100 text-3xl font-bold leading-tight tracking-[-0.015em]">
                        Create Your Retail Company</h1>
                      <p class="text-slate-600 dark:text-slate-400 text-base font-normal">Set up your
                        workspace to manage inventory, sales, and more.</p>
                    </div>
                    <form class="flex flex-col gap-6">
                      <div class="flex flex-col gap-2">
                        <label class="text-slate-900 dark:text-slate-100 text-sm font-bold leading-tight"
                          for="companyName">Company Name</label>
                        <input
                          class="flex w-full min-w-0 flex-1 resize-none overflow-hidden rounded-lg text-slate-900 dark:text-slate-100 focus:outline-0 focus:ring-0 border border-slate-300 dark:border-slate-700 bg-white dark:bg-gray-950 focus:border-indigo-600 h-12 px-4 text-base font-normal leading-normal placeholder:text-slate-400"
                          id="companyName" placeholder="e.g. Skyline Boutique" type="text" />
                      </div>
                      <div class="flex flex-col gap-2">
                        <label class="text-slate-900 dark:text-slate-100 text-sm font-bold leading-tight"
                          for="companyAddress">Company Address</label>
                        <input
                          class="flex w-full min-w-0 flex-1 resize-none overflow-hidden rounded-lg text-slate-900 dark:text-slate-100 focus:outline-0 focus:ring-0 border border-slate-300 dark:border-slate-700 bg-white dark:bg-gray-950 focus:border-indigo-600 h-12 px-4 text-base font-normal leading-normal placeholder:text-slate-400"
                          id="companyAddress" placeholder="123 Retail Ave, Commerce City" type="text" />
                      </div>
                      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div class="flex flex-col gap-2">
                          <label class="text-slate-900 dark:text-slate-100 text-sm font-bold leading-tight"
                            for="retailCategory">Retail Category</label>
                          <div class="relative">
                            <select
                              class="flex w-full min-w-0 flex-1 resize-none overflow-hidden rounded-lg text-slate-900 dark:text-slate-100 focus:outline-0 focus:ring-0 border border-slate-300 dark:border-slate-700 bg-white dark:bg-gray-950 focus:border-indigo-600 h-12 px-4 text-base font-normal leading-normal appearance-none"
                              id="retailCategory">
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
                          <label class="text-slate-900 dark:text-slate-100 text-sm font-bold leading-tight"
                            for="storeCount">Number of Locations</label>
                          <input
                            class="flex w-full min-w-0 flex-1 resize-none overflow-hidden rounded-lg text-slate-900 dark:text-slate-100 focus:outline-0 focus:ring-0 border border-slate-300 dark:border-slate-700 bg-white dark:bg-gray-950 focus:border-indigo-600 h-12 px-4 text-base font-normal leading-normal placeholder:text-slate-400"
                            id="storeCount" min="1" placeholder="1" type="number" />
                        </div>
                      </div>
                      <div class="flex flex-col gap-2">
                        <label class="text-slate-900 dark:text-slate-100 text-sm font-bold leading-tight"
                          for="description">Additional Details</label>
                        <textarea
                          class="flex w-full min-w-0 flex-1 resize-none overflow-hidden rounded-lg text-slate-900 dark:text-slate-100 focus:outline-0 focus:ring-0 border border-slate-300 dark:border-slate-700 bg-white dark:bg-gray-950 focus:border-indigo-600 min-h-[100px] p-4 text-base font-normal leading-normal placeholder:text-slate-400"
                          id="description" placeholder="Describe your store or any specific needs..."></textarea>
                      </div>
                      <div class="pt-4">
                        <button
                          class="flex w-full cursor-pointer items-center justify-center overflow-hidden rounded-lg h-12 px-5 bg-indigo-600 hover:bg-blue-600 transition-colors text-white text-base font-bold leading-normal tracking-[0.015em]"
                          type="button">
                          Create Company
                        </button>
                      </div>
                    </form>
                  </div>
                </main>
                <footer class="flex flex-col gap-6 px-5 py-10 text-center @container mt-auto">
                  <div class="flex flex-wrap items-center justify-center gap-6 @[480px]:flex-row @[480px]:justify-around">
                    <a class="text-slate-600 dark:text-slate-400 text-base font-normal leading-normal min-w-40" href="#">About
                      Us</a>
                    <a class="text-slate-600 dark:text-slate-400 text-base font-normal leading-normal min-w-40"
                      href="#">Contact</a>
                    <a class="text-slate-600 dark:text-slate-400 text-base font-normal leading-normal min-w-40"
                      href="#">Privacy Policy</a>
                  </div>
                  <div class="flex flex-wrap justify-center gap-4">
                    <a href="#">
                      <svg class="text-slate-600 dark:text-slate-400" fill="none" height="24" stroke="currentColor"
                        stroke-linecap="round" stroke-linejoin="round" stroke-width="2" viewBox="0 0 24 24" width="24"
                        xmlns="http://www.w3.org/2000/svg">
                        <path d="M18 2h-3a5 5 0 0 0-5 5v3H7v4h3v8h4v-8h3l1-4h-4V7a1 1 0 0 1 1-1h3z"></path>
                      </svg>
                    </a>
                    <a href="#">
                      <svg class="text-slate-600 dark:text-slate-400" fill="none" height="24" stroke="currentColor"
                        stroke-linecap="round" stroke-linejoin="round" stroke-width="2" viewBox="0 0 24 24" width="24"
                        xmlns="http://www.w3.org/2000/svg">
                        <path
                          d="M22 4s-.7 2.1-2 3.4c1.6 1.4 3.3 4.9 3.3 4.9-6.1-1.4-6.1-1.4-6.1-1.4-.4 5.4-1.3 6.6-1.3 6.6s-1.3-.8-3.1-2.8c-2.8-3.1-8.3-4-8.3-4s.9 2.1 2.8 3.7c-2.5-.9-5.1-3.1-5.1-3.1s2.1.8 4.2 2.2c-1.4-.5-2.8-1.5-2.8-1.5s4.1 4.2 7.7 4.6c-1.3-1.3-1.3-3.3-1.3-3.3s-3.1-.1-4.9-2.5c2.3.1 4.2.8 4.2.8s-.9-1.9-2.8-3.7c2.5.5 4.9 1.4 4.9 1.4s-.5-2.1-2.8-4.2c2.3.5 4.2 1.4 4.2 1.4s-.8-2.5-3.1-4.2c2.5.8 4.9 1.9 4.9 1.9s-.9-2.8-3.7-4.9c2.5.8 4.9 1.9 4.9 1.9s-.9-2.8-3.7-4.9c2.5.8 4.9 1.9 4.9 1.9s-1-2.8-3.7-4.9c2.5.8 4.9 1.9 4.9 1.9z">
                        </path>
                      </svg>
                    </a>
                    <a href="#">
                      <svg class="text-slate-600 dark:text-slate-400" fill="none" height="24" stroke="currentColor"
                        stroke-linecap="round" stroke-linejoin="round" stroke-width="2" viewBox="0 0 24 24" width="24"
                        xmlns="http://www.w3.org/2000/svg">
                        <path d="M16 8a6 6 0 0 1 6 6v7h-4v-7a2 2 0 0 0-2-2 2 2 0 0 0-2 2v7h-4v-7a6 6 0 0 1 6-6z"></path>
                        <rect height="12" width="4" x="2" y="9"></rect>
                        <circle cx="4" cy="4" r="2"></circle>
                      </svg>
                    </a>
                  </div>
                  <p class="text-slate-600 dark:text-slate-400 text-base font-normal leading-normal">© 2024 Skycom,
                    Inc. All rights reserved.</p>
                </footer>
              </div>
            </div>
          </div>
        </div>
      </div>
    `
  }
}
