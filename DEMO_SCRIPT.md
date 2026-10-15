# MoneyWizard — Judge Demo Script

**Target: 3 minutes.** Everything below is live; nothing is pre-recorded or faked.

---

## Before you present (do this 5 minutes before)

```bash
cd moneywizard
./run.sh
```

1. Open <http://127.0.0.1:8000>
2. Check the header pill says **Stripe: test mode ready**. If it says `missing`, your
   `backend/.env` has no test key — fix that now, payments will not run without it.
3. Click **Reset demo data** so you start from a clean ledger.
4. Keep a second terminal open on `backend/.env` and a browser tab on
   <https://dashboard.stripe.com/test/payments> — showing Stripe's own dashboard is the
   strongest possible proof the payment is real.

---

## The opening line (15 seconds)

> "Every company wants an agent that can spend money. Nobody trusts one, because when it gets
> it wrong, nobody can explain why. So we built the agent that can't get away with it.
>
> MoneyWizard enforces a written policy in code, and it can explain every pound it moves — by
> pointing at the rule and the evidence."

Then: **"Watch me try to make it spend money it shouldn't."**

---

## Scenario B — it says NO (30 seconds)

Click **B — Unapproved merchant**.

- Point at the red **REJECTED** badge and the outcome chip **Blocked**.
- Say: *"£189.99 to a merchant that isn't on our approved list. It refused."*
- Click the row to open the drawer.
- **This is the moment.** Point at:
  - **WHY** — a plain-English answer naming `R08_MERCHANT_ALLOWLIST`
  - **STRIPE EVIDENCE** — **"NO PAYMENT CREATED"**, and the PaymentIntent field reading
    `none — no Stripe call was made`
  - The 13 rules, with the one failure expanded showing the raw evidence JSON
- Say: *"It didn't just say no — it shows the rule it applied and the exact data it looked at.
  And critically, it never talked to Stripe at all."*

---

## Scenario A — it says YES, autonomously (45 seconds)

Click **A — Approved purchase**.

- Green **APPROVED**, outcome **Paid**, and a real `pi_...` PaymentIntent id.
- Switch to the **Stripe dashboard tab** and show the payment that just appeared.
- Say: *"£249 to an allowlisted merchant, under the £1,000 limit, with a real business purpose.
  It paid on its own, in test mode, with no human involved. That id is a real Stripe object —
  go and look at it."*
- Back in MoneyWizard, open the drawer and scroll to **"12 passed, 0 failed"**.

> If asked about merchants: *"The allowlist is seeded demo data — the UI says so. We're not
> claiming any real merchant is trusted."*

---

## Scenario D — it says "I need a human" (30 seconds)

Click **D — Over the autonomous limit**.

- Amber **SUSPENDED**, outcome **Awaiting review**.
- Say: *"£1,450. Perfectly legitimate purchase, allowlisted supplier, good reason. But it's
  over our £1,000 autonomous limit. So it stopped. It moved no money, and it's waiting."*
- Point at the rule detail: *"£1,450.00 exceeds the £1,000.00 autonomous limit. MoneyWizard
  will not pay this alone; it needs a human owner."*
- Go to **Review queue**, type a note, click **Approve & pay** → it executes.
- Say: *"The human decision is in the audit trail too — who approved it, when, and why. The
  policy verdict never changes; the human action is recorded alongside it."*

**This is your differentiator.** Most agents are approve/reject. The interesting case is
*"I could do this, but I shouldn't be the one to."*

---

## Scenario C — duplicate protection (25 seconds)

Click **C — Duplicate purchase**.

- Two steps appear: the first APPROVED, the second **REJECTED / Duplicate blocked**.
- Say: *"Same request ID twice. One payment, not two."*
- Open the duplicate record. Point at **Linked to an earlier request**, the `#DUP-` suffix, and
  the idempotency key.
- Say: *"The second one isn't just refused — it's linked to the original, so finance can see
  the attempt. And the Stripe idempotency key means even a concurrent retry can't double-charge."*

---

## Closing (20 seconds)

Switch to **Audit trail**.

> "Every event, append-only, in order. And note what's *not* deciding: the LLM drafts and
> narrates, but the deterministic engine has final authority. That's the only way 'explain
> every pound' means anything.
>
> It cannot use a live key — we refuse to boot with one. It cannot fake a success — `settled`
> is true only when Stripe literally returns `succeeded`. And it won't claim it paid a supplier,
> because we haven't built a payout flow and we're not going to pretend we have."

---

## Likely judge questions

**"Is the LLM deciding anything?"**
No. The engine takes no LLM input. There's a test named
`test_policy_can_never_be_overridden_by_an_llm` that proves it.

**"What if two identical requests arrive at once?"**
The `request_id` is the SQLite primary key, so the second insert collides and is recorded as a
blocked duplicate. And Stripe's idempotency key `moneywizard-{request_id}` means at most one
PaymentIntent can ever exist per request.

**"Why does a rejection email not need human approval?"**
Because it moves no money. Gating it would make the rejection path slower than the payment
path. The flag exists in `policy.yaml` if you want it stricter.

**"What's not done?"**
Supplier payouts. We authorise a payment; there's no Connect/transfer flow, so no merchant is
actually settled — and the app says that on every single screen.

---

## If something breaks on stage

- **Stripe pill says `missing`** → `backend/.env` lost its key. Scenario A will show
  `PAYMENT_FAILED` with a clear reason. It will *not* lie. Say so — it's a feature.
- **"Cannot reach the backend"** → the server died; re-run `./run.sh`.
- **Slow/offline** → everything except the Stripe call is local. Run scenarios B, C and D;
  they need no network at all.
