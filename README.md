# How Fast Does Normal Happen? Stress-Testing the Central Limit Theorem

An R-based Monte Carlo study of how quickly the sampling distribution of the
sample mean becomes approximately normal across populations of different shapes,
and of what happens when the CLT's assumptions (independence, identical
distribution, finite variance) break down.

**Start here:** [`analyses/00_summary.qmd`](analyses/00_summary.qmd) (executive summary and results table)

## Repository layout

| File | Contents |
|---|---|
| `R/clt_functions.R` | Shared code: populations, theory, simulation, diagnostics, plots |
| `analyses/00_summary.qmd` | Executive summary, "normal enough" argument, cross-distribution table |
| `analyses/01_normal.qmd` | Standard Normal |
| `analyses/02_die.qmd` | Six-sided die |
| `analyses/03_exponential.qmd` | Exponential (includes the reproducibility experiment) |
| `analyses/04_binom_small.qmd` | Binomial(5, 0.10) |
| `analyses/05_cauchy.qmd` | Cauchy |
| `analyses/EC1_dependent_failure.qmd` | Extra credit: dependent machine failures |
| `analyses/EC2_basketball.qmd` | Extra credit: non-identical basketball shots |
| `analyses/EC3_life_death.qmd` | Extra credit: life/death mixture |
| `ai_prompts.md` | Record of AI prompts, follow-ups, and how I checked the results |

## Reproducing the results

Open any `.qmd` file in RStudio and click **Render**. Only `knitr` is needed.
All simulations use seed 8515 (last four digits of my student ID), set right
before each simulation, with B = 10,000 Monte Carlo repetitions.

## Key findings

- **There is no universal n = 30.** The smallest sample size at which the sample mean looked approximately normal ranged from **n = 1** (Normal) to **n = 300** (dependent failures). For the Cauchy, **no n works**.
- **Skewness and discreteness set the pace.** Symmetric, smooth populations converged fast (Die 9, Life/death 16). Skewed or highly discrete ones were slow (Exponential 80, Binomial(5, 0.1) 80, Basketball 125).
- **The assumptions matter most.** Independent but non-identical data still followed the CLT. Dependent data converged slowly *and* broke the σ/√n formula (SE 2.16× too large). Infinite-variance (Cauchy) data never converged: averaging 1,000 values was no better than one.

| Population | Smallest n judged normal |
|---|---|
| Normal | 1 |
| Die | 9 |
| Life/death (extra credit) | 16 |
| Exponential | 80 |
| Binomial(5, 0.10) | 80 |
| Basketball shots (extra credit) | 125 |
| Dependent machine failure (extra credit) | 300 |
| Cauchy | none |

**"Normal enough" standard (used for every population):** |skewness| ≤ 0.25, |excess kurtosis| ≤ 0.3, Q-Q correlation ≥ 0.998, every larger n must also pass, and the plots must agree. See the summary for the reasoning.
