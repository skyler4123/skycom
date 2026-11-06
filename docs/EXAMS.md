# Skycom Exams (Question Bank & Assessments)

> **Status**: Web-only, company-scoped. Exams are built from a reusable question
> bank, assigned to employees, taken as timed attempts, and summarized by a
> background job. There is no mobile UI and no dynamic-property/TableConfig
> integration for these pages.

## 1. Overview

| Term | Meaning |
|---|---|
| **Exam** | A scored assessment definition (duration, pass mark, attempts, question selection). |
| **Question Bank** | The company pool of reusable questions. |
| **Question** | A single-choice, true/false, or text-answer prompt with points. |
| **Question Option** | A choice row for single-choice / true-false questions. |
| **Assignment** | An `assigned` employee exam row created by a manager. |
| **Attempt** | One employee try, from `in_progress` through `graded`/`expired`. |
| **Exam Summary** | Cached aggregate (pass rate, averages, per-question stats). |

`Exam` is the standard English term for a scored examination and is the model/UI
name. The employee-facing page is **My Exams**; the manager-facing pages are
**Exams** and **Question Bank**.

## 2. Data Model

```
Company 1─* Exam, Question
Category 1─* Question          (resource_name = "questions")
Question 1─* QuestionOption
Question 1─* ExamQuestionAppointment
Exam 1─* ExamQuestionAppointment
Exam 1─* EmployeeExamAppointment
Employee 1─* EmployeeExamAppointment
EmployeeExamAppointment 1─* EmployeeQuestionAppointment
Question 1─* EmployeeQuestionAppointment
Exam 1─1 ExamSummary
```

| Table | Purpose |
|---|---|
| `questions` | Company-scoped prompt, type, points, `correct_text` for text questions. |
| `question_options` | Ordered choices; exactly one correct for single-choice/true-false. |
| `exams` | Draft/published/archived definition with duration, pass mark, attempt limit, shuffle flag. |
| `exam_question_appointments` | Ordered exam↔question join. |
| `employee_exam_appointments` | Assignment/attempt header: timing, score, pass/fail, status. |
| `employee_question_appointments` | One answer plus an immutable question/option snapshot, option order, selected options, text answer, and points. |
| `exam_summaries` | One cached aggregate row per exam. |

The old generator scaffold (`ExamGroup`, `Answer`, tag appointments) was removed
completely; there is no backfill.

## 3. Question Types and Validation

| `question_type` | Options | Correct answer |
|---|---|---|
| `single_choice` | At least 2 | Exactly one `question_options.correct = true`. |
| `true_false` | Exactly 2 (`True`, `False`) | Exactly one correct. |
| `text` | None | Optional `correct_text` used as a model answer for manual grading. |

Question categories use the existing `Category` model with
`resource_name = "questions"`. New companies seed `General`, `Safety`,
`Compliance`, and `Customer Service` categories. `Question` and `Exam` do **not**
use `PropertyMappingConcern`, `DynamicSearchConcern`, or `TagConcern`.

## 4. Exam Status and Scoring

`Exam#workflow_status`: `draft` → `published` → `archived`.

- Draft exams are manager-only and cannot be assigned.
- Published exams can be assigned and started.
- Archived exams cannot be assigned or started; in-progress attempts can finish.

`Exam#publish!` raises `ActiveRecord::RecordInvalid` when the exam has no
questions. `published_at` is set on publish.

Scoring:

- Each answer row snapshots `points_possible` from the question at start.
- Objective answers award full points or zero.
- Text answers are graded manually with `0..points_possible` points; `correct`
  is true only at full points.
- `score = earned_points / total_points * 100`.
- `passed = score >= exam.passing_score`.
- Changing the pass mark does not retroactively change graded attempts.

## 5. Attempt Lifecycle

```
assigned ──start──► in_progress ──submit (no text)──► graded
                         │
                         ├──submit (text exists)──► submitted ──grade──► graded
                         └──deadline passes────────► expired
```

- At most one active attempt (`assigned` or `in_progress`) per employee/exam,
  enforced by a partial unique index and a model validation.
- `max_attempts` is an integer; `nil` means unlimited.
- Starting uses an existing `assigned` row when present; otherwise it creates
  the next attempt when attempts remain.
- Retakes are employee-initiated from My Exams after a `graded`/`expired`
  attempt, when attempts remain.
- `Exams::SubmitAttemptService::GRACE_PERIOD` (30 seconds) absorbs network
  latency; after it, the attempt is expired instead of accepted.
- `Exams::ExpireAttemptsJob` runs every 5 minutes and expires overdue attempts.

## 6. History Snapshots

At attempt start, every question and option is snapshotted into
`employee_question_appointments.question_snapshot`, and the displayed choice
order is stored in `option_order`. Later edits to the question bank never rewrite
history. `single_choice` choices may be shuffled per attempt; true/false is never
shuffled. A/B/C/D labels follow the displayed order and are not stored.

## 7. Background Summaries

`Exams::SummaryService` recomputes one `ExamSummary` row per exam:

- Counts are per employee, not per attempt. An employee who failed then passed
  counts once in `passed_count` and zero in `failed_count`; the best graded score
  is used for average/highest/lowest.
