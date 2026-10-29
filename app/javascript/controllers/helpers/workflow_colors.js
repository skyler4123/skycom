// Semantic class pairs for WorkflowStep color. These string literals are kept
// here (and mirrored in config/initializers/constants.rb) so Tailwind can scan
// and compile them. Keys must match the backend WORKFLOW_STEP_COLORS keys.
//
// Values are semantic tokens, not palette names: changing --primary or the
// status tokens in app/assets/tailwind/application.css recolors every workflow
// step automatically. No dark: variants — the CSS variables switch themselves.
export const WORKFLOW_STEP_COLOR_OPTIONS = [
  { key: "neutral", label: "Neutral", text: "text-muted-foreground", background: "bg-muted" },
  { key: "primary", label: "Primary", text: "text-primary",          background: "bg-primary/10" },
  { key: "success", label: "Success", text: "text-success",          background: "bg-success/10" },
  { key: "warning", label: "Warning", text: "text-warning",          background: "bg-warning/10" },
  { key: "danger",  label: "Danger",  text: "text-danger",           background: "bg-danger/10" },
  { key: "info",    label: "Info",    text: "text-info",             background: "bg-info/10" }
]

export const findWorkflowColorOption = (textColor, backgroundColor) => {
  return WORKFLOW_STEP_COLOR_OPTIONS.find(o => o.text === textColor && o.background === backgroundColor)
    || WORKFLOW_STEP_COLOR_OPTIONS[0]
}
