import ApplicationController from "controllers/application_controller"
import { openModal, closeModal, csrfTokenTag, signInPath, signUpPath, poll } from "controllers/helpers"

export default class Home_IndexController extends ApplicationController {
  static targets = ["signInButton", "signUpButton"]

  init() {
    this.initActions()
  }

  initActions() {
    poll(() => {
      if (this.hasSignInButtonTarget) {
        this.addAction(this.signInButtonTarget, `click->${this.identifier}#openSignInModal`)
      }
      if (this.hasSignUpButtonTarget) {
        this.addAction(this.signUpButtonTarget, `click->${this.identifier}#openSignUpModal`)
      }
    })
  }

  openSignInModal(event) {
    event.preventDefault()
    // If a modal is already open, close it first before opening the new one.
    if (document.querySelector('.swal2-container')) {
      closeModal()
    }
    openModal({
      html: this.signInModalHTML()
    })
  }

  openSignUpModal(event) {
    event.preventDefault()
    if (document.querySelector('.swal2-container')) {
      closeModal()
    }
    openModal({
      html: this.signUpModalHTML()
    })
  }

  closeModal(event) {
    event.preventDefault()
    closeModal()
  }

  signInModalHTML() {
    return `
      <div class="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/50 backdrop-blur-sm p-4">
        <div class="relative w-full max-w-[480px] rounded-xl bg-white p-6 shadow-2xl md:p-8 dark:bg-slate-800">
          <button
            data-action="click->${this.identifier}#closeModal"
            class="absolute right-4 top-4 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 cursor-pointer">
            <span class="material-symbols-outlined">close</span>
          </button>
          <div class="mb-8 text-center">
            <h3 class="mb-2 text-2xl font-bold text-slate-900 dark:text-white">Sign In</h3>
            <p class="text-sm text-slate-600 dark:text-slate-400">Welcome back to Skycom</p>
          </div>
          <div class="flex flex-col gap-4">
            <button
              class="flex w-full items-center justify-center gap-3 rounded-lg border border-slate-200 bg-white px-4 py-2.5 text-sm font-medium text-slate-700 transition-colors hover:bg-slate-50 dark:border-slate-600 dark:bg-slate-700 dark:text-slate-200 dark:hover:bg-slate-600">
              <svg class="h-5 w-5" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                <path
                  d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                  fill="#4285F4"></path>
                <path
                  d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                  fill="#34A853"></path>
                <path
                  d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                  fill="#FBBC05"></path>
                <path
                  d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                  fill="#EA4335"></path>
              </svg>
              Sign in with Google
            </button>
            <div class="relative flex items-center py-2">
              <div class="flex-grow border-t border-slate-200 dark:border-slate-700"></div>
              <span class="flex-shrink-0 px-4 text-xs font-medium text-slate-500 uppercase">Or sign in with
                email</span>
              <div class="flex-grow border-t border-slate-200 dark:border-slate-700"></div>
            </div>
            
            <!-- Sign In Form -->
            <form
              role="sign-in-form"
              action="${signInPath()}"
              method="POST"
              class="">
              ${csrfTokenTag()}
              <div class="space-y-4">
                <div>
                  <label class="mb-1.5 block text-sm font-medium text-slate-700 dark:text-slate-300 text-left"
                    for="email">Email</label>
                  <input
                    class="block w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-slate-900 placeholder-slate-400 focus:border-indigo-600 focus:outline-none focus:ring-1 focus:ring-indigo-600 dark:border-slate-600 dark:bg-slate-700 dark:text-white dark:placeholder-slate-400"
                    id="email" name="email" placeholder="name@company.com" type="email" />
                </div>
                <div>
                  <label class="mb-1.5 block text-sm font-medium text-slate-700 dark:text-slate-300 text-left"
                    for="password">Password</label>
                  <input
                    class="block w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-slate-900 placeholder-slate-400 focus:border-indigo-600 focus:outline-none focus:ring-1 focus:ring-indigo-600 dark:border-slate-600 dark:bg-slate-700 dark:text-white dark:placeholder-slate-400"
                    id="password" name="password" placeholder="••••••••" type="password" />
                </div>
              </div>
              <button
                class="mt-2 w-full rounded-lg bg-indigo-600 px-4 py-2.5 text-sm font-bold text-white shadow-sm hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-indigo-600 focus:ring-offset-2">
                Sign In
              </button>
            </form>
            <!-- Sign In Form -->

            <p class="text-center text-sm text-slate-600 dark:text-slate-400">
              Don't have an account?
              <button
                data-action="click->${this.identifier}#openSignUpModal:once"
                class="font-medium text-indigo-600 hover:underline cursor-pointer">Sign Up
              </button>
            </p>
          </div>
        </div>
      </div>
    `
  }

