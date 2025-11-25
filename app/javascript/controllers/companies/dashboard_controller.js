import { Controller } from "@hotwired/stimulus"

export default class Companies_DashboardController extends Controller {
  initialize() {
    console.log("Companies Dashboard Controller initialized")
    this.element.innerHTML = this.defaultHTML()
  }

  defaultHTML() {
    return `
      <body class="bg-gray-50 font-sans text-gray-800">
        <div class="flex h-screen">
          <aside class="w-64 flex-shrink-0 bg-white border-r border-gray-200 flex flex-col">
            <div class="flex flex-col h-full p-4">
              <div class="flex items-center gap-3 mb-6 px-3 py-2">
                <div class="bg-center bg-no-repeat aspect-square bg-cover rounded-full size-10"
                  data-alt="Northwood High School logo"
                  style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuBDU4sBbWd5foRHyidVwH3kAwCGDfv2BDC0U7JybiFOEehA13EBN0Q6Yy7lFvpY5p79J5MRuGMyWFB__h6fiAj9nUCJtuMX5R4q-mrb6ikpHovkEu4u-48P1D4S3DKtD62qeBNkfcr7MA0k_qNlrMTihT71Rt8R1y2aVbQrQr4Px1dENzDdRCoEL8A1Wihi7ze_V9lqKGTpZ0NXIzkMWUTRGOduCXrWBYKuo7E3lRYDxr5yG3k8q7uvnHpPStXGM-eIEqmtNsEZkmSG");'>
                </div>
                <div class="flex flex-col">
                  <h1 class="text-gray-900 text-base font-medium leading-normal">Northwood High</h1>
                  <p class="text-gray-500 text-sm font-normal leading-normal">Management Portal</p>
                </div>
              </div>
              <nav class="flex-grow">
                <ul class="flex flex-col gap-2 text-gray-600">
                  <li>
                    <a class="flex items-center gap-3 px-3 py-2 rounded-lg bg-blue-100 text-blue-600" href="#">
                      <span class="material-symbols-outlined text-blue-600">dashboard</span>
                      <p class="text-sm font-medium leading-normal">Dashboard</p>
                    </a>
                  </li>
                  <li>
                    <a class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100" href="#">
                      <span class="material-symbols-outlined">import_contacts</span>
                      <p class="text-sm font-medium leading-normal">Courses</p>
                    </a>
                  </li>
                  <li>
                    <a class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100" href="#">
                      <span class="material-symbols-outlined">meeting_room</span>
                      <p class="text-sm font-medium leading-normal">Classes</p>
                    </a>
                  </li>
                  <li>
                    <a class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100" href="#">
                      <span class="material-symbols-outlined">groups</span>
                      <p class="text-sm font-medium leading-normal">Students</p>
                    </a>
                  </li>
                  <li>
                    <a class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100" href="#">
                      <span class="material-symbols-outlined">school</span>
                      <p class="text-sm font-medium leading-normal">Teachers</p>
                    </a>
                  </li>
                  <li>
                    <a class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100" href="#">
                      <span class="material-symbols-outlined">badge</span>
                      <p class="text-sm font-medium leading-normal">Staff/Employees</p>
                    </a>
                  </li>
                  <li>
                    <a class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100" href="#">
                      <span class="material-symbols-outlined">home</span>
                      <p class="text-sm font-medium leading-normal">Facilities</p>
                    </a>
                  </li>
                  <li>
                    <a class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100" href="#">
                      <span class="material-symbols-outlined">admin_panel_settings</span>
                      <p class="text-sm font-medium leading-normal">Administrators</p>
                    </a>
                  </li>
                  <li>
                    <a class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100" href="#">
                      <span class="material-symbols-outlined">receipt_long</span>
                      <p class="text-sm font-medium leading-normal">Payments/Invoices</p>
                    </a>
                  </li>
                </ul>
              </nav>
              <div class="mt-auto">
                <ul class="flex flex-col gap-1 text-gray-600">
                  <li>
                    <a class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100" href="#">
                      <span class="material-symbols-outlined">settings</span>
                      <p class="text-sm font-medium leading-normal">Settings</p>
                    </a>
                  </li>
                  <li>
                    <a class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100" href="#">
                      <span class="material-symbols-outlined">account_circle</span>
                      <p class="text-sm font-medium leading-normal">Profile</p>
                    </a>
                  </li>
                  <li>
                    <a class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100" href="#">
                      <span class="material-symbols-outlined">logout</span>
                      <p class="text-sm font-medium leading-normal">Logout</p>
                    </a>
                  </li>
                </ul>
              </div>
            </div>
          </aside>
          <main class="flex-1 flex flex-col overflow-y-auto">
            <header
              class="flex justify-between items-center gap-2 px-6 py-3 border-b border-gray-200 bg-gray-50/80 backdrop-blur-sm sticky top-0">
              <div class="flex items-center gap-2">
                <button class="p-2 text-gray-500 hover:text-gray-900 rounded-full hover:bg-gray-100">
                  <span class="material-symbols-outlined">search</span>
                </button>
              </div>
              <div class="flex items-center gap-4">
                <button class="p-2 text-gray-500 hover:text-gray-900 rounded-full hover:bg-gray-100">
                  <span class="material-symbols-outlined">notifications</span>
                </button>
                <button
                  class="flex items-center justify-center gap-2 h-10 px-4 rounded-lg bg-blue-600 text-white text-sm font-bold leading-normal tracking-wide hover:bg-blue-700">
                  <span class="material-symbols-outlined" style="font-variation-settings: 'FILL' 1, 'wght' 700;">add</span>
                  <span class="truncate">Add New</span>
                </button>
              </div>
            </header>
            <div class="flex-1 p-6 lg:p-8">
              <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-8">
                <div>
                  <p class="text-3xl lg:text-4xl font-black text-gray-900 leading-tight tracking-tight">School Dashboard</p>
                  <p class="text-gray-500 text-base font-normal leading-normal mt-2">Welcome back, Administrator!</p>
                </div>
                <div class="relative w-full sm:w-auto sm:min-w-[240px]">
                  <select
                    class="w-full appearance-none pl-4 pr-10 py-2.5 text-base text-gray-800 bg-white border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                    id="school-filter">
                    <option>All Schools</option>
                    <option selected="">Northwood High</option>
                    <option>Southcreek Academy</option>
                    <option>Eastwood Preparatory</option>
                    <option>Westgate International</option>
                  </select>
                  <div class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-3 text-gray-500">
                    <span class="material-symbols-outlined text-base">expand_more</span>
                  </div>
                </div>
              </div>
              <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
                <div class="flex flex-col gap-2 rounded-xl p-6 bg-white border border-gray-200">
                  <p class="text-gray-600 text-base font-medium leading-normal">Total Active Students</p>
                  <p class="text-gray-900 tracking-tight text-3xl font-bold leading-tight">1,245</p>
                  <p class="text-green-500 text-sm font-medium leading-normal mt-1">+1.5%</p>
                </div>
                <div class="flex flex-col gap-2 rounded-xl p-6 bg-white border border-gray-200">
                  <p class="text-gray-600 text-base font-medium leading-normal">Teachers & Staff</p>
                  <p class="text-gray-900 tracking-tight text-3xl font-bold leading-tight">86</p>
                  <p class="text-green-500 text-sm font-medium leading-normal mt-1">+0.5%</p>
                </div>
                <div class="flex flex-col gap-2 rounded-xl p-6 bg-white border border-gray-200">
                  <p class="text-gray-600 text-base font-medium leading-normal">Events This Week</p>
                  <p class="text-gray-900 tracking-tight text-3xl font-bold leading-tight">4</p>
                </div>
                <div class="flex flex-col gap-2 rounded-xl p-6 bg-white border border-gray-200">
                  <p class="text-gray-600 text-base font-medium leading-normal">Overdue Invoices</p>
                  <p class="text-gray-900 tracking-tight text-3xl font-bold leading-tight">12</p>
                  <p class="text-orange-400 text-sm font-medium leading-normal mt-1">+2 this week</p>
                </div>
              </div>
              <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
                <div class="lg:col-span-2">
                  <h2 class="text-gray-800 text-[22px] font-bold leading-tight tracking-tight mb-4">Attendance Trends</h2>
                  <div class="rounded-xl p-4 bg-white border border-gray-200">
                    <div class="h-80 flex items-center justify-center">
                      <img class="object-contain max-h-full"
                        data-alt="A line chart showing student attendance trends over the last month, with a slight upward trend."
                        src="https://lh3.googleusercontent.com/aida-public/AB6AXuD9BpId3nvNe_qdqmHc1OTftZdKNr4tC86xQRV8TwKNRPQOH3iMgI007FA7GG9VOits7FKh5rYGkZaxRrhJj-OrV2opPouvsrYmfWOrMJ3EWAuPejVwixF_QoddHQ3TENLytUTN9rZXrZ-_BeTHaOpRtJw_d2ZOY_-R5A6V6FCjaYCcSHPwi9QdLgUSSscgp9nYK_atblRAd26YmLZ7F50Z1In_ZGuvaisz8tQ4AyqaFWEVKS03OB8D8_Sba3r5dWatCdE6v20Dhq64" />
                    </div>
                  </div>
                </div>
                <div>
                  <h2 class="text-gray-800 text-[22px] font-bold leading-tight tracking-tight mb-4">Upcoming Events</h2>
                  <div class="rounded-xl p-4 bg-white border border-gray-200">
                    <ul class="space-y-4">
                      <li class="flex items-start gap-4 p-2">
                        <div
                          class="flex flex-col items-center justify-center h-12 w-12 rounded-lg bg-blue-100 text-blue-600 shrink-0">
                          <span class="text-sm font-bold">OCT</span>
                          <span class="text-lg font-black">28</span>
                        </div>
                        <div>
                          <p class="font-semibold text-gray-800">Parent-Teacher Conference</p>
                          <p class="text-sm text-gray-500">Main Auditorium, 4:00 PM - 7:00 PM</p>
                        </div>
                      </li>
                      <li class="flex items-start gap-4 p-2">
                        <div
                          class="flex flex-col items-center justify-center h-12 w-12 rounded-lg bg-blue-100 text-blue-600 shrink-0">
                          <span class="text-sm font-bold">NOV</span>
                          <span class="text-lg font-black">02</span>
                        </div>
                        <div>
                          <p class="font-semibold text-gray-800">Science Fair</p>
                          <p class="text-sm text-gray-500">School Gymnasium, 9:00 AM</p>
                        </div>
                      </li>
                      <li class="flex items-start gap-4 p-2">
                        <div
                          class="flex flex-col items-center justify-center h-12 w-12 rounded-lg bg-blue-100 text-blue-600 shrink-0">
                          <span class="text-sm font-bold">NOV</span>
                          <span class="text-lg font-black">05</span>
                        </div>
                        <div>
                          <p class="font-semibold text-gray-800">Mid-term Examinations Begin</p>
                          <p class="text-sm text-gray-500">All Classes</p>
                        </div>
                      </li>
                      <li class="flex items-start gap-4 p-2">
                        <div
                          class="flex flex-col items-center justify-center h-12 w-12 rounded-lg bg-gray-100 text-gray-500 shrink-0">
                          <span class="text-sm font-bold">NOV</span>
                          <span class="text-lg font-black">10</span>
                        </div>
                        <div>
                          <p class="font-semibold text-gray-800">Sports Day</p>
                          <p class="text-sm text-gray-500">Athletics Field, Full Day</p>
                        </div>
                      </li>
                    </ul>
                  </div>
                </div>
              </div>
            </div>
          </main>
        </div>
      </body>
    `
  }

}
