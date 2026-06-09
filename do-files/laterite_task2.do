/*=======================================================================
  Laterite Analytic Assessment – Task 2
  Goal:   Create dummy variables for financial exclusion and digital
          financial inclusion; report weighted rates and associations
  
=======================================================================*/

* ------------------------------------------------------------------
* 0. Setup
* ------------------------------------------------------------------
clear all
set more off
capture log close
log using "laterite_task2.log", replace text

* Load reshaped dataset from Task 1
use "laterite_wide.dta", clear

* Re-declare survey design (sampling weights; no cluster variable)
svyset _n [pweight=weight]

* ------------------------------------------------------------------
* 1. Create helper grouping variables for association analysis
* ------------------------------------------------------------------

* --- Encode string categorical variables as labelled numerics ---
encode urban,    gen(urban_enc)
encode gender,   gen(gender_enc)
encode district, gen(district_enc)

* --- Age groups (age has no missing values; min=18, max=97) ---
gen byte age_group = .
replace age_group = 1 if age >= 18 & age <  25
replace age_group = 2 if age >= 25 & age <  35
replace age_group = 3 if age >= 35 & age <  50
replace age_group = 4 if age >= 50 & age != .
label define age_lbl 1 "18-24" 2 "25-34" 3 "35-49" 4 "50+"
label values age_group age_lbl
label variable age_group "Age group"

* --- Education groups ---
gen byte edu_group = .
replace edu_group = 1 if regexm(highest_grade_completed, "^primary")
replace edu_group = 2 if regexm(highest_grade_completed, "^secondary")
replace edu_group = 3 if highest_grade_completed == "tvet"
replace edu_group = 4 if highest_grade_completed == "university"
replace edu_group = 5 if highest_grade_completed == "other"
label define edu_lbl 1 "Primary" 2 "Secondary" 3 "Vocational/TVET" ///
                     4 "University" 5 "Other"
label values edu_group edu_lbl
label variable edu_group "Highest education level (grouped)"

* ------------------------------------------------------------------
* 2. Create the two dummy variables
* ------------------------------------------------------------------

* 2a. FINANCIAL EXCLUSION
*     = 1 if no financial account of any kind (total_accounts == 0)
gen byte fin_excluded = (total_accounts == 0)
label variable fin_excluded "Financially excluded (1 = no accounts of any kind)"

* 2b. DIGITAL FINANCIAL INCLUSION
*     = 1 if holds at least one mobile money OR online bank account
gen byte dig_fin_included = (has_mm == 1 | has_online_bank == 1)
label variable dig_fin_included "Digitally financially included (MM or online bank)"

* Unweighted counts as a sanity check before applying weights
di _newline "=== UNWEIGHTED COUNTS (before survey weights) ==="
tab fin_excluded,      miss
tab dig_fin_included,  miss

* ------------------------------------------------------------------
* 3. Weighted overall rates
*    svy: proportion applies sampling weights and produces 95% CIs
* ------------------------------------------------------------------
di _newline(2) "=== WEIGHTED RATE: FINANCIAL EXCLUSION ==="
svy: proportion fin_excluded

di _newline(2) "=== WEIGHTED RATE: DIGITAL FINANCIAL INCLUSION ==="
svy: proportion dig_fin_included

* ------------------------------------------------------------------
* 4. Associations with Financial Exclusion
*
*    svy: tabulate rowvar fin_excluded, row
*      → each row shows: proportion NOT excluded | proportion excluded
*      → "fin_excluded = 1" column = exclusion rate for that subgroup
*      → Design-based F p-value tests if rates differ across groups
* ------------------------------------------------------------------
di _newline(2) "=== FIN. EXCLUSION BY GENDER ==="
svy: tabulate gender_enc fin_excluded, row format(%7.4f)

di _newline(2) "=== FIN. EXCLUSION BY URBAN/RURAL ==="
svy: tabulate urban_enc fin_excluded, row format(%7.4f)

di _newline(2) "=== FIN. EXCLUSION BY DISTRICT ==="
svy: tabulate district_enc fin_excluded, row format(%7.4f)

di _newline(2) "=== FIN. EXCLUSION BY AGE GROUP ==="
svy: tabulate age_group fin_excluded, row format(%7.4f)

di _newline(2) "=== FIN. EXCLUSION BY EDUCATION LEVEL ==="
svy: tabulate edu_group fin_excluded, row format(%7.4f)

* ------------------------------------------------------------------
* 5. Associations with Digital Financial Inclusion
* ------------------------------------------------------------------
di _newline(2) "=== DIGITAL INCLUSION BY GENDER ==="
svy: tabulate gender_enc dig_fin_included, row format(%7.4f)

di _newline(2) "=== DIGITAL INCLUSION BY URBAN/RURAL ==="
svy: tabulate urban_enc dig_fin_included, row format(%7.4f)

di _newline(2) "=== DIGITAL INCLUSION BY DISTRICT ==="
svy: tabulate district_enc dig_fin_included, row format(%7.4f)

di _newline(2) "=== DIGITAL INCLUSION BY AGE GROUP ==="
svy: tabulate age_group dig_fin_included, row format(%7.4f)

di _newline(2) "=== DIGITAL INCLUSION BY EDUCATION LEVEL ==="
svy: tabulate edu_group dig_fin_included, row format(%7.4f)

* ------------------------------------------------------------------
* 6. Save updated dataset for Tasks 3-5
*    (fin_excluded, dig_fin_included, age_group, edu_group all added)
* ------------------------------------------------------------------
save "laterite_wide.dta", replace
di _newline "laterite_wide.dta updated — Task 2 variables saved."

log close
