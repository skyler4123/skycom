import { Controller } from "@hotwired/stimulus";

import Home_SigninModalController from "controllers/home/signin_modal_controller";
import Home_SignupModalController from "controllers/home/signup_modal_controller";

export default class Home_Header_AuthenticationController extends Controller {
  static targets = ["signInButton", "signUpButton"]
  static values = {
    isSignedIn: { type: Boolean, default: false }
  }

  initialize() {
    this.initValues()
  }

  initValues() {
    this.isSignedInValue = Helpers.isSignedIn()
  }

  isSignedInValueChanged(value, previousValue) {
    if (value) {
      this.renderSignedIn()
    } else {
      this.renderSignedOut()
    }
  }

  openSignInModal(event) {
    event.preventDefault()
    openModal({
      html: `<div data-controller="${identifier(Home_SigninModalController)}"></div>`,
      backdrop: false,
    })
  }

  openSignUpModal(event) {
    event.preventDefault()
    openModal({
      html: `<div data-controller="${identifier(Home_SignupModalController)}"></div>`,
      backdrop: false,
    })
  }

  renderSignedIn() {
    console.log(currentUser())
    this.element.innerHTML = `
      ${avatar({
        url: currentUser()?.avatar,
        className: "size-12 cursor-pointer",
        // 2. Middle attributes (e.g., for your popover controller)
        innerAttributes: popover({
          position: "bottom",
          html: `<div data-controller="users--avatar-popover"></div>`
        })
      })}
    `
  }

  renderSignedOut() {
    this.element.innerHTML = `
      <button
        role="sign-in-button"
        data-action="click->${this.identifier}#openSignInModal"
        class="flex min-w-[84px] max-w-[480px] cursor-pointer items-center justify-center overflow-hidden rounded-lg h-10 px-4 bg-slate-200 dark:bg-slate-700 text-slate-900 dark:text-slate-100 text-sm font-bold leading-normal tracking-[0.015em]">
        <span class="truncate">Sign In</span>
      </button>
      <button
        role="sign-up-button"
        data-action="click->${this.identifier}#openSignUpModal"
        data-home--index-target="signUpButton"
        class="flex min-w-[84px] max-w-[480px] cursor-pointer items-center justify-center overflow-hidden rounded-lg h-10 px-4 bg-indigo-600 text-white text-sm font-bold leading-normal tracking-[0.015em]">
        <span class="truncate">Sign Up</span>
      </button>
    `
  }

}
