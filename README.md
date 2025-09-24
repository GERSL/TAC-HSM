# 🌱 TAC–HSM 

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

## 📂 Repository Structure
TAC-HSM/
├── data/ # Input datasets (field traits, TAC timeseries, climate forcing)
│ ├── Hydraulic_traits_dataset_TAVARES_et_al_2023.csv
│ ├── Plot_data_TAVARES_et_al_2023.csv
│ ├── enhancedTAC.csv
│ └── ...
├── scripts/ # MATLAB/Python scripts for data processing and analysis
│ ├── HSM_TAC_regression.m
│ └── plot_relationships.py
│ └── readme.txt # Code overview
├── figures/ # Generated figures for publication
├── results/ # Processed outputs (regression coefficients, R² values, bootstraps)
└── README.md # Project overview


