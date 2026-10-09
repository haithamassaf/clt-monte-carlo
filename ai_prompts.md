# AI Prompt Log

Tool used: Claude (Anthropic). Below are the important prompts, what came back,
what was wrong or missing, how I re-prompted, and how I checked the results.

## Entry 1: Choosing my "normal enough" standard
- **Prompt:** Shared my first exponential results, rendered with placeholder cutoffs (|skewness| ≤ 0.2), and asked for help interpreting them.
- **Problem I found:** With a 0.2 cutoff, n = 100 failed by only 0.004 (skewness 0.2037), and the other seed gave 0.212 at the same n. The cutoff was tighter than the Monte Carlo noise, so the seed was deciding the answer.
- **Re-prompt / decision:** Asked how to set a cutoff that is defensible rather than arbitrary. I raised the skewness cutoff to 0.25, based on (1) the noise level in the Normal control (skewness up to 0.06, kurtosis up to 0.13 for truly normal data) and (2) the seed-to-seed differences of up to about 0.07.
- **Result:** One standard applied to every population: |skewness| ≤ 0.25, |excess kurtosis| ≤ 0.3, Q-Q correlation ≥ 0.998, and every larger n must also pass.
- **How I checked it:** Confirmed the exponential skewness follows the theoretical 2/√n (0.365 vs 0.361 at n = 30), so the cutoff predicts n ≥ 64, consistent with my simulated n = 80.

## Entry 2: Catching an incorrect claim in the reproducibility write-up
- **Prompt:** Asked for help writing the reproducibility section after changing the cutoff.
- **Problem I found:** The first draft said "the conclusion did not change", but after the new cutoff and refined n grid, my seed (8515) gave n = 80 while the second seed used for the reproducibility check (8516) gave n = 100.
- **Re-prompt:** Asked it to recheck every number against my actual rendered output before I used it.
- **Better result:** A corrected paragraph stating that the exact n moved from 80 to 100 while the conclusion (far more than 30, roughly 80–100) held. It explains that B controls Monte Carlo noise and n controls the shape.
- **How I checked it:** Compared every number in each paragraph against the tables in my rendered HTML before pasting.

## Entry 3: Discrete populations and the Q-Q criterion
- **Prompt:** Asked why the small binomial passed skewness and kurtosis at n = 25 but still failed my standard.
- **Response:** The Q-Q correlation was 0.995 because the sample mean can only take a few values (59% of draws are 0), so the Q-Q plot is a staircase.
- **What I learned / how I checked:** Looked at the Q-Q plots at n = 30 and n = 80 and saw the steps shrink. This convinced me to keep the Q-Q criterion: moment statistics alone would have called the population normal too early. The same thing limited the Die (n = 9) and the Basketball model (n = 125).

## How I validated AI-generated code overall
- Rendered every file and checked that simulated means and SEs match theory where theory exists.
- Checked that the generators match the professor's specifications.
- Reran the exponential with a second seed to check reproducibility.
- Verified that every number quoted in my text matches the rendered tables.
