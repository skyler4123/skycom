# Skycom Storage (Folder + StoredFile)

> **Status**: Live v1. Company-scoped S3-like storage with metering-ready audit.
> Roots act as buckets; files live only inside folders. Direct Rails
> upload/download; no BYOS or credit deduction yet.

## 1. Models

| Model | File | Key columns |
|-------|------|-------------|
| `Folder` | `app/models/folder.rb` | `company_id`, `parent_id` self-join, `name` unique per `[company_id, parent_id]` |
| `StoredFile` | `app/models/stored_file.rb` | `company_id`, `folder_id` required, `attachable_type/id` polymorphic (Invoice, Purchase, ...), `file_size`, `extension`, `content_type`, `has_one_attached :file` |

- `Company` has `has_many :folders/:stored_files, dependent: :destroy`; resource
  names include `Folder`, `StoredFile` for ABAC assignment.
- `StoredFile#sync_file_metadata` (`before_save`) copies blob audit columns so
  billing can `SUM(file_size)` without touching blobs.
- `Folder#prevent_destroy_if_not_empty` (`before_destroy`) blocks delete when
  children or files exist — metering stays honest.

## 2. Constants

In `config/initializers/constants.rb`:

- `ACCEPTABLE_STORED_FILE_TYPES` — image, txt/csv, pdf, doc/docx, xls/xlsx, zip/rar MIME allowlist.
- `STORED_FILE_MAX_SIZES_BY_TYPE` — `{ image: 10MB, pdf: 20MB, office: 20MB, text: 5MB, archive: 50MB }`.

Validation maps MIME → category (`image/`, `application/pdf`, text, archive,
else office) and rejects over-limit with `errors` array.

## 3. Backend

Routes (`config/routes.rb` under `companies`):

- `resources :folders`
- `resources :stored_files { member get :download }`

Controllers (Shell-First, `errors` plural):

- `Companies::FoldersController` — index roots (plus `?parent_id=` children
  listing kept for API/deep-link use) + breadcrumbs, show subfolders + files,
  create/update/destroy JSON.
- `Companies::StoredFilesController` — index `?folder_id=`, create multipart
  `{ stored_file: { folder_id, name?, file, attachable_type/id? } }`,
  download redirects to `rails_blob_path`, destroy purges via
  `dependent: :purge_later`.
- Policies `Companies::FoldersPolicy`, `Companies::StoredFilesPolicy`
  (`record.can?`); owner bypasses via `all/all`.

## 4. Frontend

- Sidebar group `storage` + item `folders` (`sidebar_items.js`), labels in
  `dictionary.js`, paths in `url_helpers.js`, JSDoc in `types.js`.
- `Companies_Folders_IndexController` — roots grid (navigation only) + New Folder modal.
- `Companies_Folders_ShowController` — folder detail, breadcrumb, children/files
  browser, click-to-upload zone (clicking the zone or the Upload Files button
  opens the file picker; picked files upload immediately), and the single
  guarded Delete button (`confirm()`; success redirects to parent/roots,
  blocked delete toasts and stays).
- `Companies_StoredFiles_ShowController` — file metadata, Download link, and
  the single guarded Delete button (`confirm()`, redirects to parent folder).
- `Companies_Folders_NewModalController` — `form()` + `handleSubmit` →
  `reloadThenToast()` on success, `error.errors` toast on failure; parent
  preset via `window.pendingFolderParentId` (set by index/show before open).

## 5. Testing

- Models: `spec/models/folder_spec.rb`, `stored_file_spec.rb` — real
  `faker/files/*` uploads assert blob + `file_size` sync; failures assert
  no top-level files, cross-company folder, disallowed type, oversize via
  `STORED_FILE_MAX_SIZES_BY_TYPE`.
- Requests: `spec/requests/companies/folders_controller_spec.rb`,
  `stored_files_controller_spec.rb` — paired success + `errors`-key failures,
  download redirect, foreign-record 404s.
- Run: `bundle exec parallel_rspec -n 10 spec/models/folder_spec.rb spec/models/stored_file_spec.rb spec/requests/companies/folders_controller_spec.rb spec/requests/companies/stored_files_controller_spec.rb`

## 6. Non-goals (v1)

BYOS `CompanyStorage`, signed/indirect URLs, versioning, quotas, credit
deduction — audit columns exist so charging can sum later.

---

*See also: `docs/MODEL_CALLBACKS.md` (Folder/StoredFile), `docs/SIDEBAR.md`,
`docs/MODAL_PATTERN.md`, `docs/API_ERROR_FORMAT.md`.*
