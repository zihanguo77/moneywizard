# MoneyWizard — AI Spending Agent

**Autonomy with control.** MoneyWizard is an AI spending agent that can make purchasing
decisions under a written financial policy, execute them in **Stripe test mode**, and explain
every single decision by pointing at the rule it applied and the evidence it used.

Built for the **Briefcase × Stripe London Hackathon**.

---

## The one idea that matters

Most "AI payment agent" demos let the model decide. That is not auditable, and it is not
defensible when a judge asks *"why did you pay this?"*

MoneyWizard splits the responsibility:

| Layer | Responsibility | Can it change a decision? |
|---|---|---|
| **Policy engine** (`backend/app/policy.py`) | Reads `policy.yaml`. Evaluates 13 rules. Returns APPROVED / SUSPENDED / REJECTED. | **Yes — it is the only thing that decides.** |
| **LLM** (`backend/app/llm.py`) | Drafts a proposal from messy text; rephrases an explanation the engine already produced. | **No.** Absent by default. |
| **Frontend** | Renders what the backend says. | **No.** It cannot authorise anything. |
| **Stripe** | Executes the payment, in test mode. | **No.** It is only ever called after an approval. |

**The policy engine is a deterministic, side-effect-free function of its inputs.** The same
request always produces the same verdict. The LLM is a translator and a narrator — never a
decision-maker.

---

## Three verdicts, not two

| Verdict | Meaning | What happens |
|---|---|---|
| **APPROVED** | Every rule passed. | MoneyWizard executes a Stripe test-mode PaymentIntent **autonomously**. |
| **SUSPENDED** | Legitimate, but beyond an autonomous limit. | **No money moves.** It goes to a human review queue. The reviewer can pay it or deny it. |
| **REJECTED** | A rule forbids it. | **No Stripe payment is ever created.** The requester is notified. |

`SUSPENDED` is the heart of the product: it is where *"the agent acts alone"* becomes
*"the agent knows when not to."*

---

## Honest scope statement

MoneyWizard creates and confirms a **Stripe PaymentIntent in test mode** against Stripe's
documented test payment-method tokens. That exercises a real card-authorisation flow and
returns a real `pi_...` reference.

**It does not pay suppliers.** No Stripe Connect, payout, or bank-transfer flow is implemented,
so no money reaches any merchant's account. A successful test charge is evidence of the
*authorisation* step, not of supplier settlement. The app says exactly this in the UI, and it
never reports a payment as successful unless Stripe returns `succeeded`.

Likewise, if you do not configure SMTP, the app records notifications as **SIMULATED** and
tells you they were not delivered. It never claims an email went out when it did not.

---

## Quick start (2 commands)

```bash
cd moneywizard
./run.sh
```

Then open **http://127.0.0.1:8000**

`run.sh` creates the virtual environment, installs dependencies, and starts the server. The
built dashboard is served by the same process, so **there is no second server to start.**

### Enable real Stripe test payments

The app runs without Stripe (it will honestly report `STRIPE_SECRET_KEY is not set`). To make
payments actually execute:

1. Get a **test** key from <https://dashboard.stripe.com/test/apikeys> — it starts with `sk_test_`.
2. Put it in `backend/.env`:

```bash
cp backend/.env.example backend/.env   # only needed once
# then edit backend/.env:
STRIPE_SECRET_KEY=sk_test_your_key_here
```

3. Restart `./run.sh`. The header pill should read **Stripe: test mode ready**.

> MoneyWizard **refuses to run with a live key**. `STRIPE_SECRET_KEY=sk_live_...` is rejected
> before any network call is made. See `assert_test_mode()` in `backend/app/config.py`.

---

## The written policy

The policy lives in **`backend/app/policy.yaml`** — a plain, readable file. It is the single
source of truth, and the dashboard renders it in the **Policy** tab.

```yaml
limits:
  max_auto_amount_minor: 100000      # £1,000 — maximum autonomous payment
  hard_ceiling_minor: 500000         # £5,000 — reject above this, always
  daily_auto_cap_minor: 750000       # £7,500 — rolling 24h autonomous cap
  monthly_category_budget_minor: { software: 500000, hardware: 400000, ... }
merchants:
  allowlist: [Acme Office Supplies, CloudScale Hosting, ...]   # DEMO DATA
  blocklist: [CashConverters Express, PersonalTreats Ltd]
guards:
  duplicate_detection: true
  business_purpose_min_words: 3
notifications:
  require_human_release_for_rejection: false
```

**The merchant allowlist is seeded demo data.** It is not evidence that any real merchant is
trusted, and the UI labels it as such.

### The 13 rules

Evaluated in this order on every single request. Each produces `rule_id`, status
(`PASS` / `FAIL` / `ESCALATE` / `SKIP`), a human explanation, and an `evidence` payload.

| # | Rule | Fails when |
|---|---|---|
| R01 | Required fields present | Any required field is missing or blank |
| R02 | Amount validity | Not a positive whole number of minor units (rejects `-1`, `0`, `"abc"`, `true`, `12.5`) |
| R03 | Currency support | Currency not in `GBP`/`USD`/`EUR` |
| R04 | Business purpose quality | Fewer than 3 words or 12 characters |
| R05 | Request ID / idempotency key | Neither supplied |
| R06 | Duplicate detection | Request ID **or** idempotency key already used |
| R07 | Prohibited-merchant check | Merchant is blocklisted |
| R08 | Approved-merchant check | Merchant is not on the allowlist |
| R09 | Autonomous approval limit | — **escalates** above £1,000 |
| R10 | Absolute policy ceiling | Above £5,000 |
| R11 | Rolling 24h autonomy cap | — **escalates** if projected spend exceeds the cap |
| R12 | Rolling 30-day category budget | — **escalates** if the category budget would be breached |
| R13 | Request velocity guard | — **escalates** at 25 requests/hour |

