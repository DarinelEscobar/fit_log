# FitLog UI polish review

## Direction and workspace

Evolve the accepted Kinetic Noir identity for a compact native training app.
Keep Flutter, Riverpod, navigation, persistence and existing product behavior.
Use the existing Space Grotesk/Manrope fonts, Material rounded icons, charcoal
surfaces and violet accent defined in `lib/src/theme/kinetic_noir.dart`.
No new animation, font or icon dependency is needed: use Flutter's native
animation primitives and the existing theme. Shapes remain 16dp for controls,
20-24dp for larger surfaces, and pills only for compact status/selection.

Worktree: `<local path omitted>`

Branch: `feat/fitlog-ui-redesign`, review baseline `2bcae53`.
Protected checkout: `<local path omitted>`.
The worktree was clean before this setup. Commit setup before delegation.
Preserve ignored signing files, build outputs and fictional QA fixtures.

## Information hierarchy

- Active workout: exercise name, tempo and prescribed reps are immediately
  visible in the pinned header. Label reps explicitly rather than `TARGET`.
  Show current/planned set count nearby, with RIR still readable. Tempo must
  remain legible without opening Plan Details, scrolling back or dismissing
  the keyboard. Long names and large text must wrap adaptively.
- Keep only the active set expanded. Completed and upcoming sets remain compact.
  Logging advances to the next set without losing its fields or hiding the
  exercise context. Editing a logged set must not restart rest or move the
  next-set focus. Show rest only when rest is actually running.
- Finish: aim for the summary, required energy/mood controls and Save & Finish
  to fit at 375x667 with normal text and keyboard closed. Use one compact
  summary band, a bounded energy selector retaining all 1-10 values, mood
  retaining all 1-5 values, and progressively disclosed optional notes/details.
  With large text, landscape or keyboard, allow natural scrolling and a
  reachable footer instead of shrinking targets or clipping content. Preserve
  save/resume/discard and the existing required-field and draft contracts.
- History: make date, routine and recorded outcome easy to scan; retain all
  calendar/list/detail and filtering behavior. Improve hierarchy and density.
- Performance: prioritize the selected exercise/period, a clear leading
  metric and readable chart units. Keep existing calculations and honest
  empty/loading/error states; do not manufacture comparisons or data.

## Motion identity

Use the shared `KineticMotion` tokens, honoring `disableAnimations` throughout.

| Action | Timing | Purpose |
| --- | --- | --- |
| Press feedback | 120ms | Acknowledge a tap without shifting layout bounds |
| First screen/section entrance | 220ms | Establish hierarchy with a small 8-12dp translation and fade |
| Content replacement | 180ms | Explain a selected exercise, set, period or filter change |
| Forward route transition | 260ms | Preserve spatial continuity and predictable back navigation |
| Dismissal/exit | 170ms | Restore the previous context promptly |

Enter with easeOutCubic, exit with easeInCubic, state changes with
easeInOutCubic. At most one or two entrance groups per view; only initially
visible content is staggered (30-40ms, bounded total delay). All data is
immediately accessible and input stays enabled. Do not replay entrances on
the workout's one-second timer, list rebuilds or keyboard changes. Animate
opacity/translation and isolate small state transitions; avoid page-wide
size animation, perpetual effects, new DB reads or per-frame state updates.
Controllers/listeners must be disposed and hidden tabs must not keep animating.
Retain native predictive-back/gesture behavior when improving transitions.

Apply a coherent motion pass to Home, routine browsing/details, warm-up,
active training, Finish, History, Performance and existing modal transitions.
Keep useful current layouts unless the review above requests recomposition.

## Implementation and verification

Use UI/UX Pro Max's Flutter, touch, motion, accessibility and chart guidance.
The taste skill excludes native mobile; do not import its React stack,
marketing-page layouts or photographic requirements into this product.
Antigravity owns implementation and corrections in the existing FitLog chat.
Use one writer so shared theme/navigation and screen changes remain coherent.
Codex performs scoped review and serial local commits after writers finish.
No push, merge, production changes or unrelated edits.

Use the existing focused widget tests for execution summary and Finish flows;
add meaningful coverage for required metrics, compact layout, keyboard/large
text, reduced motion and entrance stability if the changed behavior needs it.
Run relevant Flutter analyze and focused tests; run combined checks once all
edits are stable. Compare real rendered views on an isolated FitLog emulator
at small-phone portrait and landscape, large text and reduced motion. The
currently running `emulator-5556` belongs to other work: do not use it.
Use fictional QA data only via `lib/main_demo.dart`; ship `lib/main.dart`.

For delivery, bump to `1.1.2+4`, build a normal signed release with the ignored
existing keystore, and verify package `com.yourcompany.fit_log` and certificate
SHA-256 `6296a3ef924ced13c2344d843aa783111a29b61b2fc7a1e07a1fe9045f993490`.
Never expose signing secrets or include demo data in the delivery build.
Report actual checks, reviewed screenshots and any device/performance limits.
