import Retail_Management_LayoutController from "controllers/retail/management/layout_controller"

export default class Retail_Management_Departments_IndexController extends Retail_Management_LayoutController {

  contentHTML() {
    return `
      <div class="p-8 overflow-y-auto">
        <div class="flex flex-col md:flex-row items-center justify-between gap-4 mb-6">
          <div class="flex flex-1 items-center gap-4 w-full max-w-2xl">
            <div class="relative flex-1">
              <span
                class="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 text-xl">search</span>
              <input
                class="w-full pl-10 pr-4 py-2 bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-700 rounded-lg text-sm outline-none focus:ring-2 focus:ring-blue-500/20"
                placeholder="Search departments..." type="text" />
            </div>
            <select
              class="bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-700 rounded-lg py-2 px-3 text-sm outline-none">
              <option>All Divisions</option>
            </select>
          </div>
          <button
            class="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-sm font-semibold rounded-lg shadow-sm transition-colors">
            <span class="material-symbols-outlined text-lg">add</span>
            Add New Department
          </button>
        </div>

        <div
          class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 overflow-hidden">
          <div class="overflow-x-auto">
            <table class="w-full text-left">
              <thead
                class="bg-slate-50 dark:bg-slate-800/50 text-slate-500 dark:text-slate-400 text-xs uppercase tracking-wider border-b border-slate-200 dark:border-slate-800">
                <tr>
                  <th class="py-4 px-6 font-semibold">Department</th>
                  <th class="py-4 px-6 font-semibold">Head of Department</th>
                  <th class="py-4 px-6 font-semibold">Description</th>
                  <th class="py-4 px-6 font-semibold text-center">Staff</th>
                  <th class="py-4 px-6 font-semibold text-right">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-200 dark:divide-slate-800">
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors">
                  <td class="py-4 px-6 flex items-center gap-4">
                    <div
                      class="w-10 h-10 rounded-lg bg-blue-100 dark:bg-blue-900/40 text-blue-600 flex items-center justify-center">
                      <span class="material-symbols-outlined">hr_resting</span>
                    </div>
                    <div>
                      <div class="font-bold text-slate-900 dark:text-white">Human Resources</div>
                      <div class="text-xs text-slate-500">Corporate</div>
                    </div>
                  </td>
                  <td class="py-4 px-6">
                    <div class="flex items-center gap-3">
                      <div class="w-8 h-8 rounded-full bg-slate-200 bg-cover"
                        style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuBKqYQ-lFCKRgrfI4EPnefW878hsy7gNRqQPqj8s8E5Ge1-_XBtng98qY0IAC49HZtbBQbq_Xmm4WmqZTwnBA_u537-Oo3_Bo4ROEj9ufUtCi4z9_rT-JasRis5CI7aU-r4EgoVDyUSSL43L90Fx5kY6QLXVMw6PuhYB_Wpdku2jGXGTXlkeOHm_Q2XgxRygRF4fkXUKJxzjygS0_ITnoHauhzBh15UCG0VN28rIU4wC0Q1FFpiLqZxefa17HrnD0ReSRauHALa7YI")'>
                      </div>
                      <div>
                        <div class="text-sm font-medium">Sarah Jenkins</div>
                        <div class="text-xs text-slate-500">CPO</div>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-400 max-w-xs truncate">Employee relations
                    and benefits.</td>
                  <td class="py-4 px-6 text-center"><span
                      class="px-2 py-1 rounded-full bg-slate-100 dark:bg-slate-800 text-xs font-medium">12
                      Members</span></td>
                  <td class="py-4 px-6 text-right space-x-2">
                    <button class="text-blue-600 hover:text-blue-700 transition-colors"><span
                        class="material-symbols-outlined text-xl">edit</span></button>
                    <button class="text-red-500 hover:text-red-600 transition-colors"><span
                        class="material-symbols-outlined text-xl">delete</span></button>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors">
                  <td class="py-4 px-6 flex items-center gap-4">
                    <div
                      class="w-10 h-10 rounded-lg bg-purple-100 dark:bg-purple-900/40 text-purple-600 flex items-center justify-center">
                      <span class="material-symbols-outlined">monitoring</span>
                    </div>
                    <div>
                      <div class="font-bold text-slate-900 dark:text-white">Finance & Accounting</div>
                      <div class="text-xs text-slate-500">Corporate</div>
                    </div>
                  </td>
                  <td class="py-4 px-6">
                    <div class="flex items-center gap-3">
                      <div class="w-8 h-8 rounded-full bg-slate-200 bg-cover"
                        style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuAbXVPxwq9gR05ET4Kg0zCkBedYQjSJZmR3DH8SdyUnxZGoM_metNxBWCUUuSnCOssD-X8VxfXiG9Yn8EfI7K0CBy89bmtD6VOri4Otu7fyWyW17ze__SksK4FO4Nm3RhWu-tuH6YoqZe3BrXGRN0eEcf4YPYy9ZVCVUjpcTsQ7vITeB-vBntfVqWXHEoBs6-F3MNAfRrD6TPd_ulew3ZSwkPOR99c991viv5iDIKdMeoP5NnXZHRFkvdpt45KCw-xhpWJaokfXO-4")'>
                      </div>
                      <div>
                        <div class="text-sm font-medium">Michael Chen</div>
                        <div class="text-xs text-slate-500">CFO</div>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-400 max-w-xs truncate">Payroll, auditing,
                    and taxes.</td>
                  <td class="py-4 px-6 text-center"><span
                      class="px-2 py-1 rounded-full bg-slate-100 dark:bg-slate-800 text-xs font-medium">8 Members</span>
                  </td>
                  <td class="py-4 px-6 text-right space-x-2">
                    <button class="text-blue-600 hover:text-blue-700 transition-colors"><span
                        class="material-symbols-outlined text-xl">edit</span></button>
                    <button class="text-red-500 hover:text-red-600 transition-colors"><span
                        class="material-symbols-outlined text-xl">delete</span></button>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors">
                  <td class="py-4 px-6 flex items-center gap-4">
                    <div
                      class="w-10 h-10 rounded-lg bg-emerald-100 dark:bg-emerald-900/40 text-emerald-600 flex items-center justify-center">
                      <span class="material-symbols-outlined">campaign</span>
                    </div>
                    <div>
                      <div class="font-bold text-slate-900 dark:text-white">Marketing & Sales</div>
                      <div class="text-xs text-slate-500">Growth</div>
                    </div>
                  </td>
                  <td class="py-4 px-6">
                    <div class="flex items-center gap-3">
                      <div class="w-8 h-8 rounded-full bg-slate-200 bg-cover"
                        style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuC0-OZADNa-IOAewhuFRea32GhnTvSizf8IS7oJQCoW7uVPOToTNdbnfTGSgQdK2_aazL5e3yrXwWx9ytQRzabYngl2KRa100dLvLcWHTf8YH24sSOeI_cUDKZTq154ssb9O_ltPlYsH_elSHIo5jkwQ8hYYdKSESjp5-M_aY2blXiJ1y-xpC-Q0x7GWNq3JGWv52TwBe_bbUyVrAmWaRkl5zg1G8ld4KFLDZxeB_IGkorYr_4N8EAD49G9_7E9KOu9S0MyWLhLHXs")'>
                      </div>
                      <div>
                        <div class="text-sm font-medium">Jessica Lee</div>
                        <div class="text-xs text-slate-500">VP Marketing</div>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-400 max-w-xs truncate">Brand strategy and
                    advertising.</td>
                  <td class="py-4 px-6 text-center"><span
                      class="px-2 py-1 rounded-full bg-slate-100 dark:bg-slate-800 text-xs font-medium">24
                      Members</span></td>
                  <td class="py-4 px-6 text-right space-x-2">
                    <button class="text-blue-600 hover:text-blue-700 transition-colors"><span
                        class="material-symbols-outlined text-xl">edit</span></button>
                    <button class="text-red-500 hover:text-red-600 transition-colors"><span
                        class="material-symbols-outlined text-xl">delete</span></button>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors">
                  <td class="py-4 px-6 flex items-center gap-4">
                    <div
                      class="w-10 h-10 rounded-lg bg-orange-100 dark:bg-orange-900/40 text-orange-600 flex items-center justify-center">
                      <span class="material-symbols-outlined">terminal</span>
                    </div>
                    <div>
                      <div class="font-bold text-slate-900 dark:text-white">IT & Support</div>
                      <div class="text-xs text-slate-500">Technology</div>
                    </div>
                  </td>
                  <td class="py-4 px-6">
                    <div class="flex items-center gap-3">
                      <div class="w-8 h-8 rounded-full bg-slate-200 bg-cover"
                        style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuAbXVPxwq9gR05ET4Kg0zCkBedYQjSJZmR3DH8SdyUnxZGoM_metNxBWCUUuSnCOssD-X8VxfXiG9Yn8EfI7K0CBy89bmtD6VOri4Otu7fyWyW17ze__SksK4FO4Nm3RhWu-tuH6YoqZe3BrXGRN0eEcf4YPYy9ZVCVUjpcTsQ7vITeB-vBntfVqWXHEoBs6-F3MNAfRrD6TPd_ulew3ZSwkPOR99c991viv5iDIKdMeoP5NnXZHRFkvdpt45KCw-xhpWJaokfXO-4")'>
                      </div>
                      <div>
                        <div class="text-sm font-medium">David Ross</div>
                        <div class="text-xs text-slate-500">CTO</div>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-400 max-w-xs truncate">Technical
                    infrastructure management.</td>
                  <td class="py-4 px-6 text-center"><span
                      class="px-2 py-1 rounded-full bg-slate-100 dark:bg-slate-800 text-xs font-medium">15
                      Members</span></td>
                  <td class="py-4 px-6 text-right space-x-2">
                    <button class="text-blue-600 hover:text-blue-700 transition-colors"><span
                        class="material-symbols-outlined text-xl">edit</span></button>
                    <button class="text-red-500 hover:text-red-600 transition-colors"><span
                        class="material-symbols-outlined text-xl">delete</span></button>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors">
                  <td class="py-4 px-6 flex items-center gap-4">
                    <div
                      class="w-10 h-10 rounded-lg bg-indigo-100 dark:bg-indigo-900/40 text-indigo-600 flex items-center justify-center">
                      <span class="material-symbols-outlined">inventory</span>
                    </div>
                    <div>
                      <div class="font-bold text-slate-900 dark:text-white">Supply Chain</div>
                      <div class="text-xs text-slate-500">Operations</div>
                    </div>
                  </td>
                  <td class="py-4 px-6">
                    <div class="flex items-center gap-3">
                      <div class="w-8 h-8 rounded-full bg-slate-200 bg-cover"
                        style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuC_yRDDWRHorUiz0qbFEELV1j4CH5u7Pi8lNcqwN_NtNOzzmmXcLVj1axHQygvNQtzXQuDy_WkVr48kqu5bnmVmaRknP1wRgyFHJ0ERmHZ1ExwN-9Wqgojlr03kwVw9G0tQZ1LAdNn1qJJqPVvUwb4YiQRrkrevxFplJFS3LWtv2j3JA8GtCWs8wVtXw44pdWfb7d68qYZ-F37TizWABbG75ItHnbVZC8XlKJTD_otQmgkGtRdNZeoKOiYLoBJNe3JIPJHtx766U-8")'>
                      </div>
                      <div>
                        <div class="text-sm font-medium">Amanda Clarke</div>
                        <div class="text-xs text-slate-500">Logistics Dir.</div>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-400 max-w-xs truncate">Warehousing and
                    inventory flow.</td>
                  <td class="py-4 px-6 text-center"><span
                      class="px-2 py-1 rounded-full bg-slate-100 dark:bg-slate-800 text-xs font-medium">32
                      Members</span></td>
                  <td class="py-4 px-6 text-right space-x-2">
                    <button class="text-blue-600 hover:text-blue-700 transition-colors"><span
                        class="material-symbols-outlined text-xl">edit</span></button>
                    <button class="text-red-500 hover:text-red-600 transition-colors"><span
                        class="material-symbols-outlined text-xl">delete</span></button>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors">
                  <td class="py-4 px-6 flex items-center gap-4">
                    <div
                      class="w-10 h-10 rounded-lg bg-pink-100 dark:bg-pink-900/40 text-pink-600 flex items-center justify-center">
                      <span class="material-symbols-outlined">support_agent</span>
                    </div>
                    <div>
                      <div class="font-bold text-slate-900 dark:text-white">Customer Service</div>
                      <div class="text-xs text-slate-500">Support</div>
                    </div>
                  </td>
                  <td class="py-4 px-6">
                    <div class="flex items-center gap-3">
                      <div class="w-8 h-8 rounded-full bg-slate-200 bg-cover"
                        style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuBKqYQ-lFCKRgrfI4EPnefW878hsy7gNRqQPqj8s8E5Ge1-_XBtng98qY0IAC49HZtbBQbq_Xmm4WmqZTwnBA_u537-Oo3_Bo4ROEj9ufUtCi4z9_rT-JasRis5CI7aU-r4EgoVDyUSSL43L90Fx5kY6QLXVMw6PuhYB_Wpdku2jGXGTXlkeOHm_Q2XgxRygRF4fkXUKJxzjygS0_ITnoHauhzBh15UCG0VN28rIU4wC0Q1FFpiLqZxefa17HrnD0ReSRauHALa7YI")'>
                      </div>
                      <div>
                        <div class="text-sm font-medium">Robert Fox</div>
                        <div class="text-xs text-slate-500">Head of CS</div>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-400 max-w-xs truncate">Customer inquiries
                    and feedback.</td>
                  <td class="py-4 px-6 text-center"><span
                      class="px-2 py-1 rounded-full bg-slate-100 dark:bg-slate-800 text-xs font-medium">45
                      Members</span></td>
                  <td class="py-4 px-6 text-right space-x-2">
                    <button class="text-blue-600 hover:text-blue-700 transition-colors"><span
                        class="material-symbols-outlined text-xl">edit</span></button>
                    <button class="text-red-500 hover:text-red-600 transition-colors"><span
                        class="material-symbols-outlined text-xl">delete</span></button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div
            class="flex items-center justify-between p-4 border-t border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-800/50">
            <span class="text-sm text-slate-500">Showing 6 of 18 departments</span>
            <div class="flex gap-2">
              <button
                class="px-3 py-1 border border-slate-300 dark:border-slate-700 rounded-md text-sm hover:bg-white dark:hover:bg-slate-800 disabled:opacity-50"
                disabled>Previous</button>
              <button
                class="px-3 py-1 border border-slate-300 dark:border-slate-700 rounded-md text-sm hover:bg-white dark:hover:bg-slate-800">Next</button>
            </div>
          </div>
        </div>
      </div>
    `
  }

}
