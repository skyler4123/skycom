# Skycom Language/Translate System

## 1. Overview

Skycom implements a client-side multi-language system that supports 2 languages. The language preference is stored in the browser's `localStorage` under the key `languageCode`, which persists across sessions.

| Property | Value |
|----------|-------|
| Storage Key | `languageCode` |
| Default Language | `en` (English) |
| Storage Location | `localStorage` |

---

## 2. Architecture

The translation system consists of three main components:

| Component | File | Responsibility |
|-----------|------|-------------|
| **Dictionary** | `app/javascript/controllers/helpers/dictionary.js` | Stores all translation keys and localized strings |
| **translate()** | `app/javascript/controllers/helpers/ui_helpers.js:272` | Looks up translations based on current language |
| **LanguageController** | `app/javascript/controllers/language_controller.js` | Handles language switching via UI |

### Flow

```
User clicks language button
       ↓
LanguageController saves new code to localStorage
       ↓
Page reloads (hard reload)
       ↓
translate() reads localStorage.getItem("languageCode")
       ↓
Returns translated string from dictionary.js
```

---

## 3. Supported Languages

| Code | Language |
|------|----------|
| `en` | English |
| `vi` | Tiếng Việt |

---

## 4. Dictionary Structure

The dictionary is a JavaScript object where:
- **Keys** are the English strings (used as the master key and fallback value)
- **Values** are objects containing only Vietnamese translations (`vi`)

```javascript
// app/javascript/controllers/helpers/dictionary.js
export const dictionary = () => {
  return {
    "Dashboard": {
      vi: "Bảng điều khiển",
    },
    "New Company": {
      vi: "Công Ty Mới",
    },
    "Create Company": {
      vi: "Tạo Công Ty",
    },
    "Billing": {
      vi: "Thanh Toán",
    },
    "Cancel": {
      vi: "Hủy",
    }
  }
}
```

---

## 5. How translate() Works

```javascript
// app/javascript/controllers/helpers/ui_helpers.js
export const translate = (key) => {
  // Get current lang from local storage, default to 'en'
  const lang = localStorage.getItem("languageCode") || "en";
  
  // Return translation if found, otherwise return the key itself (fallback)
  return dictionary()[key]?.[lang] || key;
};
```

### Behavior

| Scenario | Return Value |
|----------|-----------|
| Key exists in dictionary for `vi` and language is Vietnamese | Vietnamese translation |
| Key missing in dictionary or language is English | Returns the English key itself (no translation object needed) |

---

## 6. Usage Guidelines (MANDATORY)

> **When adding any new text/string to UI, you MUST use `translate()` first.**
>
> **If the translated word doesn't exist in dictionary.js yet, you MUST add/update it to dictionary.js.**

### Pattern Examples

```javascript
// ✅ CORRECT - Using translate()
${translate("Dashboard")}
${tooltip(translate("Click to edit"))}
<p class="text-sm">${translate("Save")}</p>

// ❌ WRONG - Using raw strings directly
${"Dashboard"}
${"Click to edit"}
<p>Save</p>
```

### Workflow for New Strings

1. Use `translate("Your New String")` in your template
2. Run the app - it will display "Your New String" (fallback to key)
3. Add the translation to `dictionary.js`:
   ```javascript
   "Your New String": {
     vi: "Chuỗi mới của bạn",
   },
   ```

### Adding Words Without Translations (IMPORTANT)

If you need to add a word/phrase that **doesn't exist in dictionary.js yet**, follow this rule:

> **The key is the English value** (source of truth). Only add a `vi` entry with the Vietnamese translation.

**Example - Adding "System Design":**
```javascript
"System Design": {
  vi: "Thiết Kế Hệ Thống",
},
```

**Example - Adding "Employee Management":**
```javascript
"Employee Management": {
  vi: "Quản Lý Nhân Viên",
},
```

This ensures the fallback works correctly: when Vietnamese translation is missing, users will see the English key instead of a blank or broken display.

---

## 7. Translation Policy

Skycom supports multi-language, so every new "word" added to the UI should use `translate()`. This ensures the platform is accessible to Vietnamese-speaking users.

However, this is a practical rule, not an absolute one. Some words are globally understood and translating them can make the interface more confusing than helpful:

| Skip Translation | Reason |
|-----------------|--------|
| `username`, `password` | Universal tech terms — users expect them in English |
| `admin`, `administrator` | Role names universally recognized |
| `email`, `login`, `logout` | Standard UI vocabulary |
| Brand names, product codes | Proper nouns — no translation needed |
| Placeholder code examples | Technical examples (JSON, URLs) — translating would confuse |

**Rule of thumb**: If a word looks awkward or unrecognizable when translated, leave it in English. The `translate()` fallback guarantees English display when no translation exists, so it's always safe to start without a dictionary entry.

**Do NOT skip `translate()` for**: labels, section headings, button text, navigation items, error messages, status labels, empty-state messages, or tooltip text. These should always have a Vietnamese entry in `dictionary.js`.

---

## 8. How to Switch Language

### Via Code

```javascript
localStorage.setItem("languageCode", "vi");  // Set to Vietnamese
window.location.reload();                    // Required to apply
```

### From UI (Header)

The language switcher is in the header (see `layout_controller.js`). Click triggers `data-language-code-param` → `LanguageController#changeLanguage` → saves to localStorage → reloads.

---

## 9. Adding a New Language

The project currently supports only English and Vietnamese. To add a new language (e.g., `ja` for Japanese):

1. **Add the option to the language switcher** in `app/javascript/controllers/companies/layout_controller.js`
2. **Add translations to `dictionary.js`** for every key:
   ```javascript
   "Save": {
     vi: "Lưu",
     ja: "保存",
   },
   ```

---

## 10. File Reference

| File | Description |
|------|-----------|
| `app/javascript/controllers/helpers/dictionary.js` | Translation dictionary |
| `app/javascript/controllers/helpers/ui_helpers.js` | translate() function (line 272) |
| `app/javascript/controllers/language_controller.js` | Language switch controller |
| `app/javascript/application.js` | window.translate exposure |
| `app/javascript/controllers/companies/layout_controller.js` | Language dropdown UI |

---

## 11. Best Practices

1. **Always use translate()** - Never hardcode display strings
2. **Keep keys in English** - The key should be the English version (source of truth)
3. **Update dictionary first** - When adding new features, add translations in the same PR
4. **Use consistent casing** - Keys should match exactly (case-sensitive)
5. **Fallback is not perfect** - Missing translations show English keys; add them to dictionary.js

---

*End of documentation*