- `pending_review_count` counts attempts currently `submitted`.
- `expired_count` counts attempts currently `expired`.
- `question_stats` is computed from graded answers only.
- `Exams::SummaryJob` is enqueued after assignment/start/submit/grade/expiry and
  by the manual “Refresh Summary” button.
- `ExamSummary.computed_at` is shown on the exam page.

## 8. Authorization

| Surface | Rule |
|---|---|
| Exams CRUD, publish/archive/refresh, assignment | `can?(:read/:create/:update/:delete, Exam)` / `can?(:update, Exam)` |
| Question Bank CRUD | `can?(:read/:create/:update/:delete, Question)` |
| My Exams / attempt pages | Any signed-in employee; every lookup scoped through `current_employee` |

New companies grant Admin and Manager CRUD on `Exam` and `Question`; the owner
bypasses ABAC. Employee self-service policies return `true`; ownership scoping is
the security boundary. The take payload never includes correct flags or awarded
points; the result payload reveals them only after grading/expiry.

## 9. Endpoints

| Method | Path | Purpose |
|---|---|---|
| GET/POST | `/companies/:company_id/questions(.json)` | Question Bank list/create |
| GET/PATCH/DELETE | `/companies/:company_id/questions/:id(.json)` | Question detail/update/delete |
| GET/POST | `/companies/:company_id/exams(.json)` | Exam list/create |
| GET/PATCH/DELETE | `/companies/:company_id/exams/:id(.json)` | Exam detail/update/delete |
| POST | `/companies/:company_id/exams/:id/publish` | Publish |
| POST | `/companies/:company_id/exams/:id/archive` | Archive |
| POST | `/companies/:company_id/exams/:id/refresh_summary` | Enqueue summary refresh |
| GET/POST | `/companies/:company_id/exams/:exam_id/assignments(.json)` | Employee assignment list / bulk assign |
| GET | `/companies/:company_id/exams/:exam_id/appointments(.json)` | Manager attempt list |
| GET | `/companies/:company_id/exams/:exam_id/appointments/:id(.json)` | Manager attempt detail |
| PATCH | `/companies/:company_id/exams/:exam_id/appointments/:id/grade` | Save text grades |
| GET | `/companies/:company_id/my_exams(.json)` | Employee exam center |
| GET | `/companies/:company_id/my_exams/:id(.json)` | Employee exam detail |
| POST | `/companies/:company_id/my_exams/:id/start` | Start/retake an attempt |
| GET | `/companies/:company_id/my_exam_appointments/:id/take` | Full-screen timed attempt |
| PATCH | `/companies/:company_id/my_exam_appointments/:id/answer` | Autosave one answer |
| POST | `/companies/:company_id/my_exam_appointments/:id/submit` | Submit attempt |
| GET | `/companies/:company_id/my_exam_appointments/:id(.json)` | Result/review |

All failure responses use `{ errors: [...] }` with `:unprocessable_content`.

## 10. Frontend

| Surface | Stimulus controller |
|---|---|
| Question Bank list/detail/form | `Companies_Questions_IndexController` / `ShowController` / `NewController` / `EditController` |
| Exam list/detail/form | `Companies_Exams_IndexController` / `ShowController` / `NewController` / `EditController` |
| Question picker | `Companies_Exams_QuestionPickerController` |
| Assignment panel | `Companies_Exams_AssignmentPanelController` |
| Employee exam center | `Companies_MyExams_IndexController` / `ShowController` |
| Timed attempt | `Companies_MyExamAppointments_TakeController` |
| Result/review | `Companies_MyExamAppointments_ShowController` |
| Manager attempts/grading | `Companies_ExamAppointments_IndexController` / `ShowController` |

The timed attempt page is full-screen (standalone `Controller`, no sidebar). It
autosaves each answer after a short debounce, keeps the server `deadline_at`
across refreshes, auto-submits at zero, and flushes the full answer payload on
submit.

## 11. Sidebar

Group **Exams** contains:

- **Exams** → `/companies/:id/exams`
- **Question Bank** → `/companies/:id/questions`
- **My Exams** → `/companies/:id/my_exams`

Sidebar visibility is FE-only; the policies enforce authorization.

## 12. Testing

Priority: feature specs → model/service specs → request specs.

- Model: `spec/models/{question,question_option,exam,exam_question_appointment,employee_exam_appointment,employee_question_appointment,exam_summary}_spec.rb`
- Services/jobs: `spec/services/exams/*`, `spec/jobs/exams/*`
- Seed: `spec/services/seed/exam_seed_spec.rb`, `spec/services/seed/exam_sample_seed_spec.rb`
- Requests: `spec/requests/companies/{questions,exams,exam_assignments,exam_appointments,my_exams,my_exam_appointments}_controller_spec.rb`
- Features: `spec/features/companies/{questions,exams,my_exams,exam_appointments}`

Run `bundle exec parallel_rspec -n 14 [paths]`; feature specs also follow
`docs/FLAKY_TESTS.md` (never `sleep`).

## 13. Out of Scope / Follow-ups

- Multi-select questions (schema already supports `selected_option_ids` arrays).
- Question-order randomization (only choice order is randomized today).
- Manager-forced retake grants (employees retake from My Exams; managers can
  raise `max_attempts`).
- Notifications for assignment/publish.
- Mobile exam pages.
- Recomputing already graded attempts when `passing_score` changes.
- Assignment status filtering (the panel filters by search/department/group/branch
  and displays status badges).
