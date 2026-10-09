# =============================================================================
# clt_functions.R
# Shared code for the CLT Monte Carlo project.
# Load it at the top of every analysis file with:  source("../R/clt_functions.R")
# Base R only, so no extra packages are needed.
# =============================================================================


# -----------------------------------------------------------------------------
# 1. POPULATIONS
# Each population is a function: give it n, it returns ONE sample of size n.
# -----------------------------------------------------------------------------

# ---- Required populations ----
r_normal      <- function(n) rnorm(n, mean = 0, sd = 1)
r_die         <- function(n) sample(1:6, size = n, replace = TRUE)
r_exponential <- function(n) rexp(n, rate = 1)
r_binom_small <- function(n) rbinom(n, size = 5, prob = 0.10)
r_cauchy      <- function(n) rcauchy(n, location = 0, scale = 1)

# ---- Extra credit 1: Dependent machine failure (from dependent_failure_process) ----
# Each operating time's failure rate depends on the PREVIOUS operating time:
#   lambda_t = lambda_0 * exp(beta * (X_{t-1} - mu)),   X_t | X_{t-1} ~ Exp(lambda_t)
# A sample of size n is one machine's first n operating times.
r_dependent_failure <- function(n, baseline_rate = 1, beta = 1.25,
                                reference_time = 1) {
  x <- numeric(n)
  x[1] <- rexp(1, rate = baseline_rate)
  if (n > 1) {
    for (t in 2:n) {
      rate_t <- baseline_rate * exp(beta * (x[t - 1] - reference_time))
      x[t]   <- rexp(1, rate = rate_t)
    }
  }
  x
}

# ---- Extra credit 2: Non-identical basketball shots (from non_identical_basketball_shots) ----
# n shots. Shot t has its own make probability p_t, falling evenly from 0.90
# (first shot) to 0.50 (last shot). The shots are independent but NOT
# identically distributed.
basketball_p <- function(n) seq(0.90, 0.50, length.out = n)
r_basketball <- function(n) rbinom(n, size = 1, prob = basketball_p(n))

# ---- Extra credit 3: Life/death mixture (from custom_age_at_death_distribution) ----
# Discrete ages 0-100: an early-death exponential decay plus an adult bell
# curve centered at 65, normalized so the probabilities sum to 1.
death_age   <- 0:100
death_wt    <- 0.045 * exp(-death_age / 5) +
               0.030 * exp(-0.5 * ((death_age - 65) / 10)^2)
death_prob  <- death_wt / sum(death_wt)
r_life_death <- function(n) sample(death_age, size = n, replace = TRUE,
                                   prob = death_prob)

populations <- list(
  normal            = r_normal,
  die               = r_die,
  exponential       = r_exponential,
  binom_small       = r_binom_small,
  cauchy            = r_cauchy,
  dependent_failure = r_dependent_failure,
  basketball        = r_basketball,
  life_death        = r_life_death
)


# -----------------------------------------------------------------------------
# 2. THEORY: what the CLT predicts for the sample mean at sample size n
# Each entry returns c(mean = E[Xbar], se = SD(Xbar)).
# -----------------------------------------------------------------------------
life_mu <- sum(death_age * death_prob)
life_sd <- sqrt(sum((death_age - life_mu)^2 * death_prob))

theory <- list(
  normal      = function(n) c(mean = 0,    se = 1 / sqrt(n)),
  die         = function(n) c(mean = 3.5,  se = sqrt(35 / 12) / sqrt(n)),
  exponential = function(n) c(mean = 1,    se = 1 / sqrt(n)),
  binom_small = function(n) c(mean = 0.5,  se = sqrt(5 * 0.1 * 0.9) / sqrt(n)),
  # Cauchy has no mean and no variance, so there is nothing to compare against.
  cauchy      = function(n) c(mean = NA,   se = NA),
  # Dependent: no simple formula exists. This is the NAIVE prediction you would
  # make if you ignored the dependence and treated the data as i.i.d. Exp(1).
  # How the simulation differs from it is the point of this case.
  dependent_failure = function(n) c(mean = 1, se = 1 / sqrt(n)),
  # Independent, non-identical: the mean is the average p_t, and the variance of
  # the mean is the sum of the p_t(1 - p_t) divided by n^2.
  basketball  = function(n) {
    p <- basketball_p(n)
    c(mean = mean(p), se = sqrt(sum(p * (1 - p))) / n)
  },
  life_death  = function(n) c(mean = life_mu, se = life_sd / sqrt(n))
)


# -----------------------------------------------------------------------------
# 3. MONTE CARLO SIMULATION
#   n = observations in ONE sample   (the thing we are studying)
#   B = number of samples simulated  (only sets how precisely we see the
#                                     sampling distribution)
# -----------------------------------------------------------------------------
simulate_means <- function(gen, n, B = 10000, seed) {
  set.seed(seed)                     # set right before each experiment
  replicate(B, mean(gen(n)))
}


# -----------------------------------------------------------------------------
# 4. NUMERICAL DIAGNOSTICS
# -----------------------------------------------------------------------------

# Skewness: 0 for a normal distribution. + = right skew, - = left skew.
skewness <- function(x) {
  m <- mean(x); s <- sqrt(mean((x - m)^2))
  mean((x - m)^3) / s^3
}

# EXCESS kurtosis: 0 for a normal distribution. + = heavier tails than normal.
excess_kurtosis <- function(x) {
  m <- mean(x); s2 <- mean((x - m)^2)
  mean((x - m)^4) / s2^2 - 3
}

