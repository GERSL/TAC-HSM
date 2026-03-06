# TAC–HSM 

This repository hosts code, data workflows, and figures for investigating the ecophysiological relationship between **lag-1 Temporal Autocorrelation (TAC)** derived from satellite vegetation indices and **Hydraulic Safety Margin (HSM)** measured in the field. The project examines how **resistance** (indicated by HSM) and **resilience** (recovery speed, indicated by 1-TAC) are linked across Amazonian forests.

---

## 📖 Background

- **Resilience Indicator (TAC):**  
  TAC is widely used as a proxy for ecosystem resilience. Increas in TAC values suggest reduced recovery speed and greater risk of tipping points.  
- **Resistance Trait (HSM):**  
  HSM is calculated from field hydraulic traits, e.g., the difference between the minimum observed stem water potential (Pmin) and the xylem pressure at 50% conductivity loss (P50).  
- **Climate water deficit (CWD):**  
  Long-term water excess (precipitation – evapotranspiration) influences how resistance translates into resilience.  

By integrating field datasets with satellite TAC time series, we provide mechanistic evidence linking resistance and resilience, and test how this relationship varies with hydrological background.

---

## Repository Structure
```plaintext
TAC-HSM/
├── COLD_v2/                       # Harmonic model for time series fitting (analysis)
├── ClimateData/                   # ERA5-Land data stored in the Google drive (for RFmodel inputs)
├── Data/                          # Project data directory (satellite + hydraulic traits)
├── ForestCover/                   # Forest cover maps and tables (preprocessing)
├── GEE-LandsatTimeSeries/         # Google Earth Engine workflows for Landsat time-series extraction (downloading)
├── HPCJobs/                       # HPC batch/SLURM job scripts for large-scale processing
├── HSM_TAC_Correlation/           # Linking TAC metrics with HSM (core analysis)
├── Input/                         # Input tables (samples/coordinates/lookup tables used by pipelines)
├── L57_L89_Harmonization/         # Harmonization workflows across Landsat 5/7/8/9 to enhance data consistency (preprocessing)
├── Others/                        # Other supporting scripts
├── Plot/                          # Plotting/figure scripts (paper figures, diagnostics)
├── RFmodel/                       # Random Forest for excluding climate autocorrelation's impact on TAC (analysis)
├── TAC/                           # TAC computation code (analysis)
├── c_factor_brdf_python/          # BRDF correction (c-factor approach) implemented in Python (preprocessing)
├── enhancedTAC_gap_filling_test/  # Experiments/tests results for HSM_TAC_Correlation
├── Tests/                         # Simple test csv file and test.m for estimating TAC
│
├── LICENSE                         # MIT license
├── CONTRIBUTING.md                 # Contribution and reuse policy
└── README.md                       # Project overview (this file) Legacy notes / additional documentation
```

Note: All scripts were tested with MATLAB R2023b and Python 3.11. Dependent Python packages are listed in ./GEE-LandsatTimeSeries/environment.yml and ./c_factor_brdf_python/environment.yml
  
---

## Workflow Overview 
(More instructions can be found in the **run_pipeline.txt**)

1. Satellite Time-Series Processing
- Landsat surface reflectance and TOA reflectance extraction via GEE
- BRDF correction
- Cross-sensor harmonization

2. Observed TAC Computation
- Harmonic modeling (COLD framework)
- Residual extraction (detrend and deseasonality)
- Compositing and gap-filling
- Lag-1 TAC calculation

3. Enhanced TAC Computation
- Prepare predictor and response variables for random forest models
- Random forest regression model training and validating
- Calculate enhanced TAC

4. TAC-HSM Correlation Analysis
- Link spatial-aggregated TAC with plot-level HSM 
- Regression model evaluation with AIC
- Figure generation

### Download ./Tests for an example run!
---

## License
This project is licensed under the MIT License. See the LICENSE file for details.

---

## Contributing
Please see CONTRIBUTING.md for reuse guidelines, maintenance plans, and contribution standards.

---




