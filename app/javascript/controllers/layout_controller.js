import { Controller } from "@hotwired/stimulus"
import { ROUTES } from "controllers/routes"

export default class LayoutController extends Controller {
  initialize() {
    this.initLayout()
  }
  
  initLayout() {
    this.element.innerHTML = this.layoutHTML()
  }

  contentHTML() {
    return `
      <!-- ContentHTML -->
    `
  }

  layoutHTML() {
    return `
      <div class="bg-gray-50 dark:bg-gray-950">
        <div class="relative flex h-auto min-h-screen w-full flex-col group/design-root overflow-x-hidden">
          <div class="layout-container flex h-full grow flex-col">
            <div class="flex flex-1 justify-center">
              <div class="layout-content-container flex flex-col flex-1">
                <header class="flex items-center justify-between whitespace-nowrap px-10 py-3">
                  <a
                    href="${ROUTES.rootPath}"
                    class="flex items-center gap-4 text-slate-900 dark:text-slate-100">
                    <span class="material-symbols-outlined text-2xl text-indigo-600">all_inclusive</span>
                    <h2 class="text-slate-900 dark:text-slate-100 text-lg font-bold leading-tight tracking-[-0.015em]">
                      Skycom</h2>
                  </a>

                  <!-- Navbar start -->
                  <nav class="flex flex-1 justify-around items-center px-4">
                    <a class="text-sm font-medium text-slate-700 dark:text-slate-300 hover:text-indigo-600 dark:hover:text-indigo-600 transition-colors"
                      href="/home/retail">Retail</a>
                    <a class="text-sm font-medium text-slate-700 dark:text-slate-300 hover:text-indigo-600 dark:hover:text-indigo-600 transition-colors"
                      href="/home/education">Education</a>
                    <a class="text-sm font-medium text-slate-700 dark:text-slate-300 hover:text-indigo-600 dark:hover:text-indigo-600 transition-colors"
                      href="/home/hospital">Hospital</a>
                    <a class="text-sm font-medium text-slate-700 dark:text-slate-300 hover:text-indigo-600 dark:hover:text-indigo-600 transition-colors"
                      href="/home/restaurant">Restaurant</a>
                    <a class="text-sm font-medium text-slate-700 dark:text-slate-300 hover:text-indigo-600 dark:hover:text-indigo-600 transition-colors whitespace-nowrap"
                      href="/home/food_service">Food Service</a>
                    <a class="text-sm font-medium text-slate-700 dark:text-slate-300 hover:text-indigo-600 dark:hover:text-indigo-600 transition-colors whitespace-nowrap"
                      href="home/sport_fitness">Sport & Fitness</a>
                  </nav>
                  <!-- Nabar end -->

                  <!-- Authentication start -->
                  <div class="flex justify-end gap-2 items-center" data-controller="header--authentication"></div>
                  <!-- Authentication end -->
                </header>

                ${this.contentHTML()}

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
