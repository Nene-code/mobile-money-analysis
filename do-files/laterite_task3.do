/*=======================================================================
  Laterite Analytic Assessment – Task 3
  Goal:   Describe how the mobile money market is divided between
          Company A, B, and C; produce charts; test associations
 
=======================================================================*/

* ------------------------------------------------------------------
* 0. Setup
* ------------------------------------------------------------------
clear all
set more off
capture log close
log using "laterite_task3.log", replace text

use "laterite_wide.dta", clear
svyset _n [pweight=weight]

* ------------------------------------------------------------------
* 1. Parse mm_account_telco into per-company binary indicators
*    strpos(string, sub) > 0 means the company name appears in the field
*    Non-MM users (has_mm == 0) are set to missing throughout
* ------------------------------------------------------------------
gen byte has_mm_A = (strpos(mm_account_telco, "Company_A") > 0) if has_mm == 1
gen byte has_mm_B = (strpos(mm_account_telco, "Company_B") > 0) if has_mm == 1
gen byte has_mm_C = (strpos(mm_account_telco, "Company_C") > 0) if has_mm == 1

label variable has_mm_A "Has a Company A MM account (MM users only, 1=yes)"
label variable has_mm_B "Has a Company B MM account (MM users only, 1=yes)"
label variable has_mm_C "Has a Company C MM account (MM users only, 1=yes)"

* Number of distinct MM providers per user
gen byte n_providers = has_mm_A + has_mm_B + has_mm_C if has_mm == 1
label variable n_providers "Number of MM providers held (MM users only)"

di _newline "=== PROVIDER COUNT DISTRIBUTION (MM users) ==="
tab n_providers, miss

di _newline "=== ACCOUNT HOLDERS PER COMPANY (unweighted counts) ==="
tab has_mm_A, miss
tab has_mm_B, miss
tab has_mm_C, miss

* ------------------------------------------------------------------
* 2. Construct primary_provider variable
*    Single-provider users: mm_account_telco holds their only company name
*    Multi-provider users:  mm_account_telco_main identifies their primary
* ------------------------------------------------------------------
gen primary_provider = ""
replace primary_provider = mm_account_telco ///
    if has_mm == 1 & n_providers == 1
replace primary_provider = mm_account_telco_main ///
    if has_mm == 1 & n_providers > 1 & !missing(mm_account_telco_main)

* Verify all MM users have a primary provider
di _newline "=== PRIMARY PROVIDER DISTRIBUTION (unweighted) ==="
tab primary_provider, miss

* Flag any MM users still missing a primary (edge cases)
count if has_mm == 1 & missing(primary_provider)
di "MM users with no primary provider identified: " r(N)   // Should be 0

* Binary dummies for primary provider
gen byte primary_A = (primary_provider == "Company_A") if has_mm == 1
gen byte primary_B = (primary_provider == "Company_B") if has_mm == 1
gen byte primary_C = (primary_provider == "Company_C") if has_mm == 1

label variable primary_A "Primary MM provider is Company A (MM users only)"
label variable primary_B "Primary MM provider is Company B (MM users only)"
label variable primary_C "Primary MM provider is Company C (MM users only)"

* Sanity check: each MM user must have exactly one primary
gen byte chk = primary_A + primary_B + primary_C if has_mm == 1
tab chk, miss     // All values should equal 1
drop chk

* ------------------------------------------------------------------
* 3. Multi-provider indicator
* ------------------------------------------------------------------
gen byte multi_provider = (n_providers > 1) if has_mm == 1
label variable multi_provider "Holds accounts with 2+ MM companies (MM users only)"

* ------------------------------------------------------------------
* 4. Weighted market statistics (restricted to MM users via subpop)
* ------------------------------------------------------------------
di _newline(2) "=== ACCOUNT HOLDING RATE BY COMPANY (% of MM users) ==="
svy, subpop(if has_mm == 1): proportion has_mm_A
svy, subpop(if has_mm == 1): proportion has_mm_B
svy, subpop(if has_mm == 1): proportion has_mm_C

di _newline(2) "=== PRIMARY PROVIDER MARKET SHARE (% of MM users) ==="
svy, subpop(if has_mm == 1): proportion primary_A
svy, subpop(if has_mm == 1): proportion primary_B
svy, subpop(if has_mm == 1): proportion primary_C

