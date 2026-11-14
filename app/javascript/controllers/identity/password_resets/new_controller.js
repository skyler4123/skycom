import { Controller } from "@hotwired/stimulus"

// Depends on BE: Identity::PasswordResetsController#new (GET /identity/password_reset/new shell) + #create (POST /identity/password_reset).
// Reset password page — renders its form client-side (Shell-First).
export default class Identity_PasswordResets_NewController extends Controller {
  connect() {
    this.element.innerHTML = this.pageHTML()
  }

  pageHTML() {
    return `
      <div class="min-h-screen flex flex-col bg-background">
        <div class="flex-1 py-12">
        <div class="mx-auto w-full max-w-[480px] px-4">
          <a
            class="mb-8 flex items-center justify-center gap-2 cursor-pointer"
            href="/"
          >
            <img alt="Skycom Logo" class="h-8 w-auto object-contain" src="/icon.svg">
            <span class="text-lg font-bold tracking-tight text-foreground">Skycom</span>
          </a>
          <div class="rounded-xl bg-card p-6 shadow-2xl md:p-8 ">
            <div class="mb-6 flex flex-col items-center text-center">
              <div class="mb-4 flex h-14 w-14 items-center justify-center rounded-xl bg-primary text-primary-foreground shadow-lg shadow-primary/25">
                <span class="material-symbols-outlined text-[30px]">lock_reset</span>
              </div>
              <h1 class="mb-2 text-2xl font-bold text-foreground">Reset your password?</h1>
              <p class="text-sm text-muted-foreground">
                Enter the email associated with your Skycom account and we'll send you a secure verification link to reset your password.
              </p>
            </div>
            <form
              role="reset-password-form"
              action="${Helpers.identity_password_reset_path()}"
              method="POST"
              data-turbo="false"
              class="space-y-4"
            >
              ${Helpers.formPostSecurityTags()}
              <div class="space-y-1.5">
                <label class="mb-1.5 block text-sm font-medium text-foreground text-left" for="work-email">
                  Work Email Address
                </label>
                <div class="relative rounded-lg shadow-sm">
                  <div class="absolute left-3.5 top-1/2 -translate-y-1/2 flex items-center justify-center pointer-events-none text-muted-foreground">
                    <span class="material-symbols-outlined text-[20px] leading-none">mail</span>
                  </div>
                  <input
                    autocomplete="email"
                    class="block w-full h-11 pl-10 pr-4 rounded-lg border border-line bg-card text-foreground placeholder:text-muted-foreground focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary "
                    id="work-email" name="email" placeholder="name@company.com" type="email" />
                </div>
                <p class="flex items-center gap-1.5 pt-1 text-xs text-muted-foreground">
                  <span class="material-symbols-outlined text-[15px] text-muted-foreground">info</span>
                  Must match the email of your active tenant account.
                </p>
              </div>
              <button
                type="submit"
                class="mt-2 flex w-full items-center justify-center gap-2 rounded-lg bg-primary px-4 py-2.5 text-sm font-bold text-primary-foreground shadow-sm transition-all hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2 cursor-pointer"
              >
                <span>Send Reset Link</span>
                <span class="material-symbols-outlined text-[18px]">send</span>
              </button>
            </form>
            <div class="mt-6 flex justify-center">
              <a
                href="/sign_in"
                class="text-sm font-medium text-primary hover:underline cursor-pointer"
              >
                Back to Sign In
              </a>
            </div>
            <div class="mt-6 rounded-lg bg-muted/60 p-4 flex items-start gap-3">
              <span class="material-symbols-outlined text-primary text-[20px] shrink-0 mt-0.5">schedule</span>
              <p class="text-xs text-muted-foreground">
                Check your spam folder if you don't receive an email within 2 minutes. The link expires in <strong>15 minutes</strong> for security.
              </p>
            </div>
          </div>
        </div>
      </div>
      <footer class="w-full border-t border-line bg-background/80">
        <div class="mx-auto max-w-7xl px-4 py-6">
          <div class="flex flex-col items-center justify-between gap-4 md:flex-row">
            <p class="text-sm text-muted-foreground">© 2025 Skycom Technologies Inc. All rights reserved.</p>
            <div class="flex items-center gap-4">
              <a class="text-sm text-muted-foreground transition-colors hover:text-foreground " href="#">Privacy Policy</a>
              <a class="text-sm text-muted-foreground transition-colors hover:text-foreground " href="#">Security Center</a>
              <a class="text-sm text-muted-foreground transition-colors hover:text-foreground " href="#">Trust Center</a>
            </div>
          </div>
        </div>
      </footer>
      </div>
    `
  }
}
