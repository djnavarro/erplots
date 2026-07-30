# Simulates `erplots_data`, the package's own bundled example dataset.
#
# Design goals:
#  - multiple, always-continuous exposure columns (auc_ss, cmax_ss, cmin_ss)
#  - response columns spanning all three response types (continuous, binary,
#    count)
#  - one exposure/response pair suitable for each of: Emax-continuous,
#    Emax-binary, logistic regression, linear regression, Poisson regression
#  - a placebo arm plus several active dose levels
#  - a few plausible covariates (bodyweight, age, sex, renal function)
#  - large enough (n = 4000) that a raw-point data-layer overlay visibly
#    overplots, motivating `er_style_data_hex()`/a density-based alternative
#  - a `study_id` column, independent of dose/exposure/response, that's
#    convenient to filter on to illustrate the same plot at a smaller N

library(tibble)

set.seed(8137)
n <- 4000

dose_levels <- c(0, 10, 30, 100, 300)
dose_labels <- c("Placebo", "10 mg", "30 mg", "100 mg", "300 mg")

dose_mg <- rep(dose_levels, each = n / length(dose_levels))
dose_group <- factor(
  rep(dose_labels, each = n / length(dose_levels)),
  levels = dose_labels,
  ordered = TRUE
)

# Covariates
bodyweight_kg <- pmax(40, round(rnorm(n, 70, 12), 1))
age_years <- pmax(18, pmin(85, round(rnorm(n, 45, 13))))
sex <- factor(sample(c("F", "M"), n, replace = TRUE))
renal_function <- factor(
  sample(c("Normal", "Mild", "Moderate"), n, replace = TRUE, prob = c(0.7, 0.2, 0.1)),
  levels = c("Normal", "Mild", "Moderate")
)

# study_id: a purely administrative label (which of 4 pooled studies a
# subject came from), independent of dose/exposure/response by construction.
# Its only purpose is to be a convenient filtering column: subsetting to one
# study gives a smaller sample (as few as 400 rows) that still spans the
# full dose range, useful for illustrating how a plot looks with less data.
study_labels <- c("Study 1", "Study 2", "Study 3", "Study 4")
study_sizes <- c(400, 800, 1200, 1600)
study_id <- factor(sample(rep(study_labels, times = study_sizes)), levels = study_labels)

# Exposure: a simple (not a literal PK/ODE) one-compartment-flavored
# simulation. Individual clearance depends on bodyweight and renal function;
# AUC follows from dose/clearance; Cmax/Cmin are derived from AUC via
# individually-varying peak/trough ratios, so all three exposure columns are
# internally consistent (correlated, but not identical).
renal_mult <- c(Normal = 1, Mild = 0.8, Moderate = 0.6)[as.character(renal_function)]
CL_pop <- 5
eta_cl <- rnorm(n, 0, 0.3)
CL_i <- CL_pop * (bodyweight_kg / 70)^0.75 * renal_mult * exp(eta_cl)

auc_noise <- exp(rnorm(n, 0, 0.15))
auc_ss <- ifelse(dose_mg == 0, 0, (dose_mg / CL_i) * auc_noise)

tau <- 24
ptr <- rlnorm(n, meanlog = log(1.8), sdlog = 0.2)
trough_frac <- rlnorm(n, meanlog = log(0.5), sdlog = 0.15)
cmax_ss <- ifelse(dose_mg == 0, 0, (auc_ss / tau) * ptr)
cmin_ss <- ifelse(dose_mg == 0, 0, (auc_ss / tau) * trough_frac)

# Responses -- one exposure/response pair per modelling scenario.

# 1. biomarker_change: continuous, Emax on auc_ss
Emax_bio <- -20
EC50_bio <- 20
biomarker_change <- Emax_bio * auc_ss / (EC50_bio + auc_ss) +
  0.05 * (age_years - 45) +
  ifelse(sex == "M", 1, 0) +
  rnorm(n, 0, 4)

# 2. responder: binary, Emax on logit(cmax_ss)
logit_p0 <- qlogis(0.05)
Emax_logit <- 3.5
EC50_cmax <- 1
logit_p <- logit_p0 + Emax_logit * cmax_ss / (EC50_cmax + cmax_ss)
responder <- rbinom(n, 1, plogis(logit_p))

# 3. adverse_event: binary, plain log-linear logistic on log(auc_ss + 1)
logit_ae0 <- qlogis(0.03)
slope_ae <- 0.5
logit_ae <- logit_ae0 + slope_ae * log(auc_ss + 1) +
  0.02 * (age_years - 45) +
  ifelse(renal_function == "Moderate", 0.3, 0)
adverse_event <- rbinom(n, 1, plogis(logit_ae))

# 4. symptom_score: continuous, linear in cmin_ss
symptom_score <- 50 - 6 * cmin_ss + 0.1 * (age_years - 45) + rnorm(n, 0, 5)

# 5. n_events: count, Poisson (log-linear rate) on log(auc_ss + 1)
log_mu0 <- log(0.3)
slope_events <- 0.35
mu_events <- exp(log_mu0 + slope_events * log(auc_ss + 1))
n_events <- rpois(n, mu_events)

erplots_data <- tibble(
  subject_id = seq_len(n),
  dose_mg = dose_mg,
  dose_group = dose_group,
  study_id = study_id,
  bodyweight_kg = bodyweight_kg,
  age_years = age_years,
  sex = sex,
  renal_function = renal_function,
  auc_ss = round(auc_ss, 2),
  cmax_ss = round(cmax_ss, 3),
  cmin_ss = round(cmin_ss, 3),
  biomarker_change = round(biomarker_change, 2),
  responder = responder,
  adverse_event = adverse_event,
  symptom_score = round(symptom_score, 2),
  n_events = n_events
)

usethis::use_data(erplots_data, overwrite = TRUE)
