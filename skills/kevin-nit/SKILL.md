---
name: kevin-nit
description: Post-implementation nit pass. Use after finishing implementing code, before presenting it.
---

# Kevin Nits

Post-implementation pass. Re-read the diff you just produced and ask, for every
line, three questions. Fix everything that fails.

## 1. Could a stranger read this cold?

No access to the ticket, the Slack thread, or the author. If understanding a
name or a line requires outside context, the context has to move into the code
as structure, or into the PR body, or die.

- Task IDs, dates, audit refs in names or comments (`isK34TargetName`,
  `TA-6610`, `8/13 監査済み`) → name by behavior (`isPlaceholderName`), ticket
  context goes in the PR description or commit message.
- Impact numbers (rows affected, 対処数) → PR body, never code.

## 2. Is this comment compensating for the code?

A comment that explains *what* code does means the code failed. Fix the code,
then the comment is dead weight, delete it.

The default verdict is delete. Almost every comment in an AI-written diff is
restating code that should have been named better. A comment has to earn its
place; it does not get to stay just because it is true.

- Comment restating a function or a `select` → the fix is a better name.
- Per-line comments in a regex or array → the taxonomy is missing. Extract
  named lists grouped by meaning, build the pattern with `join('|')`. The
  names ARE the comments.
- The only comment that survives is one recording a decision the code cannot
  express: "総括 can't go in SENIOR_ROLE_WORDS, exempting bare 総括 leaks 28
  rows". That one stops a future 'simplification' from becoming a bug. Keep
  those, and put them above the constant they protect, never inline.

## 3. Does this line earn its place in the diff?

Every line costs review time. Anything that isn't the task is a cost.

- One-op wrapper called from one place → inline it. Indirection must pay rent.
  This includes helpers invented to hide `new RegExp`.
- Tests nobody asked for, in a repo with no test harness → delete. Fine-grained
  generated tests bloat the diff without buying confidence.
- Two lists sharing members (`TITLE_KEYWORDS_JA` and
  `TITLE_KEYWORDS_JA_EXTENDED`) → base + `_EXTENSIONS`, merge to build the
  full set. Duplicated members drift.
- Generated data files (name lists, thousand-line CSVs) → object storage (S3),
  not the repo.

## Worked example

Bad:

```ts
const PENDING_ADJUDICATION_PATTERNS: RegExp[] = [
  /本店.*店長|店長.*本店/, // 本店＋店長（拠点長か小売店長か不明）
  // 総括＋店長は「統括店長」の表記揺れの可能性があり灰色（8/13 監査済み名簿と同口径）。
  // 総括を SENIOR_ROLE_WORDS に入れる案は不可 — 総括主任/総括班長/総括係長 は監査で
  // 削除確定しており、裸の 総括 で豁免すると 28 行が漏れる（8/24 スナップショット照合で実測）。
  /総括.*店長|店長.*総括/,
  /(主任技術者|主任者|主任技師|主任医長|主任研究員)/, // 専門職・資格名の主任
  /主任.*(看護|介護|保育|診療)|(看護|介護|保育|診療).*主任/, // 医療・介護系の主任
]
```

A human cannot review this. There is a comment INSIDE the array compensating
for structure that isn't there (question 2). The comments cite audit dates and
snapshot dates that mean nothing without the Slack thread (question 1).

Good:

```ts
// 総括 を SENIOR_ROLE_WORDS に入れる案は不可: 総括主任/総括班長 は監査で削除確定
// しており、裸の 総括 で豁免すると 28 行が漏れる。
const SITE_HEAD_SUSPECT_STORE_MANAGER_QUALIFIERS = ['本店', '総括']

const LICENSED_PROFESSION_CHIEF_TITLES = ['主任技術者', '主任者', '主任技師', '主任医長', '主任研究員']

const MEDICAL_CARE_CHIEF_CONTEXTS = ['看護', '介護', '保育', '診療']

const siteHeadSuspect = SITE_HEAD_SUSPECT_STORE_MANAGER_QUALIFIERS.join('|')
const medicalCare = MEDICAL_CARE_CHIEF_CONTEXTS.join('|')

const PENDING_ADJUDICATION_PATTERNS: RegExp[] = [
  new RegExp(`店長.*(${siteHeadSuspect})|(${siteHeadSuspect}).*店長`),
  new RegExp(LICENSED_PROFESSION_CHIEF_TITLES.join('|')),
  new RegExp(`主任.*(${medicalCare})|(${medicalCare}).*主任`),
]
```

Every group has a name, so no per-line comments (question 2). The one comment
that survives records a measured decision, stripped of dates (questions 1 and
2). Adding a title means appending to a list, not editing a regex. And no
helper was invented to hide `new RegExp`: that would just add indirection
(question 3).

## Adding new nits

When a new nit shows up in review, first check if it is an instance of one of
the three questions. If yes, add it as a one-line example under that question.
Only if it genuinely isn't does it become question 4. This file stays a
generator, not a checklist.
