// Tailwind class pairs for WorkflowStep color. These string literals are kept
// here (and mirrored in config/initializers/constants.rb) so Tailwind can scan
// and compile them. Keys must match the backend WORKFLOW_STEP_COLORS keys.
export const WORKFLOW_STEP_COLOR_OPTIONS = [
  { key: "slate",   label: "Slate",   text: "text-slate-700 dark:text-slate-300",   background: "bg-slate-100 dark:bg-slate-800" },
  { key: "blue",    label: "Blue",    text: "text-blue-700 dark:text-blue-300",     background: "bg-blue-100 dark:bg-blue-900/30" },
  { key: "emerald", label: "Emerald", text: "text-emerald-700 dark:text-emerald-300", background: "bg-emerald-100 dark:bg-emerald-900/30" },
  { key: "amber",   label: "Amber",   text: "text-amber-700 dark:text-amber-300",   background: "bg-amber-100 dark:bg-amber-900/30" },
  { key: "rose",    label: "Rose",    text: "text-rose-700 dark:text-rose-300",     background: "bg-rose-100 dark:bg-rose-900/30" },
  { key: "indigo",  label: "Indigo",  text: "text-indigo-700 dark:text-indigo-300", background: "bg-indigo-100 dark:bg-indigo-900/30" },
  { key: "violet",  label: "Violet",  text: "text-violet-700 dark:text-violet-300", background: "bg-violet-100 dark:bg-violet-900/30" },
  { key: "teal",    label: "Teal",    text: "text-teal-700 dark:text-teal-300",    background: "bg-teal-100 dark:bg-teal-900/30" }
]

export const findWorkflowColorOption = (textColor, backgroundColor) => {
  return WORKFLOW_STEP_COLOR_OPTIONS.find(o => o.text === textColor && o.background === backgroundColor)
    || WORKFLOW_STEP_COLOR_OPTIONS[0]
}