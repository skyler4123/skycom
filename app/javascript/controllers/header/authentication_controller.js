import ApplicationController from "controllers/application_controller";
import { isSignedIn, signOutPath } from "controllers/helpers"
import Home_IndexController from "controllers/home/index_controller";

export default class Header_AuthenticationController extends ApplicationController {
  static targets = ["signInButton", "signUpButton"]
  static values = {
    isSignedIn: { type: Boolean, default: false }
  }

  init() {
    this.initBindings()
    this.initValues()
  }

  initBindings() {}

  initValues() {
    this.isSignedInValue = isSignedIn()
  }

  isSignedInValueChanged(value, previousValue) {
    if (value) {
      this.renderSignedIn()
    } else {
      this.renderSignedOut()
    }
  }

  renderSignedIn() {
    this.element.innerHTML = `
      <div class="flex items-center gap-2">
        <div
          class="bg-center bg-no-repeat aspect-square bg-cover rounded-full h-10 w-10 border border-slate-200 dark:border-slate-700"
          style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuDmCMcaKuxM-L3kekIel30wVgf_J-ssrf86FqOelUJrmeAHwneIxkCor7hKn3SzOtbLg3DrSVpbI77hxo-i174Ll7V-lQ8CTCQB3H9YEA5_LSG8vyi_FynSf8l4w3lgYkc2uFLpD4U1w_DzdTIiCUzYkrAkVoZumb-iT_CjUsLofbZCfryp_hfJBATT8XUgqjbHSZdKEhdoREZiwf1ZCevLreCxK463hwZhGxwb6xu2NoSIYjbWxlfEmD5ABwPppLeyiUqyCCWWVw0");'>
        </div>
      </div>
      <a href="${signOutPath()}">
        <button
          class="flex min-w-[84px] max-w-[480px] cursor-pointer items-center justify-center overflow-hidden rounded-lg h-10 px-4 bg-slate-200 dark:bg-slate-700 text-slate-900 dark:text-slate-100 text-sm font-bold leading-normal tracking-[0.015em]">
          <span class="truncate">Sign Out</span>
        </button>
      </a>
    `
  }

  renderSignedOut() {
    this.element.innerHTML = `
      <button
        data-${Home_IndexController.identifier}-target="signInButton"
        data-home--index-target="signInButton"
        class="flex min-w-[84px] max-w-[480px] cursor-pointer items-center justify-center overflow-hidden rounded-lg h-10 px-4 bg-slate-200 dark:bg-slate-700 text-slate-900 dark:text-slate-100 text-sm font-bold leading-normal tracking-[0.015em]">
        <span class="truncate">Sign In</span>
      </button>
      <button
        data-${Home_IndexController.identifier}-target="signUpButton"
        data-home--index-target="signUpButton"
        class="flex min-w-[84px] max-w-[480px] cursor-pointer items-center justify-center overflow-hidden rounded-lg h-10 px-4 bg-indigo-600 text-white text-sm font-bold leading-normal tracking-[0.015em]">
        <span class="truncate">Sign Up</span>
      </button>
    `
  }

}
