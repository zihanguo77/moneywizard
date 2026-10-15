# 🧙‍♂️ MoneyWizard — Autonomous AI Spending Agent

> **Built for the Briefcase × Stripe London Hackathon**  
> *Autonomous corporate spending agent operating under strict, unbypassable financial policy guardrails with Stripe test mode payment settlement.*

---

## 🌟 1. Core Principle: Autonomy with Control

Corporate spending today is trapped between two extremes:
1. **Slow, manual expense approvals** that bottleneck engineering velocity and operations.
2. **Uncontrolled credit cards or blank-check agents** that risk budget blowout, double-billing, and unauthorized luxury purchases.

**MoneyWizard** solves this with **Autonomy with Control**:
- **Autonomous Action**: The agent evaluates incoming purchases, parses intent with AI, checks compliance against corporate policies, and executes payment flows automatically.
- **Strict Control**: The agent cannot override or bypass written financial policy rules. If an expense violates the rules, it is immediately blocked and recorded in an evidence-backed audit trail.

---

## 🚀 2. Quick Start (One Command)

Everything is pre-installed and configured. Simply run:

```bash
./start.sh
```

This launches:
- **Web Dashboard**: [http://localhost:5173](http://localhost:5173)
- **FastAPI Backend**: [http://127.0.0.1:8000](http://127.0.0.1:8000)
- **Interactive API Docs**: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)

*To stop both servers at any time, press `Ctrl + C` in your terminal.*

---

## 🎯 3. The 3 Ready-to-Run Hackathon Demo Scenarios

On the web dashboard, you can trigger three instant scenarios designed specifically for presentations and judging:

| Scenario | Purchase | Expected Outcome | What It Proves |
| :--- | :--- | :--- | :--- |
| **Scenario 1** | **Linear Pro Seat ($29.00)** | ✅ **Autonomous Approval & Paid** | Agent approves valid operational SaaS within limits, charges Stripe test card, logs `PaymentIntent` ID. |
| **Scenario 2** | **Cartier Luxury Watch ($3,850.00)** | ❌ **Policy Breach Blocked** | Agent catches limit breach (>$500 single limit) and restricted luxury category. Blocks transaction and cites exact policy clauses. |
| **Scenario 3** | **Duplicate Cloudflare Bill ($85.00)** | 🛡️ **Anti-Replay Intercepted** | Agent calculates cryptographic vendor hash and halts double-billing replay within the 30-minute lookback window. |

---

## 💳 4. Stripe Integration (Test Mode)

MoneyWizard integrates with the official **Stripe Python SDK** (`stripe>=10.0.0`):

- **Zero-Setup Out of the Box**: By default, MoneyWizard runs a high-fidelity Stripe test mode engine simulating standard test tokens (`Visa •••• 4242`) and generating authentic Stripe transaction references (`pi_3P...`, `ch_3P...`).
- **Real Stripe Test Keys**: To connect your live Stripe test account:
  1. Copy your test secret key from your [Stripe Dashboard](https://dashboard.stripe.com/test/apikeys) (starts with `sk_test_`).
  2. Put it in `.env`:
     ```env
     STRIPE_SECRET_KEY=sk_test_your_key_here
     ```
  3. Restart `./start.sh`. MoneyWizard will automatically make live Stripe test mode API calls!

---

## 🛡️ 5. Policy Guardrails Engine

MoneyWizard enforces 5 core governance checks on every transaction:

1. **LIMIT-01 (Single Transaction Limit)**: Default cap of `$500.00`. Any single purchase above this threshold is rejected.
2. **BUDGET-02 (Monthly Budget Cap)**: Default `$5,000.00/month`. Cumulative approved spend cannot breach this ceiling.
3. **CATEGORY-03 (Permitted Category Whitelist)**: Verifies that expenses belong to operational categories (e.g., *Software & SaaS*, *Cloud & Infrastructure*, *Developer Tools*) and prohibits restricted classes (*Luxury Goods*, *Gambling*).
4. **VENDOR-04 (Sanctions & Restricted Merchant Check)**: Screens merchant names against restricted watchlists (*Rolex*, *Casinos*, etc.).
5. **AUDIT-05 (Business Justification Validation)**: Ensures adequate rationale (minimum character length and bona fide operational context).
6. **DUP-01 (Anti-Replay Protection)**: SHA-256 vendor hash matching to prevent accidental or malicious double-submissions.

> **Live Policy Editor**: Click the **Policy Guardrails** button in the top navigation bar to adjust spending limits, budgets, and whitelists on the fly. The agent immediately enforces the new rules in real time!

---

## 🧠 6. AI Natural Language Parser

Instead of filling out rigid forms, team members can submit requests naturally:
- *"Approve $45 for Figma UI design seat for Sarah"*
- *"Pay $120 to Datadog for staging application monitoring"*
- *"Buy $3,400 Rolex Submariner for luxury client gift"*

The AI extraction engine parses the merchant, amount, category, and justification, runs pre-flight policy checks, and allows 1-click execution.

---

## 🏗️ 7. Architecture & Tech Stack

```
Stripe Hackathon/
├── start.sh                 # One-command launcher
├── backend/
│   ├── run.py               # Uvicorn server entrypoint
│   ├── requirements.txt     # Python dependencies
│   ├── moneywizard.db       # SQLite database (WAL mode)
│   └── app/
│       ├── main.py          # FastAPI REST API routes
│       ├── models.py        # Pydantic v2 schemas
│       ├── database.py      # SQLite persistence layer
│       ├── policy_engine.py # Autonomy-with-control rule engine & NLP
│       ├── stripe_service.py# Stripe Python SDK integration
│       └── seed_data.py     # Benchmark demo dataset
└── frontend/
    ├── src/
    │   ├── App.tsx          # Main dashboard coordinator
    │   ├── components/      # React components (Navbar, Metrics, Tables, Modals)
    │   ├── types.ts         # TypeScript interfaces
    │   └── index.css        # Tailwind CSS design system
    ├── package.json
    └── vite.config.ts
```

---

## 🎤 8. Presentation Walkthrough Script (for Judges)

1. **Introduction**: *"MoneyWizard gives organizations the speed of autonomous AI spending with the safety of unbypassable corporate financial policies."*
2. **Show the Metrics**: Point out the live Monthly Spend progress bar, Autonomous Approval rate, and Replay Blocks.
3. **Run Scenario 1 (Linear Pro $29)**: Click the button. Watch the confetti burst, examine the approved status, and inspect the Stripe `PaymentIntent` ID.
4. **Run Scenario 2 (Cartier Watch $3,850)**: Click the button. Show how the agent caught the $500 threshold violation and restricted luxury category.
5. **Run Scenario 3 (Duplicate Bill $85)**: Click the button. Show how anti-replay cryptographic hashing immediately intercepted the double-billing attempt.
6. **Show Policy Editor**: Open *Policy Guardrails*, show how any rule can be adjusted live, and explain that the agent operates under *Autonomy with Control*.

---
*Built with ❤️ for the Briefcase × Stripe London Hackathon.*
