import PaginationController from "controllers/pagination_controller"
import ApplicationController from "controllers/application_controller"
import DarkmodeController from "controllers/darkmode_controller"
import { isSignedIn, avatar, Cookie } from "controllers/helpers"
import { useClickOutside } from 'stimulus-use'

export default class LayoutController extends ApplicationController {
  static targets = ["profileDropdown", "headerSubmenuContainer", "headerSubmenuContent"]
  static values = {
    pagination: { type: Object, default: {} },
    flash: { type: Object, default: {} },
    data: { type: Object, default: {} },
    isOpenProfileDropdown: { type: Boolean, default: false },
    openHeaderSubmenuName: { type: String, default: "" },
    
  }

  initBinding() {
    this.serverHTML = this.element.innerHTML
    this.paginationController = PaginationController
    this.flashValue = ServerData.flash || {}
    this.paginationValue = ServerData.pagination || {}
    this.dataValue = ServerData.data || {}
  }

  initLayout() {
    // Ensure the main element (which wraps the layout) is set up for sticky footer
    this.element.className = 'min-h-screen flex flex-col'
    this.element.innerHTML = this.layoutHTML()
  }

  contentHTML() {
    return this.serverHTML
  }

  clickProfileDropdown() {
    this.isOpenProfileDropdownValue = !this.isOpenProfileDropdownValue
  }

  isOpenProfileDropdownValueChanged(value, previousValue) {
    if (value) {
      this.profileDropdownTarget.innerHTML = this.profileDropdownHTML()
    } else {
      this.profileDropdownTarget.innerHTML = ''
    }
  }

  disconnect() {
    this.element.innerHTML = this.serverHTML
  }

  headerSubmenuHTML() {
    return {
      "home": `
        <div
          data-${this.identifier}-target="headerSubmenuContent"
          data-action="${this.identifier}:click:outside->${this.identifier}#clickOutsideHeaderSubmenu"
        >
          <a href="/companies/new">About us</a>
          <a href="/companies/new">Contact</a>
          <a href="/companies/new">Policy</a>
        </div>
      `,
      "product": `
        <div
          data-${this.identifier}-target="headerSubmenuContent"
          data-action="${this.identifier}:click:outside->${this.identifier}#clickOutsideHeaderSubmenu"
        >
          <a href="/companies/new">Company</a>
          <a href="/companies/new">School/University</a>
          <a href="/companies/new">Shop</a>
          <a href="/companies/new">Restaurant</a>
          <a href="/companies/new">Hospital</a>
          <a href="/companies/new">Service Company</a>
        </div>
      `
    }
  }

  profileDropdownHTML() {
    return `
      <div class="flex flex-col gap-y-2 p-2 w-full border-2 border-black rounded-xl">
        <div>${Cookie("email")}</div>
        <a href="/users/${Cookie("id")}">Profile</a>
        <a href="/sign_out">Sign Out</a>
      </div>
    `
  }

  authSectionHTML() {
    // avatar()
    if (isSignedIn()) {
      return `
        <div
          class="relative w-10 h-10 bg-gray-100 rounded-full dark:bg-gray-600 cursor-pointer"
          data-action="click->${this.identifier}#clickProfileDropdown"
        >
          ${avatar() ?
          `<img class="w-10 h-10 rounded-full" src="${avatar()}" alt="Rounded avatar">`
          :
          `<svg class="absolute w-12 h-12 text-gray-400 -left-1" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd"></path></svg>`
        }
          <div
            data-${this.identifier}-target="profileDropdown"
            class="absolute right-0 -bottom-2 translate-y-full z-20"
          >
            <div class="flex flex-col gap-y-2 p-2 w-full">
              <div>${Cookie("email")}</div>
              <a href="/users/${Cookie("id")}">Profile</a>
              <a href="/sign_out">Sign Out</a>
            </div>
          </div>
        </div>
      `
    } else {
      return `
        <a href="/sign_in" class="px-4 py-2 border border-transparent text-sm font-medium rounded-lg shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition duration-150">
          Log in
        </a>
      `
    }
  }

  layoutHTML() {
    return `
    <!-- Header: Sticky, White Background, Shadow, Responsive -->
    <header class="relative bg-white dark:bg-gray-800 shadow-md border-b border-gray-200 dark:border-gray-700">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-3 flex justify-between items-center h-16">
        
        <!-- Logo -->
        <div class="flex shrink-0">
          <a href="/" class="text-2xl font-extrabold text-indigo-600 tracking-wider hover:text-indigo-800 transition duration-150">
            SKYCOM
          </a>
        </div>
        
        <!-- Navigation (Desktop) -->
        <nav class="hidden sm:flex">
          <ul class="flex space-x-8">
            <li
              data-action="click->${this.identifier}#toggleHeaderSubmenu"
              data-${this.identifier}-header-submenu-name-param="home"
            >
              <div class="text-gray-700 dark:text-gray-300 hover:text-indigo-600 dark:hover:text-indigo-400 font-medium transition duration-150 cursor-pointer">Home</div>
            </li>
            <li
              class="flex flex-row gap-x-1 cursor-pointer group"
              data-action="click->${this.identifier}#toggleHeaderSubmenu"
              data-${this.identifier}-header-submenu-name-param="product"
            >
              <div class="text-gray-700 dark:text-gray-300 group-hover:text-indigo-600 group-hover:hover:text-indigo-400 font-medium transition duration-150">Product</div>
              <div class="flex justify-center items-center cl">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-5 group-hover:stroke-indigo-600 group-hover:hover:stroke-indigo-400">
                  <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
                </svg>
              </div>
            </li>
            <li>
              <a href="#" class="text-gray-700 dark:text-gray-300 hover:text-indigo-600 dark:hover:text-indigo-400 font-medium transition duration-150">Pricing</a>
            </li>
            <li>
              <a href="#" class="text-gray-700 dark:text-gray-300 hover:text-indigo-600 dark:hover:text-indigo-400 font-medium transition duration-150">What's new</a>
              </li>
          </ul>
        </nav>
        
        <!-- Action/Login -->
        <div class="flex items-center space-x-4">
          <div class="flex flex-row" data-controller="${DarkmodeController.identifier}"></div>
            ${this.authSectionHTML()}
          <!-- Placeholder for Mobile Menu Button (if needed) -->
          <button class="md:hidden text-gray-700 dark:text-gray-300 hover:text-indigo-600 dark:hover:text-indigo-400">
            <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"></path></svg>
          </button>
        </div>

      </div>
      <div
        data-${this.identifier}-target="headerSubmenuContainer"
        class="absolute w-full bottom-0 translate-y-full"
      >
      </div>
    </header>
    
    <!-- Main Content: Takes up remaining vertical space -->
    <main class="flex grow bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100">
      <article class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        ${this.contentHTML()}
      </article>
    </main>

    <!-- Footer: Dark Background, Centered Content -->
    <footer class="bg-gray-900 mt-12">
      <div class="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8 text-center">
        <div class="text-sm text-gray-400 space-x-4">
          <a href="#" class="hover:text-white transition duration-150">About</a>
          <span class="text-gray-600">|</span>
          <a href="#" class="hover:text-white transition duration-150">Contact</a>
          <span class="text-gray-600">|</span>
          <p class="inline text-gray-500">&copy; ${new Date().getFullYear()} Skycom. All rights reserved.</p>
        </div>
      </div>
    </footer>
    `
  }
}
