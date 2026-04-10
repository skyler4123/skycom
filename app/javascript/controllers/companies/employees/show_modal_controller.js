// app/javascript/controllers/companies/employees/new_modal_controller.js

import { Controller } from "@hotwired/stimulus"

export default class Companies_Employees_ShowModalController extends Controller {
  /** @type {Employee|null} */
  employee = null

  connect() {
    console.log("HAHAHAHAHHA")
    this.employee = currentEmployee
    this.element.innerHTML = this.html()
  }

  html() {
    return `
      <!-- Modal Overlay -->
      <div class="flex items-center justify-center">
        <div class="relative w-full max-w-[640px] overflow-hidden rounded-xl bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 shadow-2xl">
          
          <div class="flex items-center justify-between border-b border-slate-200 dark:border-gray-800 px-6 py-4">
            <h3 class="text-xl font-bold text-slate-900 dark:text-white">Employee Details</h3>
            <button class="rounded-full p-2 text-slate-500 dark:text-gray-400 hover:bg-slate-100 dark:hover:bg-gray-800">
              <span class="material-symbols-outlined">close</span>
            </button>
          </div>

          <div class="p-6">
            <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start">
              <div class="size-32 shrink-0 overflow-hidden rounded-full border-4 border-blue-100 dark:border-blue-900/30 bg-slate-100 dark:bg-gray-800 shadow-lg">
                <img class="h-full w-full object-cover" src="https://lh3.googleusercontent.com/aida-public/AB6AXuCdl33Dx4Q4diQVh50H-7KAkXuzdatYq7KrBZOTTGLU0DeGklEda8V-NSs8PsfUx86lb_NW5SVSKPhAIUVFftXhbbcHXKiedlL_xcI-4G7YkcGkgf-S-hIDHDRq1Lw6E6STx6JzNq-UOJfa6m4c0jpuwMoSRM0lfdc1R3iF1AOXhod-vEyMZWMawCQoPrHuFMOmddzo7qRXdHmZ-ZdE9xmsu6_OzsjNmbn3WTjPYf4AKbj0OIfHNq41EMeVwOkRDCnZHOvUCGzSBgo" alt="Sarah Johnson" />
              </div>
              
              <div class="flex flex-1 flex-col text-center sm:text-left">
                <div class="flex flex-col gap-1">
                  <h2 class="text-2xl font-black text-slate-900 dark:text-white">Sarah Johnson</h2>
                  <p class="font-semibold text-blue-600 dark:text-blue-400">Senior Designer</p>
                </div>
                <div class="mt-4 flex flex-wrap justify-center gap-2 sm:justify-start">
                  <span class="inline-flex items-center rounded-lg bg-blue-100 dark:bg-blue-900/40 px-3 py-1 text-xs font-bold text-blue-700 dark:text-blue-300"> 
                    ACTIVE 
                  </span>
                  <span class="inline-flex items-center rounded-lg bg-slate-100 dark:bg-gray-800 px-3 py-1 text-xs font-medium text-slate-600 dark:text-gray-400"> 
                    ID: EMP-001 
                  </span>
                </div>
              </div>
            </div>

            <div class="mt-8 grid grid-cols-1 gap-6 border-t border-slate-200 dark:border-gray-800 pt-8 sm:grid-cols-2">
              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-blue-600 dark:text-blue-400">
                  <span class="material-symbols-outlined">corporate_fare</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Department</p>
                  <p class="text-sm font-semibold text-slate-900 dark:text-white">Creative Design</p>
                </div>
              </div>

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-blue-600 dark:text-blue-400">
                  <span class="material-symbols-outlined">mail</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Email Address</p>
                  <p class="text-sm font-semibold text-slate-900 dark:text-white">s.johnson@urbanazure.com</p>
                </div>
              </div>

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-blue-600 dark:text-blue-400">
                  <span class="material-symbols-outlined">call</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Phone Number</p>
                  <p class="text-sm font-semibold text-slate-900 dark:text-white">+1 (555) 012-3456</p>
                </div>
              </div>

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-blue-600 dark:text-blue-400">
                  <span class="material-symbols-outlined">calendar_today</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Join Date</p>
                  <p class="text-sm font-semibold text-slate-900 dark:text-white">March 12, 2021</p>
                </div>
              </div>
            </div>
          </div>

          <div class="flex items-center justify-end gap-3 border-t border-slate-200 dark:border-gray-800 bg-slate-50 dark:bg-gray-900/50 px-6 py-4">
            <button class="flex h-10 items-center justify-center rounded-lg border border-slate-200 dark:border-gray-700 bg-white dark:bg-gray-800 px-4 text-sm font-bold text-slate-700 dark:text-gray-200 hover:bg-slate-50 dark:hover:bg-gray-700 transition-colors">
              Archive Profile
            </button>
            <button class="flex h-10 items-center justify-center rounded-lg bg-blue-600 dark:bg-blue-500 px-6 text-sm font-bold text-white shadow-sm hover:bg-blue-700 dark:hover:bg-blue-600 transition-colors">
              Edit Details
            </button>
          </div>
        </div>
      </div>
    `
  }
}