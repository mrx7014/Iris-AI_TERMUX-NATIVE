<p align="center">
  <img src="static/logo.png" width="120" alt="Iris AI Logo">
</p>

<h1 align="center">Iris AI</h1>

<p align="center">
  <strong>Local Multi-Model AI Router — Private. Offline. Specialized.</strong>
</p>

<p align="center">
  <a href="#quick-start">Quick Start</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#models">Models</a> •
  <a href="#training">Training</a> •
  <a href="documentations/">Documentation</a>
</p>

---

## What is Iris AI?

Iris AI is a **local AI routing system** that runs multiple specialized GGUF models on your machine. Instead of one large general-purpose model trying to do everything, Iris routes every query to the best specialist.

| Role | Purpose | Example Query |
|------|---------|--------------|
| **Triage** | Classify & route queries | *"build me an OS kernel"* → `[ROUTE: CODE_COMPLEX]` |
| **Code** | Generate code, fix bugs | Full apps, websites, kernels, scripts |
| **Math** | Equations, proofs, computation | Calculus, linear algebra, statistics |
| **Reasoning** | System design, strategy, debugging | Architecture decisions, scaling, tradeoffs |
| **General** | Knowledge, explanations, comparisons | "Explain quantum computing", "React vs Vue" |
| **Vision** | Analyze images | Screenshots, diagrams, photos |

**No cloud. No API keys. Everything runs on your hardware.**

---

## Quick Start

```bash
# 1. One-time setup
bash setup.sh

# 2. Download models for your tier
python train.py --size medium --download-models

# 3. Start the web interface
python app.py

# 4. Or use the PC controller (CLI agent)
./controller        # C++ binary (build: g++ -std=c++17 -O2 controller.cpp -lcurl -o controller)
python controller.py   # Python fallback

# 5. Open browser → http://localhost:5000
```

---

## Size Tiers

Choose the tier that fits your hardware:

| Tier | Total Params | Storage | RAM | Largest Model | Best For |
|------|-----------|------------|---------------|----------|
| **Tiny** | 16B | ~11 GB | 4 GB | 4B | Raspberry Pi, old laptops |
| **Small** | 38B | ~27 GB | 8 GB | 8B | MacBook Air, budget laptops |
| **Medium** | 66B | ~46 GB | 16 GB | 14B | Modern laptops (default) |
| **Large** | 193B | ~102 GB | 24 GB | 32B | Workstations, Mac Studio |
| **Max** | 328B | ~235 GB | 48 GB | 72B | Servers, multi-GPU rigs |

```bash
# Switch tiers:
python train.py --size large --download-models
# Then edit config/iris.conf: "size": "large"
```

---

## Architecture

```text
                               User Query
                                   │
                                   ▼
                          ┌─────────────────┐
                          │     TRIAGE      │
                          │  (Query Gate)   │
                          └────────┬────────┘
                                   │
       ┌───────────┬───────────────┼───────────────┬───────────┐
       ▼           ▼               ▼               ▼           ▼
 ┌──────────┐ ┌──────────┐   ┌───────────┐   ┌──────────┐ ┌──────────┐
 │ GENERAL  │ │   MATH   │   │ REASONING │   │  VISION  │ │   CODE   │
 │ (Info)   │ │ (Calc)   │   │ (Design)  │   │ (Images) │ │  (Dev)   │
 └──────────┘ └──────────┘   └───────────┘   └──────────┘ └────┬─────┘
                                                               │
                                                       ┌───────┴───────┐
                                                       ▼               ▼
                                                 ┌───────────┐   ┌───────────┐
                                                 │  SIMPLE   │   │  COMPLEX  │
                                                 │(Snippets) │   │(Full Apps)│
                                                 └───────────┘   └───────────┘
```

**Only one model loaded at a time.** The triage model analyzes the query, outputs a routing tag, and the specialist model loads to handle the request.

---

## Project Structure

```
Iris-AI/
├── app.py                  # Flask web server
├── controller.py           # Python PC agent (natural-language computer control)
├── controller.cpp          # C++ PC agent (1:1 port, compiled binary)
├── train.py                # Unified training pipeline
├── setup.sh                # One-shot environment setup
├── README.md               # This file
├── requirements.txt        # Python dependencies
│
├── config/
│   ├── iris.conf           # Inference settings (temperature, context, models)
│   ├── control.conf        # PC controller config (email, apps, contacts)
│   ├── datasets.json       # Training dataset registry per role
│   └── sizes/              # Size tier definitions
│       ├── tiny.json
│       ├── small.json
│       ├── medium.json
│       ├── large.json
│       └── max.json
│
├── src/
│   ├── iris.py             # Core: model loading, routing, streaming, RAG
│   ├── iris_pro.py         # Pro mode: multi-agent API pipeline
│   ├── browser_agent.py    # Selenium-based browser automation agent
│   ├── context_compactor.py # Context window optimization
│   ├── grpo_trainer.py     # GRPO reinforcement learning trainer
│   ├── harness.py          # Code/math output post-processing
│   ├── syntax_checker.py   # Syntax validation for generated code
│   └── tools_harness.py    # Tool integration harness
│
├── training/
│   ├── coding/             # Code training data (generated_code.md, etc.)
│   ├── reasoning/          # Reasoning training (chain_of_thought.md, etc.)
│   ├── math/               # Math training data
│   ├── triage/             # Triage routing data (triage_dataset.md, etc.)
│   ├── general/            # General knowledge (chat_general.md, etc.)
│   ├── control/            # PC controller training
│   └── shared/             # Shared across all roles
│
├── benchmark/              # Automated evaluation suite
│   ├── run_all.py          # Orchestrator
│   ├── test_math.py        # Math benchmarks
│   ├── test_coding.py      # Code benchmarks
│   ├── test_mmlu.py        # MMLU (knowledge)
│   └── test_gpqa.py        # GPQA Diamond (science)
│
├── static/                 # Web UI assets (CSS, JS, images)
├── templates/              # Flask HTML templates
├── models/                 # Downloaded GGUF files
├── outputs/                # Training logs, benchmark results
├── logs/                   # Chat logs
├── uploads/                # User-uploaded images
└── documentations/         # Full documentation set
```

---

## Key Features

- **Multi-model routing**: 8 specialized models, each fine-tuned for its domain
- **Fully local & private**: No API calls, no data leaves your machine
- **5 size tiers**: From Raspberry Pi to multi-GPU server
- **Web interface**: Clean chat UI with streaming, image upload, settings
- **PC controller**: Natural-language computer control (open apps, files, system ops)
- **RAG knowledge base**: Index your documents for context-aware answers
- **Training pipeline**: Fine-tune models with LoRA, quantize to GGUF
- **Benchmark suite**: Automated evaluation on standard benchmarks
- **GRPO trainer**: Reinforcement learning from group preference optimization
- **Browser agent**: Selenium-based web automation
- **Pro mode**: Multi-agent API pipeline for complex tasks

---

## Training

```bash
# Train a single role:
python train.py --train-role code --iters 2000

# Train all roles:
python train.py --size medium --iters 2000

# Custom datasets:
python train.py --train-role math --iters 3000 --batch-size 2 --accum-steps 4

# Skip GGUF conversion for faster iteration:
python train.py --train-role code --skip-gguf
```

Training data is Markdown files with `USER:` / `BOT:` pairs. See [documentations/training.md](documentations/training.md) for full details.

---

## Benchmarks

```bash
python benchmark/run_all.py
```

Results written to `outputs/benchmark_results.csv`. Covers:
- **Math**: GSM8K, MATH (competition math)
- **Code**: HumanEval (execution-based), SWE-Bench (codebase repair)
- **Knowledge**: MMLU (57 subjects)
- **Science**: GPQA Diamond

---

## Hardware Requirements

| Tier | RAM | Storage | GPU (optional) | Params |
|------|-----|---------|----------------|--------|
| Tiny | 4 GB | ~11 GB | — | 16B |
| Small | 8 GB | ~27 GB | — | 38B |
| Medium | 16 GB | ~46 GB | Apple M1+ / 6GB VRAM | 66B |
| Large | 24 GB | ~102 GB | Apple M2 Ultra / 24GB VRAM | 193B |
| Max | 48 GB | ~220 GB | Apple M3 Max 48GB / 2x RTX 3090 | 328B |

---

## Full Documentation

All detailed docs live in [`documentations/`](documentations/):

| Document | Covers |
|----------|--------|
| [Architecture](documentations/architecture.md) | Full system design, data flow, component interactions |
| [Configuration](documentations/configuration.md) | Every config file, every setting explained |
| [Models](documentations/models.md) | Size tiers, role descriptions, model selection logic |
| [Router](documentations/router.md) | Triage model, classification, routing decisions |
| [Training](documentations/training.md) | Training pipeline, data format, LoRA, GGUF conversion |
| [Controller](documentations/controller.md) | PC agent actions, intent detection, platform support |
| [API Reference](documentations/api.md) | Flask endpoints, request/response formats |
| [Benchmarks](documentations/benchmarks.md) | Evaluation suite, scoring, results format |
| [Performance](documentations/performance.md) | Optimization, hardware tuning, latency benchmarks |

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

<p align="center">
  Built with ❤️ by the Iris team<br>
  <sub>Ahmed Barakat, Mazen Khaled, Yasmine Omar, Hamdy Ahmed</sub>
</p>
