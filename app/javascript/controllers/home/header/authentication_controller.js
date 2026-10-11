import { Controller } from "@hotwired/stimulus";

// Homepage signed-in header slot (inside #header-signedin, unhidden client-side
// by home--index when the browser holds a session). Renders the avatar only;
// guests always use the static page links in #header-guest.
export default class Home_Header_AuthenticationController extends Controller {
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
      this.element.innerHTML = ""
    }
  }

  renderSignedIn() {
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

}
