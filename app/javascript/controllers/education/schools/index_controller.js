import LayoutController from "controllers/layout_controller"

export default class Education_Schools_IndexController extends LayoutController {

  contentHTML() {
    return `
      <div class="p-8 overflow-y-auto">
        <div class="flex flex-wrap justify-between gap-3 mb-8">
          <div class="flex flex-col gap-1">
            <p class="text-gray-900 dark:text-white text-3xl font-bold leading-tight tracking-tight">Welcome back,
              Administrator!</p>
            <p class="text-gray-500 dark:text-gray-400 text-base font-normal leading-normal">Here's what's happening at
              your school today.</p>
          </div>
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <div
            class="flex flex-col gap-2 rounded-xl p-6 bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800">
            <p class="text-gray-600 dark:text-gray-300 text-base font-medium leading-normal">Total Students</p>
            <p class="text-gray-900 dark:text-white tracking-tight text-3xl font-bold leading-tight">1,245</p>
            <p class="text-green-600 dark:text-green-500 text-sm font-medium leading-normal">+2.5% this month</p>
          </div>
          <div
            class="flex flex-col gap-2 rounded-xl p-6 bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800">
            <p class="text-gray-600 dark:text-gray-300 text-base font-medium leading-normal">Active Teachers</p>
            <p class="text-gray-900 dark:text-white tracking-tight text-3xl font-bold leading-tight">82</p>
            <p class="text-green-600 dark:text-green-500 text-sm font-medium leading-normal">+1.2% this month</p>
          </div>
          <div
            class="flex flex-col gap-2 rounded-xl p-6 bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800">
            <p class="text-gray-600 dark:text-gray-300 text-base font-medium leading-normal">Courses Offered</p>
            <p class="text-gray-900 dark:text-white tracking-tight text-3xl font-bold leading-tight">56</p>
            <p class="text-green-600 dark:text-green-500 text-sm font-medium leading-normal">+5 new courses</p>
          </div>
          <div
            class="flex flex-col gap-2 rounded-xl p-6 bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800">
            <p class="text-gray-600 dark:text-gray-300 text-base font-medium leading-normal">Recent Payments</p>
            <p class="text-gray-900 dark:text-white tracking-tight text-3xl font-bold leading-tight">$12,500</p>
            <p class="text-red-600 dark:text-red-500 text-sm font-medium leading-normal">-1.8% from last week</p>
          </div>
        </div>
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div class="lg:col-span-2 flex flex-col gap-8">
            <div class="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-6">
              <h2 class="text-gray-900 dark:text-white text-xl font-bold leading-tight tracking-tight mb-4">Quick
                Actions</h2>
              <div class="grid grid-cols-2 sm:grid-cols-3 gap-4">
                <button
                  class="flex flex-col items-center justify-center gap-2 p-4 rounded-lg bg-blue-50 dark:bg-blue-900/40 hover:bg-blue-100 dark:hover:bg-blue-900/60 text-blue-600 transition-colors">
                  <span class="material-symbols-outlined text-3xl font-normal">person_add</span>
                  <span class="text-sm font-medium">Add Student</span>
                </button>
                <button
                  class="flex flex-col items-center justify-center gap-2 p-4 rounded-lg bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors">
                  <span class="material-symbols-outlined text-3xl font-normal">post_add</span>
                  <span class="text-sm font-medium">Create Course</span>
                </button>
                <button
                  class="flex flex-col items-center justify-center gap-2 p-4 rounded-lg bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors">
                  <span class="material-symbols-outlined text-3xl font-normal">campaign</span>
                  <span class="text-sm font-medium">Announcement</span>
                </button>
                <button
                  class="flex flex-col items-center justify-center gap-2 p-4 rounded-lg bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors">
                  <span class="material-symbols-outlined text-3xl font-normal">event</span>
                  <span class="text-sm font-medium">New Event</span>
                </button>
                <button
                  class="flex flex-col items-center justify-center gap-2 p-4 rounded-lg bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors">
                  <span class="material-symbols-outlined text-3xl font-normal">receipt_long</span>
                  <span class="text-sm font-medium">Generate Invoice</span>
                </button>
                <button
                  class="flex flex-col items-center justify-center gap-2 p-4 rounded-lg bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors">
                  <span class="material-symbols-outlined text-3xl font-normal">description</span>
                  <span class="text-sm font-medium">View Reports</span>
                </button>
              </div>
            </div>
            <div class="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-6">
              <h2 class="text-gray-900 dark:text-white text-xl font-bold leading-tight tracking-tight mb-4">Recent
                Enrollments</h2>
              <div class="overflow-x-auto">
                <table class="w-full text-left">
                  <thead>
                    <tr class="text-sm text-gray-500 dark:text-gray-400 border-b border-gray-200 dark:border-gray-700">
                      <th class="py-3 px-4 font-medium">Student Name</th>
                      <th class="py-3 px-4 font-medium">Course</th>
                      <th class="py-3 px-4 font-medium">Date</th>
                      <th class="py-3 px-4 font-medium">Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr class="border-b border-gray-200 dark:border-gray-800 text-sm">
                      <td class="py-3 px-4 flex items-center gap-3">
                        <div class="bg-center bg-no-repeat aspect-square bg-cover rounded-full w-8 h-8"
                          data-alt="avatar of Olivia Martin"
                          style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuBKqYQ-lFCKRgrfI4EPnefW878hsy7gNRqQPqj8s8E5Ge1-_XBtng98qY0IAC49HZtbBQbq_Xmm4WmqZTwnBA_u537-Oo3_Bo4ROEj9ufUtCi4z9_rT-JasRis5CI7aU-r4EgoVDyUSSL43L90Fx5kY6QLXVMw6PuhYB_Wpdku2jGXGTXlkeOHm_Q2XgxRygRF4fkXUKJxzjygS0_ITnoHauhzBh15UCG0VN28rIU4wC0Q1FFpiLqZxefa17HrnD0ReSRauHALa7YI");'>
                        </div>
                        Olivia Martin
                      </td>
                      <td class="py-3 px-4">Computer Science</td>
                      <td class="py-3 px-4">2024-07-21</td>
                      <td class="py-3 px-4"><span
                          class="bg-green-100 text-green-700 dark:bg-green-900/50 dark:text-green-400 text-xs font-medium px-2 py-1 rounded-full">Paid</span>
                      </td>
                    </tr>
                    <tr class="border-b border-gray-200 dark:border-gray-800 text-sm">
                      <td class="py-3 px-4 flex items-center gap-3">
                        <div class="bg-center bg-no-repeat aspect-square bg-cover rounded-full w-8 h-8"
                          data-alt="avatar of Liam Johnson"
                          style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuAbXVPxwq9gR05ET4Kg0zCkBedYQjSJZmR3DH8SdyUnxZGoM_metNxBWCUUuSnCOssD-X8VxfXiG9Yn8EfI7K0CBy89bmtD6VOri4Otu7fyWyW17ze__SksK4FO4Nm3RhWu-tuH6YoqZe3BrXGRN0eEcf4YPYy9ZVCVUjpcTsQ7vITeB-vBntfVqWXHEoBs6-F3MNAfRrD6TPd_ulew3ZSwkPOR99c991viv5iDIKdMeoP5NnXZHRFkvdpt45KCw-xhpWJaokfXO-4");'>
                        </div>
                        Liam Johnson
                      </td>
                      <td class="py-3 px-4">Mathematics 101</td>
                      <td class="py-3 px-4">2024-07-20</td>
                      <td class="py-3 px-4"><span
                          class="bg-green-100 text-green-700 dark:bg-green-900/50 dark:text-green-400 text-xs font-medium px-2 py-1 rounded-full">Paid</span>
                      </td>
                    </tr>
                    <tr class="border-b border-gray-200 dark:border-gray-800 text-sm">
                      <td class="py-3 px-4 flex items-center gap-3">
                        <div class="bg-center bg-no-repeat aspect-square bg-cover rounded-full w-8 h-8"
                          data-alt="avatar of Noah Williams"
                          style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuC0-OZADNa-IOAewhuFRea32GhnTvSizf8IS7oJQCoW7uVPOToTNdbnfTGSgQdK2_aazL5e3yrXwWx9ytQRzabYngl2KRa100dLvLcWHTf8YH24sSOeI_cUDKZTq154ssb9O_ltPlYsH_elSHIo5jkwQ8hYYdKSESjp5-M_aY2blXiJ1y-xpC-Q0x7GWNq3JGWv52TwBe_bbUyVrAmWaRkl5zg1G8ld4KFLDZxeB_IGkorYr_4N8EAD49G9_7E9KOu9S0MyWLhLHXs");'>
                        </div>
                        Noah Williams
                      </td>
                      <td class="py-3 px-4">History of Art</td>
                      <td class="py-3 px-4">2024-07-19</td>
                      <td class="py-3 px-4"><span
                          class="bg-yellow-100 text-yellow-700 dark:bg-yellow-900/50 dark:text-yellow-400 text-xs font-medium px-2 py-1 rounded-full">Pending</span>
                      </td>
                    </tr>
                    <tr class="text-sm">
                      <td class="py-3 px-4 flex items-center gap-3">
                        <div class="bg-center bg-no-repeat aspect-square bg-cover rounded-full w-8 h-8"
                          data-alt="avatar of Emma Brown"
                          style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuC_yRDDWRHorUiz0qbFEELV1j4CH5u7Pi8lNcqwN_NtNOzzmmXcLVj1axHQygvNQtzXQuDy_WkVr48kqu5bnmVmaRknP1wRgyFHJ0ERmHZ1ExwN-9Wqgojlr03kwVw9G0tQZ1LAdNn1qJJqPVvUwb4YiQRrkrevxFplJFS3LWtv2j3JA8GtCWs8wVtXw44pdWfb7d68qYZ-F37TizWABbG75ItHnbVZC8XlKJTD_otQmgkGtRdNZeoKOiYLoBJNe3JIPJHtx766U-8");'>
                        </div>
                        Emma Brown
                      </td>
                      <td class="py-3 px-4">Physics II</td>
                      <td class="py-3 px-4">2024-07-18</td>
                      <td class="py-3 px-4"><span
                          class="bg-green-100 text-green-700 dark:bg-green-900/50 dark:text-green-400 text-xs font-medium px-2 py-1 rounded-full">Paid</span>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
          <div class="lg:col-span-1 flex flex-col gap-8">
            <div class="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-6">
              <h2 class="text-gray-900 dark:text-white text-xl font-bold leading-tight tracking-tight mb-4">Upcoming
                Events</h2>
              <div class="flex flex-col gap-4">
                <div class="flex gap-4">
                  <div
                    class="flex flex-col items-center justify-center bg-blue-50 dark:bg-blue-900/40 text-blue-600 rounded-lg p-2 w-16 h-16 shrink-0">
                    <span class="text-sm font-medium">JUL</span>
                    <span class="text-2xl font-bold">25</span>
                  </div>
                  <div>
                    <h3 class="font-semibold text-gray-800 dark:text-gray-100">Parent-Teacher Meeting</h3>
                    <p class="text-sm text-gray-500 dark:text-gray-400">10:00 AM - Main Hall</p>
                  </div>
                </div>
                <div class="flex gap-4">
                  <div
                    class="flex flex-col items-center justify-center bg-gray-100 dark:bg-gray-800 rounded-lg p-2 w-16 h-16 shrink-0">
                    <span class="text-sm font-medium">AUG</span>
                    <span class="text-2xl font-bold">02</span>
                  </div>
                  <div>
                    <h3 class="font-semibold text-gray-800 dark:text-gray-100">Science Fair</h3>
                    <p class="text-sm text-gray-500 dark:text-gray-400">All Day - Gymnasium</p>
                  </div>
                </div>
                <div class="flex gap-4">
                  <div
                    class="flex flex-col items-center justify-center bg-gray-100 dark:bg-gray-800 rounded-lg p-2 w-16 h-16 shrink-0">
                    <span class="text-sm font-medium">AUG</span>
                    <span class="text-2xl font-bold">15</span>
                  </div>
                  <div>
                    <h3 class="font-semibold text-gray-800 dark:text-gray-100">Mid-term Exams Begin</h3>
                    <p class="text-sm text-gray-500 dark:text-gray-400">School-wide</p>
                  </div>
                </div>
              </div>
            </div>
            <div class="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-6">
              <h2 class="text-gray-900 dark:text-white text-xl font-bold leading-tight tracking-tight mb-4">Enrollment
                Trends</h2>
              <div class="flex items-end justify-between h-48 gap-3">
                <div class="flex flex-col items-center justify-end h-full gap-2">
                  <div class="w-8 bg-blue-100 dark:bg-blue-900/60 rounded-t-lg" style="height: 60%;"></div>
                  <span class="text-xs text-gray-500 dark:text-gray-400">Feb</span>
                </div>
                <div class="flex flex-col items-center justify-end h-full gap-2">
                  <div class="w-8 bg-blue-100 dark:bg-blue-900/60 rounded-t-lg" style="height: 75%;"></div>
                  <span class="text-xs text-gray-500 dark:text-gray-400">Mar</span>
                </div>
                <div class="flex flex-col items-center justify-end h-full gap-2">
                  <div class="w-8 bg-blue-100 dark:bg-blue-900/60 rounded-t-lg" style="height: 50%;"></div>
                  <span class="text-xs text-gray-500 dark:text-gray-400">Apr</span>
                </div>
                <div class="flex flex-col items-center justify-end h-full gap-2">
                  <div class="w-8 bg-blue-100 dark:bg-blue-900/60 rounded-t-lg" style="height: 85%;"></div>
                  <span class="text-xs text-gray-500 dark:text-gray-400">May</span>
                </div>
                <div class="flex flex-col items-center justify-end h-full gap-2">
                  <div class="w-8 bg-blue-100 dark:bg-blue-900/60 rounded-t-lg" style="height: 65%;"></div>
                  <span class="text-xs text-gray-500 dark:text-gray-400">Jun</span>
                </div>
                <div class="flex flex-col items-center justify-end h-full gap-2">
                  <div class="w-8 bg-blue-600 rounded-t-lg" style="height: 95%;"></div>
                  <span class="text-xs text-blue-600 font-semibold">Jul</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    `
  }

}
