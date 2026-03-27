import { Controller } from "@hotwired/stimulus"

export default class AuthenticationController extends Controller {
  connect() {
    this.checkAccess()
  }

  checkAccess() {
    setTimeout(() => {
      setInterval(() => {
        if (isSignedIn()) return;
        removeCookie("session_token")
        console.warn("No session detected. Redirecting...")    
        // window.location.href = Helpers.root_path()
      }, 1000)
    }, 5000)
  }
}
