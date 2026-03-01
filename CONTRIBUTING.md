# Contributing to TAC--HSM

Thank you for your interest in contributing to **TAC--HSM**.

This repository supports research linking **satellite-derived Temporal
Autocorrelation (TAC)** with **Hydraulic Safety Margin (HSM)** to assess
forest resilience. Because this codebase underpins active and published
scientific research, contributions must prioritize reproducibility,
clarity, and stability.

------------------------------------------------------------------------

## Guiding Principles

This project values:

-   Reproducibility of scientific results\
-   Transparency of methods\
-   Cross-sensor consistency (Landsat 5/7/8/9)\
-   Clear separation of preprocessing, TAC computation, and statistical
    analysis\
-   Computational scalability (HPC workflows)

Changes that affect analytical logic or published results must be
clearly documented.

------------------------------------------------------------------------

## How to Contribute

### 1. Fork and Clone

Fork the repository and clone your fork locally:

``` bash
git clone https://github.com/your-username/TAC-HSM.git
cd TAC-HSM
```

------------------------------------------------------------------------

### 2. Create a Branch

Create a descriptive branch:

``` bash
git checkout -b feature/your-feature-name
```

Examples:

-   bugfix/angle-merge\
-   feature/sentinel-support\
-   docs/update-readme\
-   refactor/brdf-module

Avoid committing directly to `main`.

------------------------------------------------------------------------

### 3. Code Standards

#### Python Code

-   Follow PEP8 style\
-   Avoid hard-coded file paths\
-   Separate I/O from computation where possible\
-   Keep BRDF and kernel logic modular\
-   Document any changes affecting reflectance correction

#### MATLAB Code

-   Do not modify driver scripts (`runTAC_*.m`) without discussion\
-   Preserve numerical behavior of TAC calculations\
-   Clearly comment algorithmic changes\
-   Avoid introducing undocumented dependencies

------------------------------------------------------------------------

### 4. Reproducibility Requirements

Before submitting a pull request:

-   Ensure scripts run without breaking existing workflows\
-   Verify outputs are consistent on a small test dataset\
-   Clearly indicate if changes alter:
    -   TAC calculation\
    -   BRDF correction\
    -   Harmonization logic\
    -   Statistical outputs

If a contribution changes published results, this must be explicitly
stated.

------------------------------------------------------------------------

### 5. Data Policy

Do **not** commit:

-   Raw Landsat imagery\
-   Large CSV outputs\
-   Raster files\
-   HPC output directories\
-   Files larger than \~10 MB

Use `.gitignore` appropriately.

The repository contains code --- not raw satellite data.

------------------------------------------------------------------------

### 6. Submitting a Pull Request

Include:

-   A clear summary of what changed\
-   The motivation for the change\
-   Whether scientific results are affected\
-   Any new dependencies introduced\
-   Example commands to test the update

Well-documented pull requests are more likely to be merged.

------------------------------------------------------------------------

## Reuse Policy

This project is licensed under the **MIT License**.

You are free to:

-   Use the code\
-   Modify the code\
-   Redistribute the code\
-   Use it commercially

You must:

-   Retain the license\
-   Provide attribution

If you use TAC--HSM in academic work, please cite the associated
publication.

------------------------------------------------------------------------

## Versioning and Stability

We recommend semantic versioning for stable releases:

-   v1.x.x --- Published paper-aligned versions\
-   v2.x.x --- Major structural updates\
-   Minor updates should not change scientific results

Major structural refactors require discussion via GitHub Issues.

------------------------------------------------------------------------

## Reporting Issues

When opening an issue, please include:

-   Script or module name\
-   Full error message\
-   Operating system\
-   Python / MATLAB version\
-   Minimal reproducible example (if possible)

Clear issue reports help maintain scientific integrity.

------------------------------------------------------------------------

## Maintenance

TAC--HSM is maintained by:

**Global Environmental Remote Sensing Laboratory (GERSL)**

Maintenance priorities:

1.  Reproducibility of published results\
2.  Stability of TAC computation\
3.  Cross-sensor harmonization consistency\
4.  Clear modular workflow

------------------------------------------------------------------------

## Questions or Collaboration

For scientific collaboration or technical questions, please open an
Issue or contact the repository maintainers.
