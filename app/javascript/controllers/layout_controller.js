import ApplicationController from "controllers/application_controller"

export default class LayoutController extends ApplicationController {
  static targets = ["profileDropdown", "headerSubmenuContainer", "headerSubmenuContent"]
  static values = {
    pagination: { type: Object, default: {} },
    flash: { type: Object, default: {} },
    data: { type: Object, default: {} },
    isOpenProfileDropdown: { type: Boolean, default: false },
    openHeaderSubmenuName: { type: String, default: "" },
    
  }

  initBinding() {}

  initLayout() {
    // add headTags to head
    document.head.insertAdjacentHTML("beforeend", this.headTags())

    // set body class and innerHTML
    this.element.className = 'min-h-screen flex flex-col'
    this.element.innerHTML = this.layoutHTML()
  }
  
  headTags() {
    return `
      <link href="https://fonts.googleapis.com/css2?family=Lexend:wght@100..900&amp;display=swap" rel="stylesheet" />
      <link
        href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200"
        rel="stylesheet" />
    `
  }
  
  layoutHTML() {
    return `
      <div class="font-sans bg-gray-50 dark:bg-gray-950 text-gray-800 dark:text-gray-200">
        <div class="flex h-screen">
          <aside
            class="w-64 shrink-0 bg-white dark:bg-gray-900 border-r border-gray-200 dark:border-gray-800 flex flex-col">
            <div class="p-6 flex items-center gap-3 border-b border-gray-200 dark:border-gray-800">
              <div class="bg-blue-100 text-blue-600 p-2 rounded-lg">
                <span class="material-symbols-outlined font-normal">school</span>
              </div>
              <div class="flex flex-col">
                <h1 class="text-gray-900 dark:text-white text-base font-medium leading-normal">Greenwood High</h1>
                <p class="text-gray-500 dark:text-gray-400 text-sm font-normal leading-normal">School Admin</p>
              </div>
            </div>
            <nav class="grow p-4">
              <div class="flex flex-col gap-2">
                <a 
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:!bg-blue-100 open:!text-blue-600 open:!bg-blue-100 open:!text-blue-600"
                  data-link-target="openByPathname"
                  href="/school/schools"
                >
                  <span class="material-symbols-outlined font-normal">dashboard</span>
                  <p class="text-sm font-medium leading-normal">Dashboard</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:!bg-blue-100 open:!text-blue-600"
                  data-link-target="openByPathname"
                  href="/school/courses"
                >
                  <span class="material-symbols-outlined font-normal">menu_book</span>
                  <p class="text-sm font-medium leading-normal">Course</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:!bg-blue-100 open:!text-blue-600"
                  data-link-target="openByPathname"
                  href="#"
                >
                  <span class="material-symbols-outlined font-normal">class</span>
                  <p class="text-sm font-medium leading-normal">Class</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:!bg-blue-100 open:!text-blue-600"
                  data-link-target="openByPathname"
                  href="#"
                >
                  <span class="material-symbols-outlined font-normal">school</span>
                  <p class="text-sm font-medium leading-normal">Student</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:!bg-blue-100 open:!text-blue-600"
                  data-link-target="openByPathname"
                  href="#"
                >
                  <span class="material-symbols-outlined font-normal">co_present</span>
                  <p class="text-sm font-medium leading-normal">Teacher</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:!bg-blue-100 open:!text-blue-600"
                  data-link-target="openByPathname"
                  href="#"
                >
                  <span class="material-symbols-outlined font-normal">groups</span>
                  <p class="text-sm font-medium leading-normal">Staffs/Employees</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:!bg-blue-100 open:!text-blue-600"
                  data-link-target="openByPathname"
                  href="#"
                >
                  <span class="material-symbols-outlined font-normal">domain</span>
                  <p class="text-sm font-medium leading-normal">Facilities</p>
                </a>
                <a
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:!bg-blue-100 open:!text-blue-600"
                  data-link-target="openByPathname"
                  href="#"
                >
                  <span class="material-symbols-outlined font-normal">payments</span>
                  <p class="text-sm font-medium leading-normal">Payment/Invoice</p>
                </a>
              </div>
            </nav>
            <div class="p-4 border-t border-gray-200 dark:border-gray-800">
              <div class="flex flex-col gap-2">
                <a class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:!bg-blue-100 open:!text-blue-600" href="#">
                  <span class="material-symbols-outlined font-normal">settings</span>
                  <p class="text-sm font-medium leading-normal">Setting</p>
                </a>
                <a class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:!bg-blue-100 open:!text-blue-600" href="#">
                  <span class="material-symbols-outlined font-normal">admin_panel_settings</span>
                  <p class="text-sm font-medium leading-normal">Administrator</p>
                </a>
              </div>
            </div>
          </aside>
          <main class="flex-1 flex flex-col overflow-auto">
            <header
              class="shrink-0 flex items-center justify-between whitespace-nowrap border-b border-gray-200 dark:border-gray-800 px-8 py-4 bg-white dark:bg-gray-900">
              <div class="flex items-center gap-8">
                <label class="flex flex-col min-w-40 h-10! w-80">
                  <div class="flex w-full flex-1 items-stretch rounded-lg h-full">
                    <div
                      class="text-gray-500 flex bg-gray-100 dark:bg-gray-800 items-center justify-center pl-4 rounded-l-lg border-r-0">
                      <span class="material-symbols-outlined font-normal">search</span>
                    </div>
                    <input
                      class="form-input flex w-full min-w-0 flex-1 resize-none overflow-hidden rounded-lg text-gray-900 dark:text-white focus:outline-0 focus:ring-0 border-none bg-gray-100 dark:bg-gray-800 h-full placeholder:text-gray-500 px-4 rounded-l-none border-l-0 pl-2 text-base font-normal leading-normal"
                      placeholder="Search for students, teachers..." value="" />
                  </div>
                </label>
              </div>
              <div class="flex flex-1 justify-end gap-4 items-center">
                <button
                  class="flex cursor-pointer items-center justify-center overflow-hidden rounded-full h-10 w-10 hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-600 dark:text-gray-300">
                  <span class="material-symbols-outlined font-normal">notifications</span>
                </button>
                <button
                  class="flex cursor-pointer items-center justify-center overflow-hidden rounded-full h-10 w-10 hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-600 dark:text-gray-300">
                  <span class="material-symbols-outlined font-normal">settings</span>
                </button>
                <div class="bg-center bg-no-repeat aspect-square bg-cover rounded-full w-10 h-10"
                  data-alt="User profile picture"
                  style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuBYk6_5wqHwhOUyfqIOzuw7uF6nG1B2aHcNfqPXgheh0TJNM9wgrKtU__k7USaOwDZLXPpvIrYvaXBnMbO7rmZHK15vMirHZqrK0UBZ18vJdiQZlmTrGe8wch8p3G7GXSetuz5njKmy7Hb6XGw18g0stonxhwtIcuuEqzZVHxbviNLuy4i_B8JHC1x_JlbUrZoIV2QQqyAprbH-jems99h8nqDZ6D6FBmq8JDrKIfaBYkl3mR0cYldl3c0gaNynjiRNKDKfaUcIKBc");'>
                </div>
              </div>
            </header>
            ${this.contentHTML()}
          </main>
        </div>
      </div>
    `
  }

}
