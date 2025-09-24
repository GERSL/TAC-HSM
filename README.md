# TAC–HSM 

This repository hosts code, data workflows, and figures for validating the relationship between **lag-1 Temporal Autocorrelation (TAC)** derived from satellite vegetation indices and **Hydraulic Safety Margin (HSM)** measured in the field.  
The project examines how **resistance** (hydraulic traits) and **resilience** (recovery speed, captured by 1-TAC) are linked across Amazonian forests.

---

## 📖 Background

- **Resilience Indicator (TAC):**  
  TAC is widely used as a proxy for ecosystem resilience. Increas in TAC values suggest reduced recovery speed and greater risk of tipping points.  
- **Resistance Trait (HSM):**  
  HSM is calculated from field hydraulic traits, e.g., the difference between the minimum observed stem water potential (Pmin) and the xylem pressure at 50% conductivity loss (P50).  
- **Hydrological Modulation (CWD):**  
  Long-term water balance (precipitation – evapotranspiration) influences how resistance translates into resilience.  

By integrating field datasets with satellite TAC time series, we provide mechanistic evidence linking resistance and resilience, and test how this relationship varies with hydrological background.

---

## Repository Structure

```plaintext
TAC-HSM/
├── data/                       # Input datasets (not tracked in Git if large)
│   ├── Hydraulic_traits_dataset_TAVARES_et_al_2023.csv
│   ├── Plot_data_TAVARES_et_al_2023.csv
│   ├── enhancedTAC.csv
│   └── README_data.md          # Notes on data sources, formats, and preprocessing
│
├── scripts/                    # Analysis scripts
│   ├── matlab/                 # MATLAB code
│   │   ├── R2_bootstrap.m
│   │   ├── HSM_TAC_regression.m
│   │   └── plot_geospatial.m
│   │
│   └── python/                 # Python code
│       ├── plot_relationships.py
│       ├── preprocess_data.py
│       └── utils.py
│
├── results/                    # Processed outputs
│   ├── regression_results.csv
│   ├── bootstrap_R2_summary.csv
│   └── model_selection_AIC.csv
│
├── figures/                    # Figures for paper / presentations
│   ├── Fig1_TAC_HSM_relationship.png
│   ├── Fig2_R2_heatmap.png
│   └── example_relationship.png
│
├── docs/                       # Documentation, notes, manuscripts
│   ├── methods_notes.md
│   └── references.bib
│
├── .gitignore                  # Ignore temp/large files (e.g., *.mat, *.asv, __pycache__/)
├── LICENSE                     # License file (MIT/Apache 2.0/etc.)
├── requirements.txt            # Python dependencies
├── README.md                   # Project overview
└── CITATION.cff                # Citation metadata for GitHub

└── README.md # Project overview


