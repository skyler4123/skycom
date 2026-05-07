# Skycom Styling Guidelines

This document outlines the CSS/Tailwind styling conventions used throughout the Skycom project.

---

## 1. Use Default Tailwind Classes

Always use only default Tailwind CSS classes. Do not write custom CSS or use arbitrary values.

```javascript
// ✅ CORRECT - Default Tailwind classes
<button class="px-4 py-2 bg-blue-600 text-white rounded-lg">Save</button>

// ❌ WRONG - Custom CSS
<button class="my-custom-style">Save</button>
```

---

## 2. cursor-pointer for Clickable Elements

Always add `cursor-pointer` to any clickable element (buttons, links, icons, checkboxes).

```javascript
// ✅ CORRECT - cursor-pointer included
<button class="px-4 py-2 bg-blue-600 text-white rounded-lg cursor-pointer">Click</button>
<button class="p-2 text-slate-500 hover:text-blue-600 rounded-lg cursor-pointer">
  <span class="material-symbols-outlined">edit</span>
</button>

// ❌ WRONG - Missing cursor-pointer
<button class="px-4 py-2 bg-blue-600 text-white rounded-lg">Click</button>
```

---

## 3. Mobile First

Write base styles for mobile, then use `md:` or `lg:` breakpoints for larger screens.

```javascript
// ✅ CORRECT - Mobile first
<button class="px-4 py-2 md:px-6 md:py-3 bg-blue-600 text-white rounded-lg">
  Save
</button>

// ❌ WRONG - Desktop first (mobile not covered)
<button class="md:px-6 md:py-3 bg-blue-600 text-white rounded-lg">
  Save
</button>
```

---

## 4. Dark Mode

Always include both light mode and `dark:` variant for every element that needs theming.

```javascript
// ✅ CORRECT - Both light and dark mode
<button class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg dark:bg-blue-500 dark:hover:bg-blue-600">
  Save
</button>

// ❌ WRONG - Only light mode
<button class="px-4 py-2 bg-blue-600 text-white rounded-lg">
  Save
</button>
```

---

## 5. Single Line Classes

Never split Tailwind classes across multiple lines. Keep all classes on a single line even if very long.

```javascript
// ✅ CORRECT - Single line even with many classes
<button class="flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm whitespace-nowrap cursor-pointer dark:bg-blue-500 dark:hover:bg-blue-600 md:px-6 md:py-3">
  Save
</button>

// ❌ WRONG - Multi-line classes
<button class="
  flex items-center justify-center gap-2
  px-4 py-2 bg-blue-600 hover:bg-blue-700
  text-white rounded-lg font-medium
  cursor-pointer
">
  Save
</button>
```

---

## 6. Multi-line Attributes

When an element has many attributes, put each attribute on its own line for readability.

```javascript
// ✅ CORRECT - Each attribute on its own line
<button
  type="button"
  data-action="click->${this.identifier}#deleteEmployee"
  class="px-4 py-2 text-sm font-medium bg-red-50 text-red-600 hover:text-red-700 hover:bg-red-100 rounded-lg transition-colors cursor-pointer dark:bg-red-900/30 dark:text-red-400 dark:hover:bg-red-100"
>
  Delete
</button>

// ❌ WRONG - Single line with multiple attributes
<button type="button" data-action="click->${this.identifier}#deleteEmployee" class="...">Delete</button>
```

---

## Complete Example

```javascript
<button
  type="button"
  data-action="click->${this.identifier}#openNewModal"
  class="flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm whitespace-nowrap cursor-pointer dark:bg-blue-500 dark:hover:bg-blue-600 md:px-6 md:py-3"
>
  <span class="material-symbols-outlined text-[20px]">add</span>
  Add Employee
</button>
```

---

## Quick Reference

| Guideline | Rule |
|-----------|------|
| Tailwind | Use only default classes |
| Clickable | Always add `cursor-pointer` |
| Responsive | Mobile first, then `md:`/`lg:` |
| Theming | Always include `dark:` variant |
| Classes | Single line only |
| Attributes | Multi-line when many |

---

*End of documentation*