# Abot Build Evidence

This is a compact record of the work that materially shaped the current demo. It is meant to support a live conversation with judges, not replace it.

## The Product Decision

We cut the broad "scholarship finder" idea down to one high-stakes workflow:

```text
student situation -> trusted opportunity -> blocker -> missing document -> usable request letter
```

The product does not reward a student for discovering more listings. It helps them avoid acting on an unverified listing and prepares the next document before the deadline.

## Codex Contributions

| Area | Concrete outcome | Where to inspect |
| --- | --- | --- |
| Product framing | Narrowed the product from a directory to an application-readiness loop with an explicit trust boundary. | `README.md`, `lib/abot_demo_web/live/abot_live.ex` |
| Scholarship state model | Represented verified, next-cycle, and unverified opportunities as distinct outcomes rather than hiding uncertainty. | `@opportunities` in `lib/abot_demo_web/live/abot_live.ex` |
| Interaction design | Built the four-step profile, plan, trust, and checklist journey, including readiness state changes and a real asynchronous OpenAI request-letter draft with an offline fallback. | `lib/abot_demo_web/live/abot_live.ex`, `lib/abot_demo/openai.ex` |
| Visual system | Created the editorial visual language, responsive layouts, rounded components, and a GSAP transition system that makes each student decision feel deliberate. | `assets/css/app.css`, `assets/js/app.js` |
| Debugging | Repaired the mobile navigation collapse, rebuilt ranked cards around a single visible action, and made letter copying use the real browser clipboard. | `assets/css/app.css`, `assets/js/app.js` |
| Honest prototype behavior | Removed the claim that a correction is already sent to a live queue; the demo now labels that boundary clearly. | `handle_event("report", ...)` in `lib/abot_demo_web/live/abot_live.ex` |
| Recovery from failure | Kept the letter workflow available during a missing key, API error, or network failure, and visibly labels the offline fallback instead of presenting it as a live result. | `AbotDemo.OpenAI`, `handle_info({:letter_drafted, ...})` |
| Verification | Compiled assets, ran the test suite, and exercised the profile -> plan -> trust -> checklist flow in desktop and mobile browser states. | `mix assets.build`, `mix test`, `mix precommit` |

## Why These Capabilities Fit

- Codex made it practical to move from a focused thesis to a working Phoenix LiveView experience within the build window.
- Visual and multimodal iteration exposed a mobile hierarchy failure that a build-only check would not catch.
- Browser testing kept the core interaction honest: a button labelled "Copy" now actually copies; a verification report no longer pretends to contact an external service.
- The OpenAI call is asynchronous, remains server-side, and has a visible fallback so a connectivity failure does not end the live walkthrough.
- GSAP is used to transition between meaningful product states, not as a decorative effect.

## Live Judge Walkthrough

1. Start on Ana's profile and state the actual job: "Tell me what I can trust and what I need to do before I lose the deadline."
2. Open **Next moves** and explain the difference between open, next-cycle, and unverified. Point out the listing Abot will not recommend.
3. Open **Prepare application** for CHED Merit. Show the fit, the blockers, source information, and the checklist.
4. Mark the Certificate of Indigency as missing, draft the request letter, show the live-result or offline-fallback label, edit a line, and copy it.
5. Show this file and the `/feedback` session ID. Explain one decision Codex changed materially: moving the OpenAI request into an asynchronous task and preserving the demo with an honest offline fallback.

## Before Submission

- Replace or supplement the sample student's story with three real, consented student observations. Do not invent interviews.
- Confirm every displayed scholarship date and requirement against its official source.
- Add the Codex `/feedback` session ID to the submission form.
- Keep this repository, setup steps, and the live demo URL available to judges.