di _newline(2) "=== MULTI-PROVIDER RATE (% of MM users with 2+ companies) ==="
svy, subpop(if has_mm == 1): proportion multi_provider

* ------------------------------------------------------------------
* 5. Associations — primary provider by district, urban/rural, gender
*    Encode primary_provider as numeric for svy: tabulate
* ------------------------------------------------------------------
encode primary_provider, gen(prov_enc)

di _newline(2) "=== PRIMARY PROVIDER BY DISTRICT ==="
svy, subpop(if has_mm == 1): tabulate district_enc prov_enc, row format(%7.4f)

di _newline(2) "=== PRIMARY PROVIDER BY URBAN/RURAL ==="
svy, subpop(if has_mm == 1): tabulate urban_enc prov_enc, row format(%7.4f)

di _newline(2) "=== PRIMARY PROVIDER BY GENDER ==="
svy, subpop(if has_mm == 1): tabulate gender_enc prov_enc, row format(%7.4f)

* Also check: do urban/rural users differ in multi-provider rates?
di _newline(2) "=== MULTI-PROVIDER RATE BY URBAN/RURAL ==="
svy, subpop(if has_mm == 1): tabulate urban_enc multi_provider, row format(%7.4f)

* ------------------------------------------------------------------
* 6. Charts
* ------------------------------------------------------------------

* --- Chart 1: Overall primary market share (all MM users, weighted) ---
preserve
    keep if has_mm == 1

    * Compute weighted means (= weighted proportions for binary vars)
    collapse (mean) primary_A primary_B primary_C [aweight=weight]

    * Reshape to long format so each company is one observation (row)
    gen obs = 1
    reshape long primary_, i(obs) j(company) string
    rename primary_ market_share

    replace company = "Company A" if company == "A"
    replace company = "Company B" if company == "B"
    replace company = "Company C" if company == "C"

    graph bar market_share, over(company, sort(market_share) descending ///
              label(labsize(medlarge))) ///
        title("Mobile Money: Primary Provider Market Share", size(medlarge)) ///
        subtitle("Weighted proportion of mobile money users", size(small)) ///
        ytitle("Proportion of MM users", size(medsmall)) ///
        ylabel(0(0.1)0.7, labsize(small) format(%3.1f)) ///
        blabel(bar, format(%4.3f) size(medsmall) position(outside)) ///
        bar(1, color(navy)) ///
        graphregion(color(white)) bgcolor(white) ///
        note("Note: Based on primary (main) account designation." ///
             "Single-provider users: their sole company." ///
             "Multi-provider users: self-identified main account.", size(vsmall))

    graph export "chart1_overall_market_share.png", replace width(1400)
    di "Chart 1 saved: chart1_overall_market_share.png"
restore

* --- Chart 2: Primary market share by district (grouped bar) ---
preserve
    keep if has_mm == 1

    * Compute weighted market share within each district
    collapse (mean) primary_A primary_B primary_C [aweight=weight], ///
             by(district_enc)

    graph bar primary_A primary_B primary_C, ///
        over(district_enc, label(labsize(medsmall))) ///
        title("Primary MM Provider Market Share by District", size(medlarge)) ///
        subtitle("Weighted proportion of MM users per district", size(small)) ///
        legend(label(1 "Company A") label(2 "Company B") label(3 "Company C") ///
               rows(1) position(6) size(medsmall)) ///
        ytitle("Proportion of MM users", size(medsmall)) ///
        ylabel(0(0.1)1, labsize(small) format(%3.1f)) ///
        bar(1, color(navy)) ///
        bar(2, color(orange)) ///
        bar(3, color(forest_green)) ///
        graphregion(color(white)) bgcolor(white)

    graph export "chart2_market_share_by_district.png", replace width(1400)
    di "Chart 2 saved: chart2_market_share_by_district.png"
restore

* ------------------------------------------------------------------
* 7. Save updated dataset
* ------------------------------------------------------------------
save "laterite_wide.dta", replace
di _newline "Dataset updated — Task 3 variables (has_mm_A/B/C, primary_A/B/C," ///
            " n_providers, multi_provider) saved."

log close
