# Skycom Language/Translate System

## 1. Overview

Skycom implements a client-side multi-language system that supports 5 languages. The language preference is stored in the browser's `localStorage` under the key `languageCode`, which persists across sessions.

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
| **translate()** | `app/javascript/controllers/helpers/ui_helpers.js:324` | Looks up translations based on current language |
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

| Code | Language | Direction |
|------|----------|----------|
| `en` | English | LTR |
| `es` | Español (Spanish) | LTR |
| `fr` | Français (French) | LTR |
| `de` | Deutsch (German) | LTR |
| `vi` | Tiếng Việt (Vietnamese) | LTR |

---

## 4. Dictionary Structure

The dictionary is a JavaScript object where:
- **Keys** are the English strings (used as the master key)
- **Values** are objects containing translations for each language code

```javascript
// app/javascript/controllers/helpers/dictionary.js
export const dictionary = () => {
  return {
    // Key (English) → Translations
    "Dashboard": {
      en: "Dashboard",
      es: "Tablero",
      fr: "Tableau de bord",
      de: "Instrumententafel",
      vi: "Bảng điều khiển",
    },
    "Save": {
      en: "Save",
      es: "Guardar",
      fr: "Enregistrer",
      de: "Speichern",
      vi: "Lưu",
    },
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
| Key exists in dictionary for current language | Translated string |
| Key missing for current language | Falls back to English (`en`) |
| Key missing entirely | Returns the key itself (no translation) |

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
     en: "Your New String",
     es: "Tu nueva cadena",
     fr: "Votre nouvelle chaîne",
     de: "Ihre neue Zeichenkette",
     vi: "Chuỗi mới của bạn",
   },
   ```

### Adding Words Without Translations (IMPORTANT)

If you need to add a word/phrase that **doesn't exist in dictionary.js yet**, follow this rule:

> **English (`en`) value = the key itself** (source of truth). Only translate to other languages.

**Example - Adding "System Design":**
```javascript
"System Design": {
  en: "System Design",     // ← Same as key
  es: "Diseño del sistema",
  fr: "Conception du système",
  de: "Systemdesign",
  vi: "Thiết Kế Hệ Thống",
},
```

**Example - Adding "Employee Management":**
```javascript
"Employee Management": {
  en: "Employee Management",
  es: "Gestión de empleados",
  fr: "Gestion des employés",
  de: "Mitarbeiterverwaltung",
  vi: "Quản Lý Nhân Viên",
},
```

This ensures the fallback works correctly: when a translation is missing for a language, users will see the English text instead of a blank or broken display.

---

## 7. How to Switch Language

### From UI (Header)

The language switcher is in the header (see `layout_controller.js:324-356`):

```javascript
<button ... ${popover({ ... })}>
  <span>${(localStorage.getItem("languageCode") || "en").toUpperCase()}</span>
</button>
```

Click triggers `data-language-code-param` → `LanguageController#changeLanguage` → saves to localStorage → reloads.

### Via Code

```javascript
localStorage.setItem("languageCode", "vi");  // Set to Vietnamese
window.location.reload();                    // Required to apply
```

---

## 8. Adding a New Language

To add a new language (e.g., `ja` for Japanese):

1. **Add the option to the language switcher** in `layout_controller.js`:

```javascript
const languageNames = {
  en: "English",
  es: "Español",
  fr: "Français",
  de: "Deutsch",
  vi: "Tiếng Việt",
  ja: "日本語"  // ← ADD HERE
};
```

2. **Add to dictionary.js** for every key:

```javascript
"Save": {
  en: "Save",
  es: "Guardar",
  fr: "Enregistrer",
  de: "Speichern",
  vi: "Lưu",
  ja: "保存",  // ← ADD HERE
},
```

3. **Add to import map** if loading dynamically (optional for client-side only).

---

## 9. File Reference

| File | Lines | Description |
|------|-------|-----------|
| `app/javascript/controllers/helpers/dictionary.js` | 1-326 | Translation dictionary |
| `app/javascript/controllers/helpers/ui_helpers.js` | 324-330 | translate() function |
| `app/javascript/controllers/language_controller.js` | 1-31 | Language switch controller |
| `app/javascript/application.js` | 19, 53 | window.translate exposure |
| `app/javascript/controllers/companies/layout_controller.js` | 324-356 | Language dropdown UI |

---

## 10. Best Practices

1. **Always use translate()** - Never hardcode display strings
2. **Keep keys in English** - The key should be the English version (source of truth)
3. **Update dictionary first** - When adding new features, add translations in the same PR
4. **Use consistent casing** - Keys should match exactly (case-sensitive)
5. **Test all languages** - Verify UI looks correct in each supported language
6. **Fallback is not perfect** - Missing translations show English keys; add them to dictionary.js

---

*End of documentation*