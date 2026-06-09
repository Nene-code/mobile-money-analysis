/* Laterite Analytic Assessment – Task 1
  Goal:   Reshape the raw data from one observation per account type
          to one observation per participant (hhid)
*/

* ------------------------------------------------------------------
* 0. Setup
* ------------------------------------------------------------------
cd "C:\Users\DELL\Downloads\Laterite Analytic Assessment_Research team"
clear all
set more off
capture log close
log using "laterite_task1.log", replace text

* ------------------------------------------------------------------
* 1. Import the raw CSV
*    stringcols(_all) brings everything in as strings so we can
*    inspect and destring selectively, avoiding silent type coercion.
* ------------------------------------------------------------------
import delimited using "laterite_mobilemoney_data.csv", ///
    stringcols(_all) varnames(1) clear

* Quick structural check
di "Raw rows imported: " _N                 // Expected: 2,442
quietly tab hhid
di "Unique participants (hhid): " r(r)      // Expected: 1,205

* Inspect account_type values (should show 6 categories incl. "None")
tab account_type, miss

* ------------------------------------------------------------------
* 2. Create one binary indicator per account type (long format)
*    Using account_type string comparisons; "None" rows score 0 on all.
* ------------------------------------------------------------------
gen byte has_mm          = (account_type == "Mobile Money")
gen byte has_bank        = (account_type == "Bank Account")
gen byte has_online_bank = (account_type == "Online Bank Account")
gen byte has_sacco       = (account_type == "SACCO Account")
gen byte has_vsla        = (account_type == "VSLA Account")
gen byte has_mfi         = 0   // No MFI accounts present in this dataset

* Quick sanity check – counts should match raw tab above
tab has_mm
tab has_bank
tab has_online_bank
tab has_sacco
tab has_vsla

* ------------------------------------------------------------------
* 3. Destring numeric variables before collapsing
* ------------------------------------------------------------------
destring weight age hh_members account_num, replace force

* ------------------------------------------------------------------
* 4. Collapse to one row per participant
*
*    - Account-type dummies  → max()    : 1 if any account row = that type
*    - All other variables   → firstnm(): first non-missing value within hhid
*      (safe because all participant-level vars are constant within hhid)
*    - start_time / end_time are intentionally omitted (row-level timestamps)
* ------------------------------------------------------------------
collapse                                                        ///
    (max)     has_mm has_bank has_online_bank has_sacco has_vsla has_mfi  ///
    (firstnm) weight district urban gender age hh_members                 ///
              highest_grade_completed mm_account_cancelled                 ///
              prefer_cash mm_trust mm_account_telco mm_account_telco_main  ///
              v234 agent_trust v236 v237 v238 v240 v241 v242 v243 v244     ///
              v245 v246                                                     ///
    , by(hhid)

* ------------------------------------------------------------------
* 5. Add a summary count: number of distinct account types held
* ------------------------------------------------------------------
gen total_accounts = has_mm + has_bank + has_online_bank + ///
                     has_sacco + has_vsla + has_mfi

* ------------------------------------------------------------------
* 6. Label all variables
* ------------------------------------------------------------------
label variable hhid               "Household ID"
label variable weight             "Sampling weight"
label variable district           "District of household"
label variable urban              "Location: Urban or Rural"
label variable gender             "Gender"
label variable age                "Age (years)"
label variable hh_members         "Number of household members"
label variable highest_grade_completed "Highest grade completed"
label variable mm_account_cancelled    "Has cancelled a mobile money account (yes/no)"
label variable prefer_cash             "Prefers cash over cashless payments (yes/no)"
label variable mm_trust                "Trusts mobile money (yes/no)"
label variable mm_account_telco        "Mobile money providers (multi-select)"
label variable mm_account_telco_main   "Main mobile money provider"
label variable v234   "Understood T&Cs when registering (yes/no)"
label variable agent_trust   "Trusts mobile money agents (yes/no)"
label variable v236   "Ever taken a mobile money loan (yes/no)"
label variable v237   "Ever had network unavailability issues (yes/no)"
label variable v238   "Clear about fees before transacting (yes/no)"
label variable v240   "Has ever had a failed transaction (yes/no)"
label variable v241   "Agent ever lacked cash/efloat (yes/no)"
label variable v242   "Has copy of mobile money T&Cs (yes/no)"
label variable v243   "Knows how/where to complain (yes/no)"
label variable v244   "Has had a complaint successfully resolved (yes/no)"
label variable v245   "Understands data collected by MM providers (yes/no)"
label variable v246   "Has been a victim of fraud (yes/no)"
label variable has_mm           "Has mobile money account (1=yes)"
label variable has_bank         "Has bank account (1=yes)"
label variable has_online_bank  "Has online bank account (1=yes)"
label variable has_sacco        "Has SACCO account (1=yes)"
label variable has_vsla         "Has VSLA account (1=yes)"
label variable has_mfi          "Has MFI account (1=yes) [none in dataset]"
label variable total_accounts   "Total number of distinct account types held"

* ------------------------------------------------------------------
* 7. Verification checks
* ------------------------------------------------------------------
di "Observations after reshape: " _N    

* Distribution of total account holdings per participant
tab total_accounts, miss

* Spot-check first 15 participants
list hhid has_mm has_bank has_sacco has_vsla has_online_bank ///
         total_accounts district urban in 1/15

* ------------------------------------------------------------------
* 8. Declare survey design for all subsequent weighted analysis
*    (No cluster variable provided in this dataset)
* ------------------------------------------------------------------
svyset _n [pweight=weight]

* ------------------------------------------------------------------
* 9. Save reshaped dataset — will be the input for Tasks 2–5
* ------------------------------------------------------------------
save "laterite_wide.dta", replace
di "Dataset saved as laterite_wide.dta — ready for Tasks 2–5."

log close
