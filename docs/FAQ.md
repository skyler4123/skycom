# System FAQ

> **Status:** Live. Signed-in, web-only, page-scoped content.
> **Page:** System → FAQ at `/companies/:company_id/faq`.
> **Audience:** every employee with a company record.

## 1. What it is

A searchable, bilingual answer book for how Skycom behaves: definitions, rules,
procedures, and honest current limits. It does not replace the Help Center. The
FAQ explains the product; Help Center tickets reach Skycom support.

## 2. Files

| File | Responsibility |
|---|---|
| `app/controllers/companies/faqs_controller.rb` | Renders the HTML shell; no data, writes, or credit deduction |
| `app/policies/companies/faqs_policy.rb` | Allows any employee to read the page |
| `app/javascript/controllers/companies/faqs/show_controller.js` | Layout, search, group filter, details, deep links, copy link |
| `app/javascript/controllers/companies/faqs/content/index.js` | Imports the 20 groups; exports `FAQ_GROUPS` and `FAQ_DICTIONARY` |
| `app/javascript/controllers/companies/faqs/content/dictionary.js` | Builds the page-scoped `{ english: { vi } }` map |
| `app/javascript/controllers/companies/faqs/content/NN_*.js` | One file per group, English + Vietnamese |
| `app/javascript/controllers/helpers/dictionary.js` | UI chrome strings + `registerDictionary()` |
| `docs/TODO.md` | `FAQ — deferred answers` maps every planned/manual answer to work |

Route: `resource :faq, only: :show, controller: :faqs` → `company_faq_path(company_id)`.

## 3. Content shape

```js
{
  key: "inventory_stock",
  icon: "warehouse",
  title: { en: "Inventory & stock", vi: "Tồn kho & kho" },
  questions: [
    {
      slug: "receive-stock",              // stable, ASCII, language-independent
      status: "available",               // available | planned | manual
      question: { en: "...", vi: "..." },
      answer: [
        { type: "p", text: { en: "...", vi: "..." } },
        { type: "steps", items: [{ en: "...", vi: "..." }] },
        { type: "list", items: [{ en: "...", vi: "..." }] },
        { type: "note", text: { en: "...", vi: "..." } },
        { type: "links", items: [
          { label: { en: "Open Inventory", vi: "Mở Tồn kho" }, path: "company_stocks_path" }
        ] }
      ]
    }
  ]
}
```

Rules:

- `slug` must be unique across all groups; it is the deep-link id.
- Every `en` must have a matching `vi`. The page falls back to English if a
  translation is missing, but a missing `vi` is a bug.
- `status: "planned"` renders **Not available yet**; `status: "manual"` renders
  **Manual step**. Both must have an entry in `docs/TODO.md`.
- Link `path` is a `Helpers` route-helper name; the renderer passes the company id.
  Use module pages, not console URLs that need an operation id.
- Answer depth: 3–6 sentences, plus steps only when the user must click through a
  procedure. Explain the consequence, not just the button.

## 4. Adding a question

1. Pick the group file and add the question object. Keep the approved group order.
2. Write the English and Vietnamese strings and choose the status.
3. If the answer needs a page link, use an existing `Helpers.*_path` helper.
4. Add the question to `docs/TODO.md` if the status is `planned` or `manual`.
5. Add or update a feature assertion in
   `spec/features/companies/faqs/show_spec.rb` for a distinctive phrase.
6. Run:

```bash
bundle exec parallel_rspec -n 14 spec/features/companies/faqs/show_spec.rb
bin/rubocop
bin/check_colors --strict
bin/brakeman --no-pager
```

## 5. Why the content is page-scoped

`app/javascript/controllers/helpers/dictionary.js` is loaded by `application.js` on
every page, and `translate()` rebuilds the dictionary object on each call. Adding
~170 bilingual answers there would make every page download the FAQ corpus.

Instead:

1. The FAQ controller dynamically imports `content/index.js` when the page connects.
2. It builds `FAQ_DICTIONARY` from the same `{ en, vi }` objects.
3. It calls `registerDictionary(FAQ_DICTIONARY)`.
4. The renderer calls `translate()` for every question, answer block, step, note, and
   link label, so the normal translation contract still applies.

Only UI chrome (search, buttons, badges, footer) lives in the global dictionary.
This exception is documented in `docs/LANGUAGE.md` §6.

## 6. Search, filters, and deep links

- Search normalizes both the query and the content (NFD, diacritics removed,
  lowercase), so `hoa don` matches `hóa đơn` and English search works while the UI
  is Vietnamese.
- Group chips filter to one group; search and group filter combine.
- Deep link format: `#faq-<slug>`; opening it clears the search, restores all groups,
  opens the question, and scrolls to it.
- Copy link uses the current origin and path plus the slug.

## 7. Backlog policy

The FAQ must not promise a feature that does not exist. When a question's honest
answer is "not yet", use `status: "planned"` (or `"manual"` for a real feature with a
manual follow-up) and add the item to `docs/TODO.md`. When the feature ships, update
the answer, remove the badge, and tick or remove the TODO entry.

## 8. Out of scope

- Public/unauthenticated FAQ and SEO.
- Markdown or rich-text authoring; the structured blocks are deliberate.
- Admin content editor and database-backed FAQs.
- "Was this helpful?" voting.
- Android shell entry (web page is responsive; mobile parity is a follow-up).
