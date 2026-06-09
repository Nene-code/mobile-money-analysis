# Mobile Money Analysis — Rwanda

Stata-based analytical assessment examining mobile money usage and financial inclusion patterns using survey data from Rwanda.

## Repository Structure

```
mobile-money-analysis/
├── data/
│   ├── laterite_mobilemoney_data.csv   # Raw survey data
│   └── laterite_wide.dta               # Wide-format Stata dataset
└── do-files/
    ├── laterite_task1.do               # Task 1: Data reshaping (wide to long)
    ├── laterite_task2.do               # Task 2: Financial inclusion dummy variables
    ├── laterite_task3.do               # Task 3: Market structure analysis
    ├── laterite_task4.do               # Task 4: Failed transaction rate testing
    └── laterite_task5.do               # Task 5: Logistic regression on account cancellation
```

## Analysis Overview

| Task | Description |
|------|-------------|
| 1 | Reshape wide-format data to long format for panel analysis |
| 2 | Construct financial inclusion dummy variables |
| 3 | Analyse mobile money market structure across providers |
| 4 | Test for differences in failed transaction rates |
| 5 | Logistic regression modelling of account cancellation predictors |

## Requirements

- Stata 16 or higher
- Standard Stata libraries (no external packages required)

## Data Source

Survey data collected by [Laterite](https://www.laterite-africa.com/), a research firm specialising in data collection and analytics across Sub-Saharan Africa.