# Q-Q correlation: correlation between the points on qqnorm(). This is one
# number for "how straight is the Q-Q plot". 1 = perfectly straight.
qq_correlation <- function(x) {
  q <- qqnorm(x, plot.it = FALSE)
  cor(q$x, q$y)
}

# Shapiro-Wilk p-value on the first 5000 means (the test's maximum).
# CAUTION: with thousands of values the test flags tiny, harmless departures.
shapiro_p <- function(x) shapiro.test(x[seq_len(min(length(x), 5000))])$p.value

# Diagnostics for one set of sample means, compared with theory.
diagnose <- function(means, n, theo) {
  th <- theo(n)
  data.frame(
    n          = n,
    sim_mean   = mean(means),
    theo_mean  = unname(th["mean"]),
    sim_se     = sd(means),
    theo_se    = unname(th["se"]),
    se_ratio   = sd(means) / unname(th["se"]),   # 1 = matches theory
    skewness   = skewness(means),
    ex_kurt    = excess_kurtosis(means),
    qq_cor     = qq_correlation(means),
    shapiro_p  = shapiro_p(means)
  )
}


# -----------------------------------------------------------------------------
# 5. RUN A FULL STUDY: one population across many values of n
# Returns $table (one row per n) and $means (the simulated means, named by n).
# -----------------------------------------------------------------------------
run_study <- function(pop, ns, B = 10000, seed) {
  gen  <- populations[[pop]]
  theo <- theory[[pop]]
  means_list <- lapply(ns, function(n) simulate_means(gen, n, B, seed))
  names(means_list) <- ns
  table <- do.call(rbind, Map(function(m, n) diagnose(m, n, theo),
                              means_list, ns))
  rownames(table) <- NULL
  list(table = table, means = means_list)
}


# -----------------------------------------------------------------------------
# 6. PLOTS
# -----------------------------------------------------------------------------

# The population itself (a large draw), so you can see the shape you start from.
# For dependent_failure this is one long run of the machine. For basketball it
# is shots across a very long game, so it only shows the 0/1 split.
plot_population <- function(pop, size = 1e5, seed = 1) {
  set.seed(seed)
  x <- populations[[pop]](size)
  if (pop == "cauchy") {
    x <- x[abs(x) < 15]
    sub <- "(values beyond +/-15 cut off so the plot is readable)"
  } else sub <- ""
  if (length(unique(x)) <= 101) {
    barplot(table(x) / length(x), main = paste("Population:", pop),
            xlab = "Value", ylab = "Probability", sub = sub)
  } else {
    hist(x, breaks = 80, freq = FALSE, col = "grey85", border = "white",
         main = paste("Population:", pop), xlab = "Value", sub = sub)
  }
}

# Histogram (with fitted normal curve) plus normal Q-Q plot for one n.
plot_diagnostics <- function(means, n, pop = "") {
  op <- par(mfrow = c(1, 2), mar = c(4, 4, 3, 1))
  on.exit(par(op))
  hist(means, breaks = 50, freq = FALSE, col = "grey85", border = "white",
       main = paste0(pop, ": sample means, n = ", n), xlab = "Sample mean")
  curve(dnorm(x, mean(means), sd(means)), add = TRUE, col = "red", lwd = 2)
  qqnorm(means, main = paste0("Normal Q-Q, n = ", n), pch = 16, cex = 0.4)
  qqline(means, col = "red", lwd = 2)
}

# How skewness, kurtosis, Q-Q correlation and SE ratio change as n grows.
plot_convergence <- function(table, pop = "") {
  op <- par(mfrow = c(2, 2), mar = c(4, 4, 3, 1))
  on.exit(par(op))
  plot(table$n, table$skewness, type = "b", log = "x", pch = 16,
       xlab = "n (log scale)", ylab = "Skewness", main = pop); abline(h = 0, lty = 2)
  plot(table$n, table$ex_kurt, type = "b", log = "x", pch = 16,
       xlab = "n (log scale)", ylab = "Excess kurtosis", main = pop); abline(h = 0, lty = 2)
  plot(table$n, table$qq_cor, type = "b", log = "x", pch = 16,
       xlab = "n (log scale)", ylab = "Q-Q correlation", main = pop); abline(h = 1, lty = 2)
  if (all(is.na(table$se_ratio))) {
    plot.new(); title("SE ratio: no theoretical SE")
  } else {
    plot(table$n, table$se_ratio, type = "b", log = "x", pch = 16,
         xlab = "n (log scale)", ylab = "Simulated SE / theoretical SE",
         main = pop); abline(h = 1, lty = 2)
  }
}


# -----------------------------------------------------------------------------
# 7. YOUR "NORMAL ENOUGH" STANDARD
# `criteria` is a list YOU choose and justify, e.g.
#   list(max_abs_skew = ..., max_abs_kurt = ..., min_qq_cor = ...)
# Any criterion you leave out is not checked.
# -----------------------------------------------------------------------------
passes_standard <- function(table, criteria) {
  ok <- rep(TRUE, nrow(table))
  if (!is.null(criteria$max_abs_skew)) ok <- ok & abs(table$skewness) <= criteria$max_abs_skew
  if (!is.null(criteria$max_abs_kurt)) ok <- ok & abs(table$ex_kurt)  <= criteria$max_abs_kurt
  if (!is.null(criteria$min_qq_cor))   ok <- ok & table$qq_cor        >= criteria$min_qq_cor
  ok
}

# Smallest n that passes AND every larger tested n also passes (so one lucky
# n doesn't count as converged). NA = no tested n qualifies.
smallest_normal_n <- function(table, criteria) {
  ok <- passes_standard(table, criteria)
  for (i in seq_along(ok)) if (all(ok[i:length(ok)])) return(table$n[i])
  NA
}
