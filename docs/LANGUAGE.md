# Skycom Language/Translate System

## 1. Overview

Skycom has **two separate localization layers**:

1. **Public homepage (SEO): server-side Rails `I18n`.** The URL is the source
   of truth: `/` is English (`en`), `/vi` is Vietnamese (`vi`). Every crawled
   string, meta tag, and JSON-LD value is rendered in the server response from
   `config/locales/home.en.yml` / `home.vi.yml`. Do **not** use the client-side
   `translate()` helper for homepage copy.
2. **Signed-in app UI: client-side dictionary.** The language preference is
   stored in `localStorage` under `languageCode` and read by `translate()`.
   The homepage language switcher writes this key on explicit click so the app
   UI follows the chosen locale, but it never redirects automatically.

| Property | Value |
|----------|-------|
| Homepage locales | `en` at `/`, `vi` at `/vi` (`PUBLISHED_LOCALES`) |
| Homepage translation files | `config/locales/home.en.yml`, `config/locales/home.vi.yml` |
| App storage key | `languageCode` |
| App default language | `en` (English) |
| App storage location | `localStorage` |
| Homepage switcher | Real `<a>` links with `hreflang`/`lang`; no auto-redirect |

---

## 2. Architecture

### 2.1 App UI (client-side)

The app-UI translation system consists of three main components:

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

### 2.2 Homepage (server-side, SEO)

The homepage never uses that client-side flow for crawled copy. `HomeController`
resolves `en` or `vi` from the URL, wraps the action in `I18n.with_locale`, and
the ERB renders `t("home.*")` from `config/locales/home.<locale>.yml`. The
language switcher is a plain anchor; `home/language_controller.js` only mirrors
the click into `localStorage.languageCode` for the signed-in app UI.

---

## 3. Supported Languages

| Code | Language | Homepage | App UI |
|------|----------|----------|--------|
| `en` | English | `/` | `languageCode=en` |
| `vi` | Tiếng Việt | `/vi` | `languageCode=vi` |

The homepage allowlist is `PUBLISHED_LOCALES` in
`config/initializers/constants.rb`. Only published locales get routes, switcher
links, hreflang, sitemap entries, and indexing.

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

> **Applies to JS-rendered app UI.**
>
> **When adding any new text/string to app UI, you MUST use `translate()` first.**
>
> **If the translated word doesn't exist in dictionary.js yet, you MUST add/update it to dictionary.js.**
>
> **Homepage exception:** server-rendered marketing copy uses
> `t("home.*")` from `config/locales/home.<locale>.yml`; do not put it in
> `dictionary.js`.
>
> **Page-scoped editorial content exception:** long-form content that would bloat
> every page (the System FAQ's ~170 bilingual answers) lives in a page-scoped
> content module with `{ en, vi }` pairs. The page dynamically imports that module
> and calls `registerDictionary()` before rendering, so `translate()` still
> resolves every string. UI chrome (search, buttons, badges) stays in
> `dictionary.js`. See `docs/FAQ.md` §5. This exception is only for content
> corpora, not for ordinary labels or controls.

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

**Rule of thumb**: If a word looks awkward or unrecognizable when translated, leave it in English. The `translate()` fallback guarantees English display when no translation exists, so it's always safe to start without a dictionary entry **for app UI**. This does not apply to the homepage: `home.*` must be complete for every published locale.

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

The project currently supports English and Vietnamese. A new locale is a
deliberate two-layer change:

1. **Homepage (SEO):** add the locale to `PUBLISHED_LOCALES`, add
   `config/locales/home.<locale>.yml` with every `home.*` key, extend
   `OG_LOCALES` in `config/initializers/constants.rb`, add the route constraint, and update
   hreflang/sitemap/switcher tests. The locale must be complete; production
   fallbacks are disabled.
2. **App UI:** add the option to the language switcher in
   `app/javascript/controllers/companies/layout_controller.js` and add
   translations to `dictionary.js` for every key:
   ```javascript
   "Save": {
     vi: "Lưu",
     ja: "保存",
   },
   ```

Do not mix the two layers: homepage copy belongs in the Rails locale files,
app UI copy belongs in `dictionary.js`.

---

## 10. File Reference

| File | Description |
|------|-----------|
| `config/locales/home.en.yml` / `home.vi.yml` | Server-rendered homepage copy |
| `app/helpers/home_helper.rb` | Homepage canonical/hreflang/OG/JSON-LD helpers |
| `app/views/home/index.html.erb` | Homepage using `home.*` Rails i18n keys |
| `app/views/home/sitemap.xml.erb` / `robots.text.erb` | Localized sitemap and robots |
| `app/javascript/controllers/home/language_controller.js` | Syncs homepage switcher → `languageCode` |
| `app/javascript/controllers/helpers/dictionary.js` | App UI translation dictionary |
| `app/javascript/controllers/helpers/ui_helpers.js` | translate() function (line 272) |
| `app/javascript/controllers/language_controller.js` | App UI language switch controller |
| `app/javascript/application.js` | window.translate exposure |
| `app/javascript/controllers/companies/layout_controller.js` | App UI language dropdown |

---

## 11. Best Practices

1. **App UI: always use translate()** - Never hardcode display strings.
2. **Homepage: always use Rails `t("home.*")`** - It must be in the server HTML for SEO; client-side `translate()` is too late.
3. **Keep app dictionary keys in English** - The key is the English source of truth.
4. **Update translations in the same PR** - App UI in `dictionary.js`; homepage in `home.<locale>.yml`.
5. **Homepage fallback is disabled** - Missing `home.*` keys fail tests; do not rely on English fallback on `/vi`.

---

*End of documentation*
