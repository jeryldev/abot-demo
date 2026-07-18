# Abot Judge Scorecard

## The target

Abot is aiming at a narrow, defensible job:

```text
Help a Filipino Grade 12 student turn a fragmented scholarship lead into one trusted next action before a document deadline closes.
```

The product is not a scholarship directory and does not promise an award decision. Its differentiator is the trust boundary: it separates an official, actionable path from a next-cycle path and a listing it cannot verify.

## What a 10 Requires

| Criterion | What the judge should see | Proof we can show live |
| --- | --- | --- |
| Codex Craft | Codex materially changed product scope, implementation, recovery behavior, visual quality, and test coverage. | `docs/BUILD_EVIDENCE.md`, this repository, the working app, responsive screenshots, and the Codex `/feedback` session ID. |
| Product Judgment | One complete loop, not a list of unrelated AI features: profile -> ranked trusted move -> blocker -> missing document -> usable letter. | Run this exact path in the app. Do not spend demo time on secondary concepts. |
| Problem & Insight | A named student audience whose real failure is late, fragmented, unverified information, not an inability to search. | Three short, consented student observations or interviews. Show the recurring pattern; do not invent quotes or statistics. |

## OpenAI Capability Choices

### Used now, because it directly supports the core job

1. **Codex with GPT-5.6** built and iterated the product. The evidence is visible in the source, testing, visual QA, and this task's `/feedback` session.
2. **Responses API with GPT-5.6** drafts the missing-document letter server-side. It uses the student's submitted context, does not expose the API key to the browser, runs asynchronously, and has an explicit offline fallback.
3. **Codex browser, image-input, and visual QA workflow** was used to catch real layout failures, including mobile overflow, collapsed callout padding, and over-rounded controls. These are Codex-craft evidence, not decorative claims.

### Relevant next only when we connect the live verifier

1. **Responses API web search with official-domain filters** should refresh a scholarship's verification state from provider pages and retain the returned source URLs. The model should be constrained to official agency or university domains and should never turn a search result into a recommendation without an official source. OpenAI's web-search tool supports domain filters and source inspection. [Web search guide](https://developers.openai.com/api/docs/guides/tools-web-search)
2. **Structured Outputs** should return a fixed verification record such as `confirmed`, `conflicting`, or `unverified`, plus a short reason and source references. This prevents a free-form model response from silently changing the product's trust state. [Structured Outputs guide](https://developers.openai.com/api/docs/guides/structured-outputs)

Do not claim these two capabilities are already live until the app can demonstrate them with an API key and retained official-source evidence.

### Deliberate non-features

Do not add Realtime voice, image generation, 3D scenes, an Agents SDK workflow, an Apps SDK wrapper, or unrelated tool calls just to name more OpenAI products. They do not make the student more likely to complete the next required document, and the judging criteria explicitly say feature count and trendy technology do not earn points by themselves.

## Final Submission Checklist

- [ ] Insert a working `OPENAI_API_KEY` and demonstrate one live Responses API letter draft.
- [ ] Add the Codex `/feedback` session ID to the Devpost submission.
- [ ] Make the repository accessible to judges and keep the local setup instructions current.
- [ ] Collect three consented student observations before claiming problem validation.
- [ ] Confirm every demo scholarship deadline and requirement against its official source.
- [ ] Record a public, under-three-minute demo that shows the complete profile-to-letter loop and names one material Codex decision.

## The One-Sentence Judge Answer

"Codex helped us cut a generic scholarship finder into one high-stakes readiness loop, then exposed and fixed the UI and trust failures that would have made that loop less honest for a student facing a deadline."
