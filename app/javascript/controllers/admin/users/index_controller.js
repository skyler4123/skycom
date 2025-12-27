import Admin_LayoutController from "controllers/admin/layout_controller"

export default class Admin_Users_IndexController extends Admin_LayoutController {

  contentHTML() {
    return `
      <div class="max-w-[1400px] mx-auto flex flex-col gap-6">
        <div class="flex flex-col md:flex-row md:items-end justify-between gap-4">
          <div>
            <h1 class="text-2xl font-bold text-slate-900 dark:text-white tracking-tight">User Account Management</h1>
            <p class="text-sm text-slate-500 dark:text-slate-400 mt-1">Manage user access, roles, and profiles across
              all business verticals.</p>
          </div>
          <button
            class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2.5 rounded-lg flex items-center gap-2 transition-all shadow-sm hover:shadow-md font-medium text-sm">
            <span class="material-symbols-outlined text-xl">person_add</span> Add New User
          </button>
        </div>

        <div
          class="bg-white dark:bg-slate-900 p-4 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm grid grid-cols-1 md:grid-cols-4 gap-4 items-center">
          <div class="flex flex-col gap-1.5">
            <label class="text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Account
              Status</label>
            <div class="relative">
              <select
                class="w-full bg-slate-50 dark:bg-slate-800 border-none text-sm rounded-lg py-2.5 pl-3 pr-10 text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-600/50 cursor-pointer">
                <option value="">All Statuses</option>
                <option value="active">Active</option>
                <option value="inactive">Inactive</option>
                <option value="suspended">Suspended</option>
              </select>
              <span
                class="absolute right-3 top-2.5 pointer-events-none text-slate-500 material-symbols-outlined text-lg">expand_more</span>
            </div>
          </div>
          <div class="flex flex-col gap-1.5">
            <label
              class="text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Role</label>
            <div class="relative">
              <select
                class="w-full bg-slate-50 dark:bg-slate-800 border-none text-sm rounded-lg py-2.5 pl-3 pr-10 text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-600/50 cursor-pointer">
                <option value="">All Roles</option>
                <option value="admin">Admin</option>
                <option value="employee">Employee</option>
                <option value="customer">Customer</option>
                <option value="manager">Manager</option>
              </select>
              <span
                class="absolute right-3 top-2.5 pointer-events-none text-slate-500 material-symbols-outlined text-lg">expand_more</span>
            </div>
          </div>
          <div class="flex flex-col gap-1.5">
            <label
              class="text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Company/Vertical</label>
            <div class="relative">
              <select
                class="w-full bg-slate-50 dark:bg-slate-800 border-none text-sm rounded-lg py-2.5 pl-3 pr-10 text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-600/50 cursor-pointer">
                <option value="">All Companies</option>
                <option value="retail">Retail</option>
                <option value="education">Education</option>
                <option value="hospital">Hospital</option>
                <option value="service">Service</option>
                <option value="restaurant">Restaurant</option>
              </select>
              <span
                class="absolute right-3 top-2.5 pointer-events-none text-slate-500 material-symbols-outlined text-lg">expand_more</span>
            </div>
          </div>
          <div class="flex items-end justify-end h-full pb-0.5">
            <button
              class="text-blue-600 hover:text-blue-700 text-sm font-medium hover:underline flex items-center gap-1 transition-colors">
              <span class="material-symbols-outlined text-lg">filter_list_off</span> Clear Filters
            </button>
          </div>
        </div>

        <div
          class="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl overflow-hidden shadow-sm flex-1">
          <div class="overflow-x-auto">
            <table class="w-full text-left text-sm whitespace-nowrap">
              <thead
                class="bg-slate-50 dark:bg-slate-800/50 text-slate-500 dark:text-slate-400 font-medium border-b border-slate-200 dark:border-slate-800">
                <tr>
                  <th class="px-6 py-4">User Name</th>
                  <th class="px-6 py-4">Email</th>
                  <th class="px-6 py-4">Assigned Role</th>
                  <th class="px-6 py-4">Associated Company</th>
                  <th class="px-6 py-4">Last Login</th>
                  <th class="px-6 py-4">Account Status</th>
                  <th class="px-6 py-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100 dark:divide-slate-800">
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors group">
                  <td class="px-6 py-4">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-8 h-8 rounded-full bg-indigo-100 text-indigo-600 dark:bg-indigo-900/30 dark:text-indigo-400 flex items-center justify-center font-bold text-xs">
                        JD</div>
                      <span class="font-medium text-slate-900 dark:text-white">John Doe</span>
                    </div>
                  </td>
                  <td class="px-6 py-4 text-slate-600 dark:text-slate-400">john.doe@skycom.io</td>
                  <td class="px-6 py-4 text-slate-900 dark:text-white font-medium">System Admin</td>
                  <td class="px-6 py-4 text-slate-500 dark:text-slate-400">Skycom HQ</td>
                  <td class="px-6 py-4 text-slate-500 dark:text-slate-400">2 mins ago</td>
                  <td class="px-6 py-4">
                    <span
                      class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400">Active</span>
                  </td>
                  <td class="px-6 py-4">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="View Profile">
                        <span class="material-symbols-outlined text-lg">visibility</span>
                      </button>
                      <button
                        class="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg transition-colors"
                        title="Edit User">
                        <span class="material-symbols-outlined text-lg">edit</span>
                      </button>
                      <button
                        class="p-1.5 text-slate-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                        title="Deactivate Account">
                        <span class="material-symbols-outlined text-lg">person_off</span>
                      </button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors group">
                  <td class="px-6 py-4">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-8 h-8 rounded-full bg-pink-100 text-pink-600 dark:bg-pink-900/30 dark:text-pink-400 flex items-center justify-center font-bold text-xs">
                        AS</div>
                      <span class="font-medium text-slate-900 dark:text-white">Alice Smith</span>
                    </div>
                  </td>
                  <td class="px-6 py-4 text-slate-600 dark:text-slate-400">alice.smith@education.org</td>
                  <td class="px-6 py-4 text-slate-900 dark:text-white font-medium">Vertical Manager</td>
                  <td class="px-6 py-4 text-slate-500 dark:text-slate-400">Education Dept</td>
                  <td class="px-6 py-4 text-slate-500 dark:text-slate-400">2 days ago</td>
                  <td class="px-6 py-4">
                    <span
                      class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400">Active</span>
                  </td>
                  <td class="px-6 py-4">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="View Profile">
                        <span class="material-symbols-outlined text-lg">visibility</span>
                      </button>
                      <button
                        class="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg transition-colors"
                        title="Edit User">
                        <span class="material-symbols-outlined text-lg">edit</span>
                      </button>
                      <button
                        class="p-1.5 text-slate-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                        title="Deactivate Account">
                        <span class="material-symbols-outlined text-lg">person_off</span>
                      </button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors group">
                  <td class="px-6 py-4">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-8 h-8 rounded-full bg-slate-200 text-slate-600 dark:bg-slate-700 dark:text-slate-400 flex items-center justify-center font-bold text-xs">
                        RK</div>
                      <span class="font-medium text-slate-900 dark:text-white">Robert King</span>
                    </div>
                  </td>
                  <td class="px-6 py-4 text-slate-600 dark:text-slate-400">r.king@retail.net</td>
                  <td class="px-6 py-4 text-slate-900 dark:text-white font-medium">Store Manager</td>
                  <td class="px-6 py-4 text-slate-500 dark:text-slate-400">Retail Inc</td>
                  <td class="px-6 py-4 text-slate-500 dark:text-slate-400">1 month ago</td>
                  <td class="px-6 py-4">
                    <span
                      class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-slate-100 text-slate-800 dark:bg-slate-700 dark:text-slate-300">Inactive</span>
                  </td>
                  <td class="px-6 py-4">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="View Profile">
                        <span class="material-symbols-outlined text-lg">visibility</span>
                      </button>
                      <button
                        class="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg transition-colors"
                        title="Edit User">
                        <span class="material-symbols-outlined text-lg">edit</span>
                      </button>
                      <button
                        class="p-1.5 text-slate-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                        title="Deactivate Account">
                        <span class="material-symbols-outlined text-lg">person_off</span>
                      </button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors group">
                  <td class="px-6 py-4">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-8 h-8 rounded-full bg-yellow-100 text-yellow-600 dark:bg-yellow-900/30 dark:text-yellow-400 flex items-center justify-center font-bold text-xs">
                        EM</div>
                      <span class="font-medium text-slate-900 dark:text-white">Elena Miles</span>
                    </div>
                  </td>
                  <td class="px-6 py-4 text-slate-600 dark:text-slate-400">elena.m@hospital.care</td>
                  <td class="px-6 py-4 text-slate-900 dark:text-white font-medium">Medical Staff</td>
                  <td class="px-6 py-4 text-slate-500 dark:text-slate-400">City Hospital</td>
                  <td class="px-6 py-4 text-slate-500 dark:text-slate-400">5 hours ago</td>
                  <td class="px-6 py-4">
                    <span
                      class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400">Suspended</span>
                  </td>
                  <td class="px-6 py-4">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="View Profile">
                        <span class="material-symbols-outlined text-lg">visibility</span>
                      </button>
                      <button
                        class="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg transition-colors"
                        title="Edit User">
                        <span class="material-symbols-outlined text-lg">edit</span>
                      </button>
                      <button
                        class="p-1.5 text-slate-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                        title="Deactivate Account">
                        <span class="material-symbols-outlined text-lg">person_off</span>
                      </button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors group">
                  <td class="px-6 py-4">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-8 h-8 rounded-full bg-teal-100 text-teal-600 dark:bg-teal-900/30 dark:text-teal-400 flex items-center justify-center font-bold text-xs">
                        TC</div>
                      <span class="font-medium text-slate-900 dark:text-white">Tom Cook</span>
                    </div>
                  </td>
                  <td class="px-6 py-4 text-slate-600 dark:text-slate-400">t.cook@foodservice.io</td>
                  <td class="px-6 py-4 text-slate-900 dark:text-white font-medium">Customer</td>
                  <td class="px-6 py-4 text-slate-500 dark:text-slate-400">Food Service Co</td>
                  <td class="px-6 py-4 text-slate-500 dark:text-slate-400">1 day ago</td>
                  <td class="px-6 py-4">
                    <span
                      class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400">Active</span>
                  </td>
                  <td class="px-6 py-4">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="View Profile">
                        <span class="material-symbols-outlined text-lg">visibility</span>
                      </button>
                      <button
                        class="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg transition-colors"
                        title="Edit User">
                        <span class="material-symbols-outlined text-lg">edit</span>
                      </button>
                      <button
                        class="p-1.5 text-slate-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                        title="Deactivate Account">
                        <span class="material-symbols-outlined text-lg">person_off</span>
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div
            class="flex items-center justify-between px-6 py-4 bg-slate-50 dark:bg-slate-800/50 border-t border-slate-200 dark:border-slate-800">
            <div class="text-xs text-slate-500 dark:text-slate-400">
              Showing <span class="font-medium">1</span> to <span class="font-medium">5</span> of <span
                class="font-medium">1,204</span> results
            </div>
            <div class="flex gap-2">
              <button
                class="px-3 py-1 text-xs font-medium bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-lg text-slate-400 cursor-not-allowed">Previous</button>
              <button
                class="px-3 py-1 text-xs font-medium bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-lg text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors">Next</button>
            </div>
          </div>
        </div>
      </div>
    `
  }

}
