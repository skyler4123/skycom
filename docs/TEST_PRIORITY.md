# Skycom Test Priority

> **⚠️ MANDATORY**: Coding agents must follow this priority order when writing and
> verifying test cases. A passing lower-priority spec never excuses a failing
> higher-priority spec.

---

## 1. Priority Order (most → least important)

1. **Feature (system) tests** — `spec/features/**`, `spec/system/**`. These exercise the real end-to-end flow (browser + Rails + DB) the user actually experiences.
2. **Model tests** — `spec/models/**`. These protect invariants, validations, and business logic at the data layer.
3. **Request specs** — `spec/requests/**` (and job/service specs where applicable). These cover controller/service edge cases not reachable from a feature test.

## 2. The Core Rule

**A passing request spec does NOT count as proof of correctness.**

It is nonsense (and not acceptable) for a request spec to pass while the corresponding feature test fails. Feature tests are the source of truth for "does this actually work for the user." If the feature test fails, the work is not done — fix the code (and/or the test, if the test is wrong) until the feature test passes, regardless of how green the request/model specs are.

## 3. What this means when writing tests

- When adding or changing behavior, write or update the **feature test first (or alongside)** the implementation. Model tests come second. Request specs only for edge cases not coverable by a feature test.
- **Never declare a task complete based on request/model specs alone** when a feature test exists or is reasonably expected for that behavior.
- Do not weaken, skip, or delete a feature test to make the suite green. If a feature test is genuinely obsolete, remove it deliberately and note why — but never as a shortcut to green.
- When a request spec and a feature spec disagree about expected behavior, the **feature spec wins**; reconcile the request spec to match, not the other way around.
- Paired success + failure cases (see `AGENTS.md` Testing) apply at every level, but the feature-level pair is the one that must be green to ship.

## 4. Verification order

When running tests to verify work, run in priority order and stop on the first failure:

1. Feature tests for the touched area.
2. Model tests for the touched models.
3. Request/service/job specs for the touched code.

A green lower tier never overrides a red higher tier.

---

*See also: `docs/PARALLEL_TESTS.md` (how to run), `docs/FLAKY_TESTS.md` (feature-test flake patterns).*
