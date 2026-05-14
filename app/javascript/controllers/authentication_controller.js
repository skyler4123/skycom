// Clear session_token will make BE know that user no longer signed in

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
        this.clearLocalStorage()
        console.warn("No session detected. Redirecting...")    
        // window.location.href = Helpers.root_path()
      }, 5000)
    }, 5000)
  }

  
  clearLocalStorage() {
    localStorage.clear();
    console.log("LocalStorage has been fully cleared.");
  }
}
