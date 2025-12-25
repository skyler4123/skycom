import Admin_LayoutController from "controllers/admin/layout_controller"

export default class Admin_Companies_IndexController extends Admin_LayoutController {

  contentHTML() {
    return `
      <div class="max-w-[1280px] mx-auto flex flex-col gap-8">
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <div
            class="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex flex-col gap-1">
            <div class="flex items-center justify-between mb-2">
              <p class="text-slate-500 dark:text-slate-400 text-sm font-medium">Active Companies</p>
              <span
                class="bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400 text-xs font-bold px-2 py-0.5 rounded-full">+1.2%</span>
            </div>
            <p class="text-3xl font-bold text-slate-900 dark:text-white tracking-tight">1,240</p>
          </div>
          <div
            class="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex flex-col gap-1">
            <div class="flex items-center justify-between mb-2">
              <p class="text-slate-500 dark:text-slate-400 text-sm font-medium">Total Platform Users</p>
              <span
                class="bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400 text-xs font-bold px-2 py-0.5 rounded-full">+3.4%</span>
            </div>
            <p class="text-3xl font-bold text-slate-900 dark:text-white tracking-tight">45,203</p>
          </div>
          <div
            class="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex flex-col gap-1">
            <div class="flex items-center justify-between mb-2">
              <p class="text-slate-500 dark:text-slate-400 text-sm font-medium">Avg Server Load</p>
              <span
                class="bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400 text-xs font-bold px-2 py-0.5 rounded-full">Stable</span>
            </div>
            <p class="text-3xl font-bold text-slate-900 dark:text-white tracking-tight">34%</p>
            <div class="w-full bg-slate-100 dark:bg-slate-700 h-1.5 rounded-full mt-2 overflow-hidden">
              <div class="bg-emerald-500 h-full rounded-full" style="width: 34%"></div>
            </div>
          </div>
          <div
            class="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex flex-col gap-1">
            <div class="flex items-center justify-between mb-2">
              <p class="text-slate-500 dark:text-slate-400 text-sm font-medium">Database Health</p>
              <span class="material-symbols-outlined text-green-500 text-xl">check_circle</span>
            </div>
            <p class="text-3xl font-bold text-slate-900 dark:text-white tracking-tight">Healthy</p>
            <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">Last check: 1 min ago</p>
          </div>
        </div>
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div
            class="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
            <div class="flex justify-between items-start mb-4">
              <div>
                <h3 class="text-slate-900 dark:text-white font-semibold">CPU Usage</h3>
                <p class="text-slate-500 text-xs">Last 24 Hours</p>
              </div>
              <span class="text-2xl font-bold text-slate-900 dark:text-white">42%</span>
            </div>
            <div class="h-40 w-full relative">
              <svg class="w-full h-full" preserveAspectRatio="none" viewBox="0 0 100 40">
                <path d="M0 35 Q 10 32, 20 30 T 40 25 T 60 15 T 80 20 T 100 10" fill="none" stroke="#2563eb"
                  stroke-width="2"></path>
                <path d="M0 35 L0 40 L100 40 L100 10 Q 80 20, 60 15 T 40 25 T 20 30 Q 10 32, 0 35"
                  fill="rgba(37, 99, 235, 0.1)"></path>
              </svg>
            </div>
            <div class="flex justify-between text-xs text-slate-400 mt-2">
              <span>00:00</span>
              <span>06:00</span>
              <span>12:00</span>
              <span>18:00</span>
            </div>
          </div>
          <div
            class="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
            <div class="flex justify-between items-start mb-4">
              <div>
                <h3 class="text-slate-900 dark:text-white font-semibold">Memory Usage</h3>
                <p class="text-slate-500 text-xs">Last 24 Hours</p>
              </div>
              <span class="text-2xl font-bold text-slate-900 dark:text-white">12.4 GB</span>
            </div>
            <div class="h-40 w-full relative">
              <svg class="w-full h-full" preserveAspectRatio="none" viewBox="0 0 100 40">
                <path d="M0 20 Q 25 25, 50 15 T 100 22" fill="none" stroke="#8b5cf6" stroke-width="2"></path>
                <path d="M0 20 L0 40 L100 40 L100 22 Q 75 12, 50 15 Q 25 25, 0 20" fill="rgba(139, 92, 246, 0.1)">
                </path>
              </svg>
            </div>
            <div class="flex justify-between text-xs text-slate-400 mt-2">
              <span>00:00</span>
              <span>06:00</span>
              <span>12:00</span>
              <span>18:00</span>
            </div>
          </div>
          <div
            class="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
            <div class="flex justify-between items-start mb-4">
              <div>
                <h3 class="text-slate-900 dark:text-white font-semibold">Network Traffic</h3>
                <p class="text-slate-500 text-xs">Real-time (Mbps)</p>
              </div>
              <span class="text-2xl font-bold text-slate-900 dark:text-white">850</span>
            </div>
            <div class="h-40 flex items-end justify-between gap-2 px-2">
              <div class="w-full bg-blue-600/20 rounded-t h-[30%] relative group">
                <div
                  class="absolute bottom-full left-1/2 -translate-x-1/2 mb-1 hidden group-hover:block bg-slate-800 text-white text-xs px-2 py-1 rounded">
                  Web</div>
              </div>
              <div class="w-full bg-blue-600/40 rounded-t h-[65%] relative group">
                <div
                  class="absolute bottom-full left-1/2 -translate-x-1/2 mb-1 hidden group-hover:block bg-slate-800 text-white text-xs px-2 py-1 rounded">
                  API</div>
              </div>
              <div class="w-full bg-blue-600/30 rounded-t h-[45%] relative group">
                <div
                  class="absolute bottom-full left-1/2 -translate-x-1/2 mb-1 hidden group-hover:block bg-slate-800 text-white text-xs px-2 py-1 rounded">
                  CDN</div>
              </div>
              <div class="w-full bg-blue-600/60 rounded-t h-[80%] relative group">
                <div
                  class="absolute bottom-full left-1/2 -translate-x-1/2 mb-1 hidden group-hover:block bg-slate-800 text-white text-xs px-2 py-1 rounded">
                  DB</div>
              </div>
              <div class="w-full bg-blue-600/20 rounded-t h-[20%] relative group">
                <div
                  class="absolute bottom-full left-1/2 -translate-x-1/2 mb-1 hidden group-hover:block bg-slate-800 text-white text-xs px-2 py-1 rounded">
                  Other</div>
              </div>
            </div>
            <div class="flex justify-between text-xs text-slate-400 mt-2 px-1">
              <span>Web</span>
              <span>API</span>
              <span>CDN</span>
              <span>DB</span>
              <span>Other</span>
            </div>
          </div>
        </div>
        <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
          <div class="xl:col-span-1 flex flex-col gap-4">
            <h3 class="text-lg font-bold text-slate-900 dark:text-white">Quick Actions</h3>
            <div class="grid grid-cols-2 gap-3">
              <button
                class="flex flex-col items-center justify-center p-4 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl hover:border-blue-600 hover:shadow-md transition-all group">
                <div
                  class="p-2 bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400 rounded-full mb-2 group-hover:bg-blue-600 group-hover:text-white transition-colors">
                  <span class="material-symbols-outlined">database</span>
                </div>
                <span class="text-sm font-semibold text-slate-700 dark:text-slate-200">Run Migrations</span>
              </button>
              <button
                class="flex flex-col items-center justify-center p-4 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl hover:border-blue-600 hover:shadow-md transition-all group">
                <div
                  class="p-2 bg-purple-50 dark:bg-purple-900/20 text-purple-600 dark:text-purple-400 rounded-full mb-2 group-hover:bg-purple-600 group-hover:text-white transition-colors">
                  <span class="material-symbols-outlined">system_update</span>
                </div>
                <span class="text-sm font-semibold text-slate-700 dark:text-slate-200">System Updates</span>
              </button>
              <button
                class="flex flex-col items-center justify-center p-4 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl hover:border-blue-600 hover:shadow-md transition-all group">
                <div
                  class="p-2 bg-orange-50 dark:bg-orange-900/20 text-orange-600 dark:text-orange-400 rounded-full mb-2 group-hover:bg-orange-600 group-hover:text-white transition-colors">
                  <span class="material-symbols-outlined">cleaning_services</span>
                </div>
                <span class="text-sm font-semibold text-slate-700 dark:text-slate-200">Clear Cache</span>
              </button>
              <button
                class="flex flex-col items-center justify-center p-4 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl hover:border-red-500 hover:shadow-md transition-all group">
                <div
                  class="p-2 bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400 rounded-full mb-2 group-hover:bg-red-500 group-hover:text-white transition-colors">
                  <span class="material-symbols-outlined">build</span>
                </div>
                <span class="text-sm font-semibold text-slate-700 dark:text-slate-200">Maintenance</span>
              </button>
            </div>
            <div
              class="bg-blue-50 dark:bg-blue-900/10 border border-blue-100 dark:border-blue-800 rounded-xl p-4 mt-auto">
              <div class="flex gap-3">
                <span class="material-symbols-outlined text-blue-600">info</span>
                <div>
                  <h4 class="text-sm font-bold text-slate-900 dark:text-white">Scheduled Maintenance</h4>
                  <p class="text-xs text-slate-600 dark:text-slate-400 mt-1">Next system patch scheduled for Sunday at
                    02:00 AM UTC. No downtime expected.</p>
                </div>
              </div>
            </div>
          </div>
          <div class="xl:col-span-2 flex flex-col gap-4">
            <div class="flex items-center justify-between">
              <h3 class="text-lg font-bold text-slate-900 dark:text-white">Recent System Alerts</h3>
              <button class="text-sm text-blue-600 font-medium hover:underline">View All Logs</button>
            </div>
            <div
              class="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl overflow-hidden shadow-sm">
              <table class="w-full text-left text-sm">
                <thead
                  class="bg-slate-50 dark:bg-slate-800/50 text-slate-500 dark:text-slate-400 font-medium border-b border-slate-200 dark:border-slate-800">
                  <tr>
                    <th class="px-6 py-3 w-16">Status</th>
                    <th class="px-6 py-3">Message</th>
                    <th class="px-6 py-3">Source</th>
                    <th class="px-6 py-3 text-right">Time</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-slate-100 dark:divide-slate-800">
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors">
                    <td class="px-6 py-4">
                      <div
                        class="flex items-center justify-center w-8 h-8 rounded-full bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400">
                        <span class="material-symbols-outlined text-sm font-bold">priority_high</span>
                      </div>
                    </td>
                    <td class="px-6 py-4">
                      <p class="font-medium text-slate-900 dark:text-white">High Latency Detected</p>
                      <p class="text-xs text-slate-500">Response time > 2000ms</p>
                    </td>
                    <td class="px-6 py-4 text-slate-600 dark:text-slate-400 font-mono text-xs">US-East-1b</td>
                    <td class="px-6 py-4 text-right text-slate-500 dark:text-slate-400 text-xs">2 min ago</td>
                  </tr>
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors">
                    <td class="px-6 py-4">
                      <div
                        class="flex items-center justify-center w-8 h-8 rounded-full bg-amber-100 text-amber-600 dark:bg-amber-900/30 dark:text-amber-400">
                        <span class="material-symbols-outlined text-sm font-bold">warning</span>
                      </div>
                    </td>
                    <td class="px-6 py-4">
                      <p class="font-medium text-slate-900 dark:text-white">API Rate Limit Warning</p>
                      <p class="text-xs text-slate-500">Approaching 80% capacity</p>
                    </td>
                    <td class="px-6 py-4 text-slate-600 dark:text-slate-400 font-mono text-xs">Gateway-04</td>
                    <td class="px-6 py-4 text-right text-slate-500 dark:text-slate-400 text-xs">15 min ago</td>
                  </tr>
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors">
                    <td class="px-6 py-4">
                      <div
                        class="flex items-center justify-center w-8 h-8 rounded-full bg-blue-100 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400">
                        <span class="material-symbols-outlined text-sm font-bold">info</span>
                      </div>
                    </td>
                    <td class="px-6 py-4">
                      <p class="font-medium text-slate-900 dark:text-white">Backup Completed</p>
                      <p class="text-xs text-slate-500">Daily incremental snapshot</p>
                    </td>
                    <td class="px-6 py-4 text-slate-600 dark:text-slate-400 font-mono text-xs">DB-Cluster-Primary</td>
                    <td class="px-6 py-4 text-right text-slate-500 dark:text-slate-400 text-xs">1 hr ago</td>
                  </tr>
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors">
                    <td class="px-6 py-4">
                      <div
                        class="flex items-center justify-center w-8 h-8 rounded-full bg-green-100 text-green-600 dark:bg-green-900/30 dark:text-green-400">
                        <span class="material-symbols-outlined text-sm font-bold">check</span>
                      </div>
                    </td>
                    <td class="px-6 py-4">
                      <p class="font-medium text-slate-900 dark:text-white">New Integration Added</p>
                      <p class="text-xs text-slate-500">Stripe Payments V2</p>
                    </td>
                    <td class="px-6 py-4 text-slate-600 dark:text-slate-400 font-mono text-xs">System-Config</td>
                    <td class="px-6 py-4 text-right text-slate-500 dark:text-slate-400 text-xs">2 hrs ago</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
        <div class="flex flex-col gap-4">
          <div class="flex items-center justify-between">
            <h3 class="text-lg font-bold text-slate-900 dark:text-white">Active Background Jobs</h3>
            <div class="flex gap-2">
              <button
                class="px-3 py-1.5 text-xs font-medium bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-lg hover:bg-slate-50 transition-colors">Filter
                by Queue</button>
              <button
                class="px-3 py-1.5 text-xs font-medium bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors">Refresh
                List</button>
            </div>
          </div>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <div
              class="bg-white dark:bg-slate-900 p-4 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex items-start gap-3">
              <div class="w-2 h-2 rounded-full bg-green-500 mt-2 flex-shrink-0 animate-pulse"></div>
              <div class="flex-1">
                <h4 class="text-sm font-bold text-slate-900 dark:text-white">Email Notifications</h4>
                <p class="text-xs text-slate-500 mb-2">Queue: critical-emails</p>
                <div class="flex justify-between items-center text-xs">
                  <span class="text-slate-600 dark:text-slate-400">Processing...</span>
                  <span class="font-mono text-slate-500">142/sec</span>
                </div>
                <div class="w-full bg-slate-100 dark:bg-slate-700 h-1 rounded-full mt-2">
                  <div class="bg-green-500 h-full rounded-full" style="width: 78%"></div>
                </div>
              </div>
            </div>
            <div
              class="bg-white dark:bg-slate-900 p-4 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex items-start gap-3">
              <div class="w-2 h-2 rounded-full bg-blue-500 mt-2 flex-shrink-0 animate-pulse"></div>
              <div class="flex-1">
                <h4 class="text-sm font-bold text-slate-900 dark:text-white">Data Export #8821</h4>
                <p class="text-xs text-slate-500 mb-2">Queue: exports-long</p>
                <div class="flex justify-between items-center text-xs">
                  <span class="text-slate-600 dark:text-slate-400">Generating CSV</span>
                  <span class="font-mono text-slate-500">45%</span>
                </div>
                <div class="w-full bg-slate-100 dark:bg-slate-700 h-1 rounded-full mt-2">
                  <div class="bg-blue-500 h-full rounded-full" style="width: 45%"></div>
                </div>
              </div>
            </div>
            <div
              class="bg-white dark:bg-slate-900 p-4 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex items-start gap-3">
              <div class="w-2 h-2 rounded-full bg-slate-300 dark:bg-slate-600 mt-2 flex-shrink-0"></div>
              <div class="flex-1">
                <h4 class="text-sm font-bold text-slate-900 dark:text-white">Nightly Analytics</h4>
                <p class="text-xs text-slate-500 mb-2">Queue: analytics-agg</p>
                <div class="flex justify-between items-center text-xs">
                  <span class="text-slate-600 dark:text-slate-400">Scheduled: 03:00 AM</span>
                </div>
              </div>
            </div>
            <div
              class="bg-white dark:bg-slate-900 p-4 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex items-start gap-3">
              <div class="w-2 h-2 rounded-full bg-red-500 mt-2 flex-shrink-0"></div>
              <div class="flex-1">
                <h4 class="text-sm font-bold text-slate-900 dark:text-white">Image Optimization</h4>
                <p class="text-xs text-slate-500 mb-2">Queue: media-resize</p>
                <div class="flex justify-between items-center text-xs">
                  <span class="text-red-600 dark:text-red-400 font-medium">Failed (Retrying)</span>
                  <span class="font-mono text-slate-500">Attempt 2/3</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    `
  }

}
