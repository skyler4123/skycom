import { Controller } from "@hotwired/stimulus"

export default class Admin_LayoutController extends Controller {

  initialize() {
    this.initLayout()
  }

  initLayout() {
    this.element.innerHTML = this.layoutHTML()
  }

  layoutHTML() {
    return `
      <div class="bg-slate-50 text-slate-900 dark:bg-slate-950 dark:text-white">
        <div class="flex h-screen w-full overflow-hidden">
          <aside
            class="w-72 bg-white dark:bg-slate-900 border-r border-slate-200 dark:border-slate-800 flex flex-col flex-shrink-0 transition-all duration-300">
            <div class="p-6 pb-2">
              <div class="flex items-center gap-3 mb-8">
                <div class="bg-blue-600/10 p-2 rounded-lg text-blue-600">
                  <span class="material-symbols-outlined fill text-3xl">cloud_circle</span>
                </div>
                <div>
                  <h1 class="text-slate-900 dark:text-white text-lg font-bold leading-tight tracking-tight">Skycom Admin</h1>
                  <p class="text-slate-500 dark:text-slate-400 text-xs font-medium">v4.2.0 (Stable)</p>
                </div>
              </div>
              <div class="flex flex-col gap-1">
                <a class="flex items-center gap-3 px-3 py-2.5 rounded-lg bg-blue-600/10 text-blue-600 group transition-colors"
                  href="#">
                  <span class="material-symbols-outlined fill">dashboard</span>
                  <span class="text-sm font-semibold">System Overview</span>
                </a>
                <a class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800 hover:text-slate-900 dark:hover:text-white transition-colors"
                  href="#">
                  <span class="material-symbols-outlined">group</span>
                  <span class="text-sm font-medium">User Accounts</span>
                </a>
                <a class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800 hover:text-slate-900 dark:hover:text-white transition-colors"
                  href="#">
                  <span class="material-symbols-outlined">dns</span>
                  <span class="text-sm font-medium">Server Management</span>
                </a>
                <a class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800 hover:text-slate-900 dark:hover:text-white transition-colors"
                  href="#">
                  <span class="material-symbols-outlined">database</span>
                  <span class="text-sm font-medium">Database Ops</span>
                </a>
                <a class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800 hover:text-slate-900 dark:hover:text-white transition-colors"
                  href="#">
                  <span class="material-symbols-outlined">monitoring</span>
                  <span class="text-sm font-medium">Logs & Monitoring</span>
                </a>
                <a class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800 hover:text-slate-900 dark:hover:text-white transition-colors"
                  href="#">
                  <span class="material-symbols-outlined">extension</span>
                  <span class="text-sm font-medium">Integrations</span>
                </a>
                <a class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800 hover:text-slate-900 dark:hover:text-white transition-colors"
                  href="#">
                  <span class="material-symbols-outlined">settings</span>
                  <span class="text-sm font-medium">Configuration</span>
                </a>
              </div>
            </div>
            <div class="mt-auto p-6 border-t border-slate-200 dark:border-slate-800">
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-full bg-slate-200 dark:bg-slate-700 bg-cover bg-center"
                  data-alt="Admin user profile picture showing a man in business casual"
                  style="background-image: url('https://lh3.googleusercontent.com/aida-public/AB6AXuAiNVKV0iWHrKIHh99mQoZ4J3tXOJfTv6PGhAy8gtjgjLm1F4-nUPBgUp--D0O3roCaqnnmxmlL6mBoBRMNFazj6uRPGMIRPf6_4E40MQq9i09bJ6ANPWJU8KETTW6dujEDHJOQSGrKjHaXIsxjGEE2o9TxbOugI0hTWBGGwB5Ke0iJgRlOOIuzCzJWrj3JeBICu_3GidSWNSht3J7pSpnhLMvg9opTC2M6KmZTR_GAnBPjIMcquDf3P8rb0AKWgpQFD8MMVdPk8M4')">
                </div>
                <div>
                  <p class="text-sm font-bold text-slate-900 dark:text-white">Alex Admin</p>
                  <p class="text-xs text-slate-500 dark:text-slate-400">Super Admin</p>
                </div>
              </div>
            </div>
          </aside>
          <div class="flex-1 flex flex-col h-full overflow-hidden relative">
            <header
              class="h-16 bg-white dark:bg-slate-900 border-b border-slate-200 dark:border-slate-800 flex items-center justify-between px-8 flex-shrink-0 z-10">
              <div class="flex items-center gap-4 flex-1">
                <h2 class="text-lg font-bold text-slate-900 dark:text-white hidden md:block">Dashboard Overview</h2>
                <div
                  class="hidden md:flex items-center bg-slate-100 dark:bg-slate-800 rounded-lg px-3 py-2 w-full max-w-md ml-4 focus-within:ring-2 ring-blue-600/20 transition-all">
                  <span class="material-symbols-outlined text-slate-400">search</span>
                  <input
                    class="bg-transparent border-none text-sm text-slate-900 dark:text-white placeholder-slate-400 focus:ring-0 w-full ml-2"
                    placeholder="Search user ID, server IP, or error code..." type="text" />
                </div>
              </div>
              <div class="flex items-center gap-4">
                <button
                  class="relative p-2 text-slate-500 hover:text-blue-600 transition-colors rounded-lg hover:bg-slate-50 dark:hover:bg-slate-800">
                  <span class="material-symbols-outlined">notifications</span>
                  <span
                    class="absolute top-2 right-2 w-2 h-2 bg-red-500 rounded-full ring-2 ring-white dark:ring-slate-900"></span>
                </button>
                <button
                  class="p-2 text-slate-500 hover:text-blue-600 transition-colors rounded-lg hover:bg-slate-50 dark:hover:bg-slate-800">
                  <span class="material-symbols-outlined">help</span>
                </button>
              </div>
            </header>
            <main class="flex-1 overflow-y-auto bg-slate-50 dark:bg-slate-950 p-8">
              


              ${this.contentHTML()}


              <footer class="mt-12 border-t border-slate-200 dark:border-slate-800 pt-6 pb-2">
                <div class="flex justify-between items-center text-xs text-slate-400">
                  <p>© 2024 Skycom Systems Inc. All rights reserved.</p>
                  <div class="flex gap-4">
                    <a class="hover:text-blue-600" href="#">System Status</a>
                    <a class="hover:text-blue-600" href="#">Docs</a>
                    <a class="hover:text-blue-600" href="#">Support</a>
                  </div>
                </div>
              </footer>
            </main>
          </div>
        </div>
      </div>
    `
  }
}
