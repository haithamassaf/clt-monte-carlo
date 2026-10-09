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

Open any `.qmd` file in RStudio and click **Render**. No extra packages are
needed beyond `knitr`. Seeds are set right before each simulation.

## Key findings

> Fill in at the end: 2–3 headline conclusions.