  signUpModalHTML() {
    return `
      <div class="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/50 backdrop-blur-sm p-4">
        <div class="relative w-full max-w-[480px] rounded-xl bg-white p-6 shadow-2xl md:p-8 dark:bg-slate-800">
          <button
            data-action="click->${this.identifier}#closeModal"
            class="absolute right-4 top-4 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 cursor-pointer">
            <span class="material-symbols-outlined">close</span>
          </button>
          <div class="mb-8 text-center">
            <h3 class="mb-2 text-2xl font-bold text-slate-900 dark:text-white">Create your account</h3>
            <p class="text-sm text-slate-600 dark:text-slate-400">Join Skycom to manage your business effectively
            </p>
          </div>
          <div class="flex flex-col gap-4">
            <button
              class="flex w-full items-center justify-center gap-3 rounded-lg border border-slate-200 bg-white px-4 py-2.5 text-sm font-medium text-slate-700 transition-colors hover:bg-slate-50 dark:border-slate-600 dark:bg-slate-700 dark:text-slate-200 dark:hover:bg-slate-600">
              <svg class="h-5 w-5" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                <path
                  d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                  fill="#4285F4"></path>
                <path
                  d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                  fill="#34A853"></path>
                <path
                  d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                  fill="#FBBC05"></path>
                <path
                  d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                  fill="#EA4335"></path>
              </svg>
              Sign up with Google
            </button>
            <div class="relative flex items-center py-2">
              <div class="flex-grow border-t border-slate-200 dark:border-slate-700"></div>
              <span class="flex-shrink-0 px-4 text-xs font-medium text-slate-500 uppercase">Or sign up with
                email</span>
              <div class="flex-grow border-t border-slate-200 dark:border-slate-700"></div>
            </div>

            <!-- Form -->
            <form
              role="sign-up-form"
              action="${signUpPath()}"
              method="POST"
              class="">
              ${csrfTokenTag()}
              <div class="space-y-4">
                <div>
                  <label class="mb-1.5 block text-sm font-medium text-slate-700 dark:text-slate-300 text-left"
                    for="email">Email</label>
                  <input
                    class="block w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-slate-900 placeholder-slate-400 focus:border-indigo-600 focus:outline-none focus:ring-1 focus:ring-indigo-600 dark:border-slate-600 dark:bg-slate-700 dark:text-white dark:placeholder-slate-400"
                    id="email" name="email" placeholder="name@company.com" type="email" />
                </div>
                <div>
                  <label class="mb-1.5 block text-sm font-medium text-slate-700 dark:text-slate-300 text-left"
                    for="password">Password</label>
                  <input
                    class="block w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-slate-900 placeholder-slate-400 focus:border-indigo-600 focus:outline-none focus:ring-1 focus:ring-indigo-600 dark:border-slate-600 dark:bg-slate-700 dark:text-white dark:placeholder-slate-400"
                    id="password" name="password" placeholder="••••••••" type="password" />
                </div>
                <div>
                  <label class="mb-1.5 block text-sm font-medium text-slate-700 dark:text-slate-300 text-left"
                    for="confirm-password">Password confirmation</label>
                  <input
                    class="block w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-slate-900 placeholder-slate-400 focus:border-indigo-600 focus:outline-none focus:ring-1 focus:ring-indigo-600 dark:border-slate-600 dark:bg-slate-700 dark:text-white dark:placeholder-slate-400"
                    id="confirm-password" name="password_confirmation" placeholder="••••••••" type="password" />
                </div>
              </div>
              <button
                class="mt-2 w-full rounded-lg bg-indigo-600 px-4 py-2.5 text-sm font-bold text-white shadow-sm hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-indigo-600 focus:ring-offset-2">
                Sign Up
              </button>
            </form>
            <!-- Form -->

            <p class="text-center text-sm text-slate-600 dark:text-slate-400">
              Already have an account?
              <button
                data-action="click->${this.identifier}#openSignInModal:once"
                class="font-medium text-indigo-600 hover:underline cursor-pointer">Sign In
              </button>
            </p>
          </div>
        </div>
      </div>
    `
  }
}
