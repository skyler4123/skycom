import { Controller } from "@hotwired/stimulus"
import { currentUser } from "controllers/helpers/auth_helpers"

export default class Users_ShowModalController extends Controller {
  connect() {
    const user = currentUser()
    
    if (user) {
      this.element.innerHTML = this.html(user)
    }
  }

  html(user) {
    const name = user.name || user.email || "User"
    const email = user.email || "N/A"
    const avatarUrl = user.avatar_url || user.metadata?.avatar_url || "https://lh3.googleusercontent.com/aida-public/AB6AXuCdl33Dx4Q4diQVh50H-7KAkXuzdatYq7KrBZOTTGLU0DeGklEda8V-NSs8PsfUx86lb_NW5SVSKPhAIUVFftXhbbcHXKiedlL_xcI-4G7YkcGkgf-S-hIDHDRq1Lw6E6STx6JzNq-UOJfa6m4c0jpuwMoSRM0lfdc1R3iF1AOXhod-vEyMZWMawCQoPrHuFMOmddzo7qRXdHmZ-ZdE9xmsu6_OzsjNmbn3WTjPYf4AKbj0OIfHNq41EMeVwOkRDCnZHOvUCGzSBgo"

    return `
      <div class="flex items-center justify-center">
        <div class="relative w-full max-w-[480px] overflow-hidden rounded-xl bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 shadow-2xl">
          
          <div class="flex items-center justify-between border-b border-slate-200 dark:border-gray-800 px-6 py-4">
            <h3 class="text-xl font-bold text-slate-900 dark:text-white">Profile</h3>
            <button data-action="click->${this.identifier}#close" class="rounded-full p-2 text-slate-500 dark:text-gray-400 hover:bg-slate-100 dark:hover:bg-gray-800">
              <span class="material-symbols-outlined">close</span>
            </button>
          </div>

          <div class="p-6">
            <div class="flex flex-col items-center gap-4">
              <div class="size-24 shrink-0 overflow-hidden rounded-full border-4 border-blue-100 dark:border-blue-900/30 bg-slate-100 dark:bg-gray-800 shadow-lg">
                <img class="h-full w-full object-cover" src="${avatarUrl}" alt="${name}" />
              </div>
              <div class="text-center">
                <h2 class="text-2xl font-black text-slate-900 dark:text-white">${name}</h2>
                <p class="text-sm font-semibold text-blue-600 dark:text-blue-400">${email}</p>
              </div>
            </div>

            <div class="mt-6 space-y-4 border-t border-slate-200 dark:border-gray-800 pt-6">
              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-blue-600 dark:text-blue-400">
                  <span class="material-symbols-outlined">badge</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">User ID</p>
                  <p class="text-sm font-semibold text-slate-900 dark:text-white">${user.id?.substring(0, 8) || 'N/A'}</p>
                </div>
              </div>

              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-blue-600 dark:text-blue-400">
                  <span class="material-symbols-outlined">account_circle</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Account Type</p>
                  <p class="text-sm font-semibold text-slate-900 dark:text-white">${user.provider ? user.provider.charAt(0).toUpperCase() + user.provider.slice(1) : 'Email'}</p>
                </div>
              </div>

              ${user.created_at ? `
              <div class="flex items-center gap-3">
                <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-blue-600 dark:text-blue-400">
                  <span class="material-symbols-outlined">calendar_month</span>
                </div>
                <div>
                  <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Joined</p>
                  <p class="text-sm font-semibold text-slate-900 dark:text-white">${new Date(user.created_at).toLocaleDateString()}</p>
                </div>
              </div>
              ` : ''}
            </div>
          </div>
        </div>
      </div>
    `
  }

  close(event) {
    event.preventDefault()
    window.closeModal()
  }
}