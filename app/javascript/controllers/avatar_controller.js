import { Controller } from "@hotwired/stimulus"
import { clearClientCacheAndReload, fetchJson, toast, translate } from "controllers/helpers/ui_helpers"

// Shared avatar uploader rendered by the avatar() helper.
// Depends on BE: UsersController#update_avatar
// Endpoints: PATCH /users/update_avatar (multipart: user[avatar_attachment])
// Docs: docs/AVATAR.md
export default class extends Controller {
  static targets = ["input", "image"]
  static values = {
    uploadUrl: String,        // The endpoint: e.g., /users/update_avatar
    paramName: String,  // The key: e.g., user[avatar_attachment]
    method: { type: String, default: "PATCH" },
    reloadOnSuccess: { type: Boolean, default: false }
  }

  browse() {
    this.inputTarget.click()
  }

  async upload(event) {
    const file = event.target.files[0]
    if (!file) return

    const previousHTML = this.imageTarget.outerHTML
    const uploadId = this.nextUploadId()

    // 1. Instant Local Preview
    const reader = new FileReader()
    reader.onload = (e) => {
      if (uploadId === this.uploadSequence) this.imageTarget.src = e.target.result
    }
    reader.readAsDataURL(file)

    // 2. Prepare Generic FormData
    const formData = new FormData()
    formData.append(this.paramNameValue, file)

    try {
      const response = await fetchJson(this.uploadUrlValue, {
        method: this.methodValue,
        body: formData
      })

      this.nextUploadId()

      if (this.reloadOnSuccessValue) {
        clearClientCacheAndReload({ type: "success", message: response.message || translate("Avatar updated!") })
        return
      }

      // 3. Update with the real processed URL from the server
      if (response.url) {
        this.renderImage(response.url)
        this.syncCurrentUserAvatar(response.url)
      }

      toast({ type: "success", message: response.message || translate("Avatar updated!") })
    } catch (error) {
      // The server rejected the file: drop the local preview.
      this.nextUploadId()
      this.imageTarget.outerHTML = previousHTML
      toast({ type: "error", message: error.errors?.join(", ") || translate("Upload failed") })
    }
  }

  nextUploadId() {
    this.uploadSequence = (this.uploadSequence || 0) + 1
    return this.uploadSequence
  }

  // The empty state is a placeholder div; swap it for a real image the first
  // time an avatar is uploaded.
  renderImage(url) {
    if (this.imageTarget.tagName === "IMG") {
      this.imageTarget.src = url
      return
    }

    const image = document.createElement("img")
    image.setAttribute("data-avatar-target", "image")
    image.src = url
    image.alt = "Avatar"
    image.className = "h-full w-full object-cover pointer-events-none"
    this.imageTarget.replaceWith(image)
  }

  // Keep other current-user avatars (e.g. the mobile top bar) in sync.
  syncCurrentUserAvatar(url) {
    document.body.dataset.userAvatar = url
    document.querySelectorAll("[data-current-user-avatar]").forEach((image) => {
      image.src = url
      image.classList.remove("hidden")
    })
  }
}
