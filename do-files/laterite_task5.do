/*=======================================================================
  Laterite Analytic Assessment – Task 5
  Goal:   Identify variables associated with mobile money account
          cancellation using a logistic regression model; discuss
          model choice and causal interpretation
  =====================================================================*/

* ------------------------------------------------------------------
* 0. Setup
* ------------------------------------------------------------------
clear all
set more off
capture log close
log using "laterite_task5.log", replace text

use "laterite_wide.dta", clear

* ------------------------------------------------------------------
* 1. Construct the outcome variable
* ------------------------------------------------------------------
gen byte mm_cancelled = .
replace mm_cancelled = 0 if has_mm == 1
replace mm_cancelled = 1 if has_mm == 0 & mm_account_cancelled == "yes"
* 201 never-MM users remain missing — excluded from all analysis below

label variable mm_cancelled ///
    "Cancelled MM account and no longer uses MM (0=current user, 1=cancelled)"

di _newline "=== ANALYSIS SAMPLE ==="
tab mm_cancelled, miss

* ------------------------------------------------------------------
* 2. Create/extend binary predictor variables
*    Task 4 dummies (failed_tx etc.) were created with if has_mm==1;
*    here we extend them to also cover cancelled MM users (mm_cancelled==1)
* ------------------------------------------------------------------

* Trust in mobile money
gen byte mm_trust_bin = .
replace mm_trust_bin = 1 if mm_trust == "yes"
replace mm_trust_bin = 0 if mm_trust == "no"
label variable mm_trust_bin "Trusts mobile money (1=yes)"

* Preference for cash
gen byte prefer_cash_bin = .
replace prefer_cash_bin = 1 if prefer_cash == "yes"
replace prefer_cash_bin = 0 if prefer_cash == "no"
label variable prefer_cash_bin "Prefers cash over digital payments (1=yes)"

* Consumer protection awareness (v243, v245)
gen byte knows_complain = .
replace knows_complain = 1 if v243 == "yes"
replace knows_complain = 0 if v243 == "no"
label variable knows_complain "Knows how/where to complain about MM (1=yes)"

gen byte data_understand = .
replace data_understand = 1 if v245 == "yes"
replace data_understand = 0 if v245 == "no"
label variable data_understand "Understands data MM providers collect (1=yes)"

* Extend service-quality dummies from Task 4 to include cancelled users
replace failed_tx    = 1 if v240 == "yes" & mm_cancelled == 1
replace failed_tx    = 0 if v240 == "no"  & mm_cancelled == 1
replace network_issues = 1 if v237 == "yes" & mm_cancelled == 1
replace network_issues = 0 if v237 == "no"  & mm_cancelled == 1
replace agent_no_cash  = 1 if v241 == "yes" & mm_cancelled == 1
replace agent_no_cash  = 0 if v241 == "no"  & mm_cancelled == 1
replace fee_clarity    = 1 if v238 == "yes" & mm_cancelled == 1
replace fee_clarity    = 0 if v238 == "no"  & mm_cancelled == 1
replace fraud_victim   = 1 if v246 == "yes" & mm_cancelled == 1
replace fraud_victim   = 0 if v246 == "no"  & mm_cancelled == 1

* ------------------------------------------------------------------
* 3. Bivariate descriptives — compare cancelled vs current MM users
*    This step motivates variable selection for the regression
* ------------------------------------------------------------------
di _newline(2) "=== BIVARIATE COMPARISONS: CANCELLED vs CURRENT MM USERS ==="

foreach v of varlist failed_tx network_issues agent_no_cash fraud_victim ///
                     fee_clarity mm_trust_bin prefer_cash_bin ///
                     knows_complain data_understand {
    quietly svy, subpop(if !missing(mm_cancelled)): ///
        tabulate mm_cancelled `v', row format(%7.3f)
    * Row 1 (mm_cancelled=0) = current users; Row 2 (=1) = cancelled
    di _newline "--- `v' ---"
    svy, subpop(if !missing(mm_cancelled)): ///
        tabulate mm_cancelled `v', row format(%7.3f)
}

di _newline "--- Urban/Rural ---"
svy, subpop(if !missing(mm_cancelled)): tabulate mm_cancelled urban_enc, row format(%7.3f)
di _newline "--- Gender ---"
svy, subpop(if !missing(mm_cancelled)): tabulate mm_cancelled gender_enc, row format(%7.3f)
di _newline "--- Education ---"
svy, subpop(if !missing(mm_cancelled)): tabulate mm_cancelled edu_group, row format(%7.3f)
di _newline "--- Mean age by cancellation status ---"
svy, subpop(if !missing(mm_cancelled)): mean age, over(mm_cancelled)

* Check pairwise correlations among candidate predictors to flag collinearity
di _newline(2) "=== PREDICTOR CORRELATIONS (multicollinearity check) ==="
pwcorr failed_tx network_issues agent_no_cash fraud_victim ///
       fee_clarity mm_trust_bin prefer_cash_bin ///
       knows_complain data_understand ///
       if !missing(mm_cancelled), sig star(0.05)

* ------------------------------------------------------------------
* 4. Logistic regression — odds ratios
*    logit with pweight + vce(robust) = svy:logit in point estimates
*    AND additionally reports pseudo R-squared and log-likelihood
* ------------------------------------------------------------------
di _newline(2) "=== LOGISTIC REGRESSION: ODDS RATIOS ==="
di "(OR > 1 = higher odds of cancellation; < 1 = lower odds)"

logit mm_cancelled ///
    i.urban_enc i.gender_enc age i.district_enc i.edu_group ///
    failed_tx network_issues agent_no_cash fraud_victim ///
    fee_clarity mm_trust_bin prefer_cash_bin ///
    knows_complain data_understand ///
    [pweight=weight], vce(robust) or nolog

* ------------------------------------------------------------------
* 5. Average Marginal Effects
*    Re-run model without 'or' then call margins
*    AME = average change in P(cancelled) per unit change in predictor
* ------------------------------------------------------------------
di _newline(2) "=== AVERAGE MARGINAL EFFECTS ==="
di "(Interpretation: a positive AME means the predictor increases"
di "the probability of cancellation by that many percentage points)"

quietly logit mm_cancelled ///
    i.urban_enc i.gender_enc age i.district_enc i.edu_group ///
    failed_tx network_issues agent_no_cash fraud_victim ///
    fee_clarity mm_trust_bin prefer_cash_bin ///
    knows_complain data_understand ///
    [pweight=weight], vce(robust) nolog

margins, dydx(*) post

* ------------------------------------------------------------------
* 6. Save updated dataset
* ------------------------------------------------------------------
save "laterite_wide.dta", replace
di _newline "Dataset updated — Task 5 variables added."

log close
