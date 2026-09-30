// app/javascript/controllers/companies/form_submit.js
//
// Shared submit interceptor for the calendar_* forms.
//
// Helpers.form() emits a plain <form>, so without an interceptor the browser
// would navigate to the endpoint and render the raw JSON response. Every other
// page in this app relies on the server issuing a redirect instead — but the
// calendar module is JSON-only by design (AGENTS.md: "Data Flow: JSON API, avoid
// server-side HTML partials"), so these forms intercept the submit, call
// fetchJson, and dispatch the same form:success / form:error events the rest of
// the app listens for.
//
// @param {HTMLElement} form
// @param {(payload: any) => string} buildBody  - turn the form into a JSON body
// @param {(error: Error) => void} onError
export const submitViaJson = async (form, buildBody, onError) => {
  const method = (form.querySelector('input[name="_method"]')?.value || form.method || "post").toUpperCase()
  const action = form.getAttribute("action")

  try {
    const response = await fetchJson(action, { method, body: buildBody(form) })
    form.dispatchEvent(new CustomEvent("form:success", { bubbles: true, detail: { response } }))
    return response
  } catch (error) {
    form.dispatchEvent(new CustomEvent("form:error", { bubbles: true, detail: { error } }))
    if (onError) onError(error)
    return null
  }
}

/**
 * Serialises a <form> into the nested JSON body strong params expects.
 *
 * FormData yields FLAT bracket keys ("calendar_event[starts_at]"). Rails only
 * un-flattens those when it parses a form-encoded body — a JSON body is taken
 * literally, so `params.require(:calendar_event)` would raise ParameterMissing.
 * This converts them into real nested objects / arrays:
 *
 *   "calendar_event[starts_at]" -> { calendar_event: { starts_at: "..." } }
 *   "practitioner_ids[]"        -> { practitioner_ids: [ "..." ] }
 *
 * Blank values are dropped so an untouched optional field does not overwrite a
 * stored one with "". Rails' checkbox convention (hidden "0" + checkbox "1")
 * still works, because the hidden input is visited first.
 */
export const formBodyFromDom = (form) => {
  const body = {}

  new FormData(form).forEach((value, key) => {
    if (key === "_method" || key === "authenticity_token") return
    if (value === "") return

    const isArray = key.endsWith("[]")
    const flatKey = isArray ? key.slice(0, -2) : key
    const segments = flatKey.split("[").map((s) => s.replace(/\]$/, ""))
    const leaf = segments.pop()
    const path = segments.filter(Boolean)

    // Walk / build the nested containers.
    let node = body
    path.forEach((segment) => {
      if (node[segment] === undefined) node[segment] = {}
      else if (Array.isArray(node[segment])) node[segment] = node[segment][0]
      node = node[segment]
    })

    if (isArray) {
      if (!Array.isArray(node[leaf])) node[leaf] = []
      node[leaf].push(value)
    } else if (node[leaf] === undefined) {
      node[leaf] = value
    } else if (Array.isArray(node[leaf])) {
      node[leaf].push(value)
    } else {
      node[leaf] = [ node[leaf], value ]
    }
  })

  return body
}
