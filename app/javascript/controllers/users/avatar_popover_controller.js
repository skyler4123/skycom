import { Controller } from "@hotwired/stimulus"
import { myProfilePath } from "controllers/helpers/auth_helpers"

// Avatar dropdown menu shared by the company header (companies/layout_controller.js)
// and the homepage header (home/header/authentication_controller.js).
// Depends on BE: RedirectController#profile (GET /redirect/profile — fallback when
//   the signed-in user has no employee record). See docs/AVATAR.md §9.
export default class extends Controller {
  connect() {
    this.element.innerHTML = this.html()
  }

  html() {
    return `
      <div class="w-48">
        <a
          href="${myProfilePath()}"
          class="flex w-full items-center gap-3 rounded-md px-4 py-2 text-sm text-foreground hover:bg-muted">
          <span class="material-symbols-outlined text-sm">person</span>
          Profile
        </a>
        <div class="my-1 border-t border-line"></div>
        <a data-controller="sign-out" data-action="click->sign-out#handleClick" class="flex items-center gap-3 px-4 py-2 rounded-md text-sm text-danger hover:bg-danger/10 " href="/sign_out">
          <span class="material-symbols-outlined text-sm">logout</span>
          Sign Out
        </a>
      </div>
    `
  }
}
