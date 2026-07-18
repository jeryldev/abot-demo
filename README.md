# Abot

Abot is a scholarship application-readiness guide for Filipino Grade 12 students who may miss college not because they are unqualified, but because they discover fragmented, unverified scholarship information after the documents are already too late to obtain.

It is deliberately not a scholarship directory. Its core job is to turn one student's situation into a trusted next move: show what is verified, explain what could block an application, and make the missing document actionable before a deadline.

## The Core Demo

The included sample student, Ana Reyes, is an incoming public-school college student in Quezon City.

1. Open the profile and see the student context.
2. Move to the ranked plan. Abot separates an open CHED path, a DOST next-cycle path, and a claim it will not verify.
3. Open CHED Merit to see why Ana fits, the exact blockers, and the evidence behind the recommendation.
4. Build the checklist, mark the Certificate of Indigency as missing, generate a tailored request letter, edit it, and copy the final text. The UI labels whether the letter came from a live OpenAI response or the offline fallback.

The trust boundary is part of the product: Abot refuses to turn an unverified listing into a recommendation.

## Run Locally

```bash
mix setup
mix phx.server
```

Open [http://localhost:4000](http://localhost:4000).

The demo works without a key, using a clearly labelled offline fallback letter. To enable the live request-letter draft, add these values to `.env` and restart the Phoenix server:

```bash
OPENAI_API_KEY=your_key_here
OPENAI_MODEL=gpt-5.6
```

The API request runs server-side through the Responses API. The key never reaches browser code, and the app keeps working if the request fails or the network is unavailable. On a deployed host, set the same variables in the host's secret manager rather than uploading `.env`.

## Buildathon Evidence

The project was built with Codex using GPT-5.6. [Build evidence](docs/BUILD_EVIDENCE.md) records the concrete product decisions, implementation work, visual iteration, testing, and debugging that shaped this demo.

[Judge scorecard](docs/JUDGE_SCORECARD.md) maps the live demo and evidence to the Build Week criteria, including which OpenAI capabilities are genuinely relevant to Abot's trust-first workflow.

For a submission, add the Codex `/feedback` session ID to the Devpost form and keep the repository accessible to judges.

## Deliberate Boundaries

- The current build uses a deterministic sample student and seeded scholarship records so the live demo is reliable.
- It does not claim to submit an application or send a report to an external verification queue.
- A live model is restricted to drafting the request letter from the supplied student, document, scholarship, and deadline context. It must not invent scholarship terms or deadlines.

## Verification

```bash
mix assets.build
mix test
mix precommit
```
