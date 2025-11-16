import PaginationController from "controllers/pagination_controller"
import ApplicationController from "controllers/application_controller"

export default class LayoutController extends ApplicationController {
  static values = {
    pagination: { type: Object, default: {} },
    flash: { type: Object, default: {} },
    data: { type: Object, default: {} },
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

  layoutHTML() {
    return `
    <!-- Header: Sticky, White Background, Shadow, Responsive -->
    <header class="sticky top-0 z-10 bg-white shadow-md border-b border-gray-200">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-3 flex justify-between items-center h-16">
        
        <!-- Logo -->
        <div class="flex-shrink-0">
          <a href="/" class="text-2xl font-extrabold text-indigo-600 tracking-wider hover:text-indigo-800 transition duration-150">
            SKYCOM
          </a>
        </div>
        
        <!-- Navigation (Desktop) -->
        <nav class="hidden sm:flex">
          <ul class="flex space-x-8">
            <li><a href="#" class="text-gray-700 hover:text-indigo-600 font-medium transition duration-150">Home</a></li>
            <li><a href="#" class="text-gray-700 hover:text-indigo-600 font-medium transition duration-150">Product</a></li>
            <li><a href="#" class="text-gray-700 hover:text-indigo-600 font-medium transition duration-150">Pricing</a></li>
            <li><a href="#" class="text-gray-700 hover:text-indigo-600 font-medium transition duration-150">What's new</a></li>
          </ul>
        </nav>
        
        <!-- Action/Login -->
        <div class="flex items-center space-x-4">
          <a href="/sign_in" class="px-4 py-2 border border-transparent text-sm font-medium rounded-lg shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition duration-150">
            Log in
          </a>
          <!-- Placeholder for Mobile Menu Button (if needed) -->
          <button class="md:hidden text-gray-700 hover:text-indigo-600">
            <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"></path></svg>
          </button>
        </div>

      </div>
    </header>
    
    <!-- Main Content: Takes up remaining vertical space -->
    <main class="flex-grow">
      <article class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        ${this.serverHTML}
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