**Aggregation:** any `FAIL` → REJECTED · else any `ESCALATE` → SUSPENDED · else APPROVED.

A rule failure **must not** cause a payment. Notice that R08 fails and R09 escalates are
different code paths, so "unapproved merchant" can never silently become "escalated".

---

## Demo scenarios

On the dashboard, four buttons run the **real** backend pipeline — real policy engine, real
Stripe call. Nothing is faked or pre-recorded.

| Button | What it does | Expected |
|---|---|---|
| **A — Approved purchase** | £249 to CloudScale Hosting (allowlisted, under limit, valid purpose) | APPROVED → Stripe PaymentIntent created and confirmed |
| **B — Unapproved merchant** | £189.99 to QuickGadget Emporium (not allowlisted) | REJECTED by R08, **no Stripe call at all** |
| **C — Duplicate purchase** | Submits the same request ID twice | 1st APPROVED · 2nd REJECTED by R06, linked to the original |
| **D — Over the autonomous limit** | £1,450 to Northern Tools Ltd (allowlisted, legitimate, over £1,000) | SUSPENDED by R09 → human review queue |

Click **Reset demo data** between rehearsals to clear the ledger.

---

## Where to look in the code

```
moneywizard/
├── run.sh                        # one command to start everything
├── README.md
├── DEMO_SCRIPT.md                # judge-facing script
├── backend/
│   ├── .env.example              # placeholders only
│   ├── requirements.txt
│   ├── pytest.ini
│   ├── data/                     # SQLite (gitignored)
│   ├── tests/                    # 52 tests: policy, duplicates, API, honesty
│   └── app/
│       ├── policy.yaml           # ← THE WRITTEN POLICY
│       ├── policy.py             # ← THE DETERMINISTIC ENGINE (13 rules)
│       ├── stripe_gateway.py     # test-mode PaymentIntent + idempotency
│       ├── explanations.py       # "why did you pay this?"
│       ├── llm.py                # optional; drafts + narrates only
│       ├── memory.py             # optional Cognee; non-authoritative
│       ├── notifications.py      # honest email outbox
│       ├── db.py                 # SQLite + append-only audit events
│       └── main.py               # FastAPI routes + orchestration
└── frontend/
    ├── src/                      # React + TypeScript + Tailwind v4
    └── dist/                     # prebuilt, served by the backend
```

### The decision pipeline

`backend/app/main.py → process_request()`

1. Normalise input (a `request_id` is generated server-side if absent, so duplicate protection always works).
2. **Run the policy engine** — the only thing that decides.
3. Persist the request plus the full rule-by-rule audit record.
4. If **APPROVED** → call Stripe. If **SUSPENDED** → stop, queue for a human. If **REJECTED** → stop, notify.
5. Every step writes an immutable row to the `events` table.

---

## Safety properties (and how they are enforced)

| Property | Enforcement |
|---|---|
| No live money, ever | `assert_test_mode()` refuses `sk_live_*` before any network call |
| No duplicate charges | Deterministic idempotency key `moneywizard-{request_id}` → at most one PaymentIntent per request |
| No payment on rejection | The Stripe call site is only reachable on the `APPROVED` branch |
| Success is never faked | `settled` is true **only** when Stripe returns `succeeded` |
| The LLM cannot override policy | The engine takes no LLM input; `test_policy_can_never_be_overridden_by_an_llm` |
| The frontend cannot authorise | All validation and all decisions happen server-side |
| No secrets leak | `.env` is gitignored; `/api/health` exposes only booleans and modes, never key material |
| Explanations cannot contradict evidence | Built from stored `rules_json`; `test_explanation_never_claims_payment_when_stripe_failed` |

---

## Running the tests

```bash
cd moneywizard
./.venv/bin/python -m pytest backend -q
```

52 tests covering rule enforcement, duplicate prevention, the human-review flow, Stripe
failure modes, live-key refusal, and explanation honesty.

---

## Optional extras

**LLM drafting + narration.** Set `OPENAI_API_KEY` in `backend/.env`. Adds a
"describe it in plain English" box that drafts the form fields, and rephrases explanations.
Without it, everything still works — the app is fully deterministic by default. The LLM's
output is always shown as clearly separate from the authoritative decision.

**Cognee memory.** Set `COGNEE_API_KEY` and `pip install cognee`. Memory retrieves prior
purchase history and precedents to enrich explanations. It is rendered in a panel explicitly
labelled **NOT AUTHORITATIVE**, and `retrieve_context()` returns `authoritative: False`. The
engine never reads it. If Cognee is missing, a built-in SQLite memory takes over so the
feature always demoes.

**Email.** Set `SMTP_*` to actually deliver notifications. Without it, messages are composed
and stored, marked **SIMULATED**, and the UI says plainly that they were not delivered.

---

## Design note: why `require_human_release_for_rejection` defaults to `false`

A rejected request moves **no money**. Gating its notification behind a human approval adds
latency without adding safety — and makes the rejection path *slower than the payment path*,
which is backwards. The flag exists in `policy.yaml` if you want the stricter behaviour; flip
it to `true` and the dashboard will show held notifications awaiting release.
