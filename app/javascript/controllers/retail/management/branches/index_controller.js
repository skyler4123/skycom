import Retail_Management_LayoutController from "controllers/retail/management/layout_controller"

export default class Retail_Management_Branches_IndexController extends Retail_Management_LayoutController {

  contentHTML() {
    return `
      <div class="p-8 overflow-y-auto">
        <div class="flex flex-col md:flex-row items-center justify-between gap-4 mb-6">
          <div class="flex flex-1 items-center gap-4 w-full">
            <div class="relative w-full max-w-sm">
              <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
                <span class="material-symbols-outlined text-gray-500">search</span>
              </div>
              <input
                class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-blue-600 focus:border-blue-600 dark:bg-gray-800 dark:border-gray-600 dark:text-white"
                placeholder="Search branches, ID or city..." type="text" />
            </div>
            <select
              class="pl-3 pr-8 py-2 border border-gray-300 rounded-lg focus:ring-blue-600 focus:border-blue-600 dark:bg-gray-800 dark:border-gray-600 dark:text-white">
              <option>All Regions</option>
              <option>North America</option>
              <option>Europe</option>
              <option>Asia Pacific</option>
              <option>South America</option>
            </select>
            <select
              class="pl-3 pr-8 py-2 border border-gray-300 rounded-lg focus:ring-blue-600 focus:border-blue-600 dark:bg-gray-800 dark:border-gray-600 dark:text-white">
              <option>All Status</option>
              <option>Active</option>
              <option>Inactive</option>
              <option>Maintenance</option>
            </select>
          </div>
          <button
            class="inline-flex items-center justify-center gap-2 px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 shadow-sm transition-colors">
            <span class="material-symbols-outlined text-base">add</span>
            <span>Add New Branch</span>
          </button>
        </div>

        <div
          class="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 overflow-hidden shadow-sm">
          <div class="overflow-x-auto">
            <table class="w-full text-left">
              <thead>
                <tr
                  class="text-sm text-gray-500 dark:text-gray-400 border-b border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800/50">
                  <th class="py-3 px-6 font-medium">Branch Name</th>
                  <th class="py-3 px-6 font-medium">Branch ID</th>
                  <th class="py-3 px-6 font-medium">Address</th>
                  <th class="py-3 px-6 font-medium">Contact Information</th>
                  <th class="py-3 px-6 font-medium">Status</th>
                  <th class="py-3 px-6 font-medium text-right">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100 dark:divide-gray-800">
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors text-sm">
                  <td class="py-4 px-6 flex items-center gap-4">
                    <div class="w-10 h-10 rounded-lg bg-gray-100 dark:bg-gray-800 flex-shrink-0 bg-cover bg-center"
                      style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuBKqYQ-lFCKRgrfI4EPnefW878hsy7gNRqQPqj8s8E5Ge1-_XBtng98qY0IAC49HZtbBQbq_Xmm4WmqZTwnBA_u537-Oo3_Bo4ROEj9ufUtCi4z9_rT-JasRis5CI7aU-r4EgoVDyUSSL43L90Fx5kY6QLXVMw6PuhYB_Wpdku2jGXGTXlkeOHm_Q2XgxRygRF4fkXUKJxzjygS0_ITnoHauhzBh15UCG0VN28rIU4wC0Q1FFpiLqZxefa17HrnD0ReSRauHALa7YI")'>
                    </div>
                    <div>
                      <div class="font-medium text-gray-900 dark:text-white">Central Plaza HQ</div>
                      <div class="text-xs text-gray-500 dark:text-gray-400">Headquarters</div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-gray-600 dark:text-gray-300">BR-1001</td>
                  <td class="py-4 px-6 text-gray-600 dark:text-gray-300 max-w-xs truncate">123 Business Blvd, New York,
                    NY 10001</td>
                  <td class="py-4 px-6">
                    <div class="flex flex-col text-xs">
                      <span class="text-gray-900 dark:text-white font-medium">+1 (212) 555-0101</span>
                      <span class="text-gray-500 dark:text-gray-400">contact@central.skycom.com</span>
                    </div>
                  </td>
                  <td class="py-4 px-6">
                    <span
                      class="bg-green-100 text-green-700 dark:bg-green-900/50 dark:text-green-400 text-xs font-medium px-2.5 py-1 rounded-full">Active</span>
                  </td>
                  <td class="py-4 px-6 text-right">
                    <div class="flex justify-end gap-2">
                      <button class="p-2 rounded-md hover:bg-blue-50 dark:hover:bg-blue-900/20 text-blue-600"><span
                          class="material-symbols-outlined text-xl">edit</span></button>
                      <button class="p-2 rounded-md hover:bg-red-50 dark:hover:bg-red-900/20 text-red-500"><span
                          class="material-symbols-outlined text-xl">delete</span></button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors text-sm">
                  <td class="py-4 px-6 flex items-center gap-4">
                    <div class="w-10 h-10 rounded-lg bg-gray-100 dark:bg-gray-800 flex-shrink-0 bg-cover bg-center"
                      style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuAbXVPxwq9gR05ET4Kg0zCkBedYQjSJZmR3DH8SdyUnxZGoM_metNxBWCUUuSnCOssD-X8VxfXiG9Yn8EfI7K0CBy89bmtD6VOri4Otu7fyWyW17ze__SksK4FO4Nm3RhWu-tuH6YoqZe3BrXGRN0eEcf4YPYy9ZVCVUjpcTsQ7vITeB-vBntfVqWXHEoBs6-F3MNAfRrD6TPd_ulew3ZSwkPOR99c991viv5iDIKdMeoP5NnXZHRFkvdpt45KCw-xhpWJaokfXO-4")'>
                    </div>
                    <div>
                      <div class="font-medium text-gray-900 dark:text-white">Westside Market</div>
                      <div class="text-xs text-gray-500 dark:text-gray-400">Retail Outlet</div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-gray-600 dark:text-gray-300">BR-1002</td>
                  <td class="py-4 px-6 text-gray-600 dark:text-gray-300 max-w-xs truncate">450 West Ave, Los Angeles, CA
                    90012</td>
                  <td class="py-4 px-6">
                    <div class="flex flex-col text-xs">
                      <span class="text-gray-900 dark:text-white font-medium">+1 (310) 555-0234</span>
                      <span class="text-gray-500 dark:text-gray-400">mgr.west@skycom.com</span>
                    </div>
                  </td>
                  <td class="py-4 px-6">
                    <span
                      class="bg-green-100 text-green-700 dark:bg-green-900/50 dark:text-green-400 text-xs font-medium px-2.5 py-1 rounded-full">Active</span>
                  </td>
                  <td class="py-4 px-6 text-right">
                    <div class="flex justify-end gap-2">
                      <button class="p-2 rounded-md hover:bg-blue-50 dark:hover:bg-blue-900/20 text-blue-600"><span
                          class="material-symbols-outlined text-xl">edit</span></button>
                      <button class="p-2 rounded-md hover:bg-red-50 dark:hover:bg-red-900/20 text-red-500"><span
                          class="material-symbols-outlined text-xl">delete</span></button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors text-sm">
                  <td class="py-4 px-6 flex items-center gap-4">
                    <div class="w-10 h-10 rounded-lg bg-gray-100 dark:bg-gray-800 flex-shrink-0 bg-cover bg-center"
                      style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuC0-OZADNa-IOAewhuFRea32GhnTvSizf8IS7oJQCoW7uVPOToTNdbnfTGSgQdK2_aazL5e3yrXwWx9ytQRzabYngl2KRa100dLvLcWHTf8YH24sSOeI_cUDKZTq154ssb9O_ltPlYsH_elSHIo5jkwQ8hYYdKSESjp5-M_aY2blXiJ1y-xpC-Q0x7GWNq3JGWv52TwBe_bbUyVrAmWaRkl5zg1G8ld4KFLDZxeB_IGkorYr_4N8EAD49G9_7E9KOu9S0MyWLhLHXs")'>
                    </div>
                    <div>
                      <div class="font-medium text-gray-900 dark:text-white">North Hills Mall</div>
                      <div class="text-xs text-gray-500 dark:text-gray-400">Kiosk</div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-gray-600 dark:text-gray-300">BR-1025</td>
                  <td class="py-4 px-6 text-gray-600 dark:text-gray-300 max-w-xs truncate">8800 North Fwy, Houston, TX
                    77037</td>
                  <td class="py-4 px-6">
                    <div class="flex flex-col text-xs">
                      <span class="text-gray-900 dark:text-white font-medium">+1 (713) 555-0987</span>
                      <span class="text-gray-500 dark:text-gray-400">info.north@skycom.com</span>
                    </div>
                  </td>
                  <td class="py-4 px-6">
                    <span
                      class="bg-yellow-100 text-yellow-700 dark:bg-yellow-900/50 dark:text-yellow-400 text-xs font-medium px-2.5 py-1 rounded-full">Maintenance</span>
                  </td>
                  <td class="py-4 px-6 text-right">
                    <div class="flex justify-end gap-2">
                      <button class="p-2 rounded-md hover:bg-blue-50 dark:hover:bg-blue-900/20 text-blue-600"><span
                          class="material-symbols-outlined text-xl">edit</span></button>
                      <button class="p-2 rounded-md hover:bg-red-50 dark:hover:bg-red-900/20 text-red-500"><span
                          class="material-symbols-outlined text-xl">delete</span></button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors text-sm">
                  <td class="py-4 px-6 flex items-center gap-4">
                    <div class="w-10 h-10 rounded-lg bg-gray-100 dark:bg-gray-800 flex-shrink-0 bg-cover bg-center"
                      style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuAbXVPxwq9gR05ET4Kg0zCkBedYQjSJZmR3DH8SdyUnxZGoM_metNxBWCUUuSnCOssD-X8VxfXiG9Yn8EfI7K0CBy89bmtD6VOri4Otu7fyWyW17ze__SksK4FO4Nm3RhWu-tuH6YoqZe3BrXGRN0eEcf4YPYy9ZVCVUjpcTsQ7vITeB-vBntfVqWXHEoBs6-F3MNAfRrD6TPd_ulew3ZSwkPOR99c991viv5iDIKdMeoP5NnXZHRFkvdpt45KCw-xhpWJaokfXO-4")'>
                    </div>
                    <div>
                      <div class="font-medium text-gray-900 dark:text-white">Chicago Loop</div>
                      <div class="text-xs text-gray-500 dark:text-gray-400">Full Service</div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-gray-600 dark:text-gray-300">BR-2050</td>
                  <td class="py-4 px-6 text-gray-600 dark:text-gray-300 max-w-xs truncate">200 S State St, Chicago, IL
                    60604</td>
                  <td class="py-4 px-6">
                    <div class="flex flex-col text-xs">
                      <span class="text-gray-900 dark:text-white font-medium">+1 (312) 555-4567</span>
                      <span class="text-gray-500 dark:text-gray-400">chicago.loop@skycom.com</span>
                    </div>
                  </td>
                  <td class="py-4 px-6">
                    <span
                      class="bg-red-100 text-red-700 dark:bg-red-900/50 dark:text-red-400 text-xs font-medium px-2.5 py-1 rounded-full">Inactive</span>
                  </td>
                  <td class="py-4 px-6 text-right">
                    <div class="flex justify-end gap-2">
                      <button class="p-2 rounded-md hover:bg-blue-50 dark:hover:bg-blue-900/20 text-blue-600"><span
                          class="material-symbols-outlined text-xl">edit</span></button>
                      <button class="p-2 rounded-md hover:bg-red-50 dark:hover:bg-red-900/20 text-red-500"><span
                          class="material-symbols-outlined text-xl">delete</span></button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors text-sm">
                  <td class="py-4 px-6 flex items-center gap-4">
                    <div class="w-10 h-10 rounded-lg bg-gray-100 dark:bg-gray-800 flex-shrink-0 bg-cover bg-center"
                      style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuC_yRDDWRHorUiz0qbFEELV1j4CH5u7Pi8lNcqwN_NtNOzzmmXcLVj1axHQygvNQtzXQuDy_WkVr48kqu5bnmVmaRknP1wRgyFHJ0ERmHZ1ExwN-9Wqgojlr03kwVw9G0tQZ1LAdNn1qJJqPVvUwb4YiQRrkrevxFplJFS3LWtv2j3JA8GtCWs8wVtXw44pdWfb7d68qYZ-F37TizWABbG75ItHnbVZC8XlKJTD_otQmgkGtRdNZeoKOiYLoBJNe3JIPJHtx766U-8")'>
                    </div>
                    <div>
                      <div class="font-medium text-gray-900 dark:text-white">Miami Beach</div>
                      <div class="text-xs text-gray-500 dark:text-gray-400">Pop-up Store</div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-gray-600 dark:text-gray-300">BR-3005</td>
                  <td class="py-4 px-6 text-gray-600 dark:text-gray-300 max-w-xs truncate">100 Ocean Dr, Miami Beach, FL
                    33139</td>
                  <td class="py-4 px-6">
                    <div class="flex flex-col text-xs">
                      <span class="text-gray-900 dark:text-white font-medium">+1 (305) 555-7890</span>
                      <span class="text-gray-500 dark:text-gray-400">miami.beach@skycom.com</span>
                    </div>
                  </td>
                  <td class="py-4 px-6">
                    <span
                      class="bg-green-100 text-green-700 dark:bg-green-900/50 dark:text-green-400 text-xs font-medium px-2.5 py-1 rounded-full">Active</span>
                  </td>
                  <td class="py-4 px-6 text-right">
                    <div class="flex justify-end gap-2">
                      <button class="p-2 rounded-md hover:bg-blue-50 dark:hover:bg-blue-900/20 text-blue-600"><span
                          class="material-symbols-outlined text-xl">edit</span></button>
                      <button class="p-2 rounded-md hover:bg-red-50 dark:hover:bg-red-900/20 text-red-500"><span
                          class="material-symbols-outlined text-xl">delete</span></button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors text-sm">
                  <td class="py-4 px-6 flex items-center gap-4">
                    <div class="w-10 h-10 rounded-lg bg-gray-100 dark:bg-gray-800 flex-shrink-0 bg-cover bg-center"
                      style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuBKqYQ-lFCKRgrfI4EPnefW878hsy7gNRqQPqj8s8E5Ge1-_XBtng98qY0IAC49HZtbBQbq_Xmm4WmqZTwnBA_u537-Oo3_Bo4ROEj9ufUtCi4z9_rT-JasRis5CI7aU-r4EgoVDyUSSL43L90Fx5kY6QLXVMw6PuhYB_Wpdku2jGXGTXlkeOHm_Q2XgxRygRF4fkXUKJxzjygS0_ITnoHauhzBh15UCG0VN28rIU4wC0Q1FFpiLqZxefa17HrnD0ReSRauHALa7YI")'>
                    </div>
                    <div>
                      <div class="font-medium text-gray-900 dark:text-white">London Flagship</div>
                      <div class="text-xs text-gray-500 dark:text-gray-400">International HQ</div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-gray-600 dark:text-gray-300">BR-4402</td>
                  <td class="py-4 px-6 text-gray-600 dark:text-gray-300 max-w-xs truncate">10 Regent St, London, UK</td>
                  <td class="py-4 px-6">
                    <div class="flex flex-col text-xs">
                      <span class="text-gray-900 dark:text-white font-medium">+44 20 7946 0123</span>
                      <span class="text-gray-500 dark:text-gray-400">london.hq@skycom.com</span>
                    </div>
                  </td>
                  <td class="py-4 px-6">
                    <span
                      class="bg-green-100 text-green-700 dark:bg-green-900/50 dark:text-green-400 text-xs font-medium px-2.5 py-1 rounded-full">Active</span>
                  </td>
                  <td class="py-4 px-6 text-right">
                    <div class="flex justify-end gap-2">
                      <button class="p-2 rounded-md hover:bg-blue-50 dark:hover:bg-blue-900/20 text-blue-600"><span
                          class="material-symbols-outlined text-xl">edit</span></button>
                      <button class="p-2 rounded-md hover:bg-red-50 dark:hover:bg-red-900/20 text-red-500"><span
                          class="material-symbols-outlined text-xl">delete</span></button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="flex items-center justify-between p-4 border-t border-gray-200 dark:border-gray-700">
            <span class="text-sm text-gray-600 dark:text-gray-400">Showing 1 to 6 of 124 branches</span>
            <div class="flex items-center gap-2">
              <button
                class="px-3 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded-md hover:bg-gray-100 dark:hover:bg-gray-800 disabled:opacity-50"
                disabled>Previous</button>
              <button
                class="px-3 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded-md hover:bg-gray-100 dark:hover:bg-gray-800">Next</button>
            </div>
          </div>
        </div>
      </div>
    `
  }

}
