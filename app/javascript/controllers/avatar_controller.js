import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "image"]
  static values = {
    uploadUrl: String,        // The endpoint: e.g., /companies/1/update_avatar
    paramName: String,  // The key: e.g., company[avatar_attachment]
    method: { type: String, default: "PATCH" }
  }

  browse() {
    this.inputTarget.click()
  }

  async upload(event) {
    const file = event.target.files[0]
    if (!file) return

    // 1. Instant Local Preview
    const reader = new FileReader()
    reader.onload = (e) => { this.imageTarget.src = e.target.result }
    reader.readAsDataURL(file)

    // 2. Prepare Generic FormData
    const formData = new FormData()
    formData.append(this.paramNameValue, file)

    try {
      // Assuming you have a fetchJson helper that handles CSRF
      const response = await fetchJson(this.uploadUrlValue, {
        method: this.methodValue,
        body: formData
      })

      // 3. Update with the real processed URL from the server
      if (response.url) {
        this.imageTarget.src = response.url
      }
      
      toast({ type: "success", message: response.message || "Updated successfully" })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || "Upload failed" })
    }
  }
}