# Developmental divergence in voice-reward circuitry differentiates autistic from typically developing children and adolescents

**Publication:** Abrams, D.A., Leipold, S., Odriozola, P., Baker, A.E., Padmanabhan, A., Phillips, J.M., & Menon, V. (2026). Developmental divergence in voice-reward circuitry differentiates autistic from typically developing children and adolescents. *Proceedings of the National Academy of Sciences.*

**Authors:** Daniel A. Abrams<sup>1,2</sup>, Simon Leipold<sup>4,5</sup>, Paola Odriozola<sup>1</sup>, Amanda E. Baker<sup>1</sup>, Aarthi Padmanabhan<sup>1</sup>, Jennifer M. Phillips<sup>1</sup>, and Vinod Menon<sup>1–3</sup>

**Affiliations:**
1. Department of Psychiatry and Behavioral Sciences, Stanford University School of Medicine, Stanford, CA 94305, USA
2. Wu Tsai Neurosciences Institute, Stanford University School of Medicine, Stanford, CA 94305, USA
3. Department of Neurology and Neurological Sciences, Stanford University School of Medicine, Stanford, CA 94305, USA
4. Social Brain Sciences Lab, Department of Humanities, Social and Political Sciences, ETH Zurich, Switzerland
5. Neuroscience Center Zurich, University of Zurich and ETH Zurich, Switzerland

**Corresponding Author:** Daniel A. Abrams, Ph.D. — daa@stanford.edu

> **Note to depositors:** The sections marked `[INSERT FROM MANUSCRIPT]` below should be filled in with verbatim language from the final published manuscript before public release.

---

## Abstract

*[INSERT FROM MANUSCRIPT]*

---

## Repository Contents

A full step-by-step description of all analyses — including preprocessing commands, exclusion decisions, groupmatching procedures, and script locations — is documented in:

> `docs/ASD_CrossSectional_Voice_Processing_ELN_FINAL.docx`

---

## Repository Structure

```
.
├── docs/
│   └── ASD_CrossSectional_Voice_Processing_ELN_FINAL.docx
├── subjectlist/
└── scripts/
    ├── groupmatch/
    ├── Demographics_Analysis/
    ├── Acoustical/
    │   ├── Compute_AcousticalFeatures/
    │   └── Compute_Duration_Raw_MothersVoiceStim/
    ├── MothersVoice_Identification_Task/
    └── taskfmri/
        ├── movement_analysis/
        ├── taskdesign/
        ├── individualstats/
        ├── groupstats/
        └── gPPI/
            └── TripleNetwork/
                └── nrunwise/
```

---

## Analysis Pipeline

### Preprocessing

**Initial sample:** N = 41 ASD subjects, N = 46 TD subjects

**Preprocessing MRI**

Sherlock command: `mlsubmit preprocessmri.m a1_preprocessmri_config.m`

**Preprocessing fMRI**

Sherlock command: `mlsubmitSL preprocessfmri.m a2_preprocessfmri_config.m`

> *note: mlsubmitSL accesses the scripts I adapted to handle the unequal # runs/subject info in FullSample_RunList.mat*

Visual inspection of swgcarI.nii's confirmed successful normalization and correct orientation for all subj/runs.

---

### Motionstats

Sherlock scripts: `scripts/taskfmri/movement_analysis/configs/[...]`

- `step1_createconfigs.sh`
- `step2_runconfigs.txt`
- `step3_collectmotion.sh`

Output: `movestats_RunX_compiled.txt` within movement_analysis folder

---

### Taskdesign

Sherlock command: `mlsubmitSL taskdesign_m2mat.m taskdesign_m2mat_config_SL.m`

Script: `task_design_collapsed.m`

**Contrasts**

1. `'mother_min_environ'`
2. `'environ_min_mother'`
3. `'others_min_environ'`
4. `'environ_min_others'`
5. `'cont1_min_environ'`
6. `'environ_min_cont1'`
7. `'cont2_min_environ'`
8. `'environ_min_cont2'`
9. `'mother_min_other'`
10. `'other_min_mother'`
11. `'speech_min_environ'`
12. `'environ_min_speech'`
13. `'cont1_min_cont2'`
14. `'cont2_min_cont1'`
15. `'mother_min_cont1'`
16. `'cont1_min_mother'`
17. `'mother_min_cont2'`
18. `'cont2_min_mother'`

---

### Individual Stats

Sherlock command: `mlsubmitSL individualstats_glm.m individualstats_config_SL.m`

---

### Groupmatching

**ASD Group:** 7729,1,1 excluded because FIQ and PIQ < 80; leaving N = 40 ASD to be matched with N = 40 TD

**Genetic algorithm**

Sherlock command: `mlsubmit subjselect.m subjselect_config2.m`

Matching on Sex, IQ, and fMRI Total Motion

**DA NOTE:** 7750 excluded because we could not locate ADOS.

**FINAL Subjectlists for second-level analyses:**
- `ASD_selected_PID_List_n39_ADOS.csv`
- `TD_selected_PID_List.csv`

---

### Second Level — GLM (ASD: n=39; TD: n=40)

#### TD vs ASD: Group x Age

**Voxelwise Whole Brain Analysis in SPM12**

**GLM: Group x Age Analysis — Main Text Figures 2-3**

Script: `GLM_two_sample_AGEcov_ASD_TD_n39_40.m`

Sherlock command: `mlsubmit groupstats.m GLM_two_sample_AGEcov_ASD_TD_n39_40.m`

Thresholding for all Group Stats: `mlsubmit export_spmresults.m export_0_005.m -p dev -c 2 -m 8G -t 1:00:00`

> NOTE: Verified equivalence between original Menon lab group stats and explicit two-age-covariate model for voxelwise analyses; unthresholded contrast images matched exactly.

**GLM: Within TD Group Age Covariate Analysis — Figures S1-S3 (TD: n=40)**

Voxelwise Whole Brain Analysis in SPM12

Script: `GLM_TD_only.m`

Sherlock command: `mlsubmit groupstats.m GLM_TD_only.m`

**GLM: Within ASD Group Age Covariate Analysis — No Significant Results or Figures (ASD: n=39)**

Voxelwise Whole Brain Analysis in SPM12

Script: `GLM_ASD_only_n39.m`

Sherlock command: `mlsubmit groupstats.m GLM_ASD_only_n39.m`

**Scatter plots for Main Text Figures 2-3**

Scatter plots STEP #1: Sherlock: Signal Level Extraction based on peaks in the TD vs ASD group comparison for the Age covariate analysis (`scripts/taskfmri/groupstats/glm_covar/signal_extraction_DA/ROI_Signal_Extract/`)

Scatter plots STEP #2: Local Matlab: Plot Individ Partic Signal Levels (`scripts/taskfmri/groupstats/glm_covar/signal_extraction_DA/Plot_Scatters_Compare_Lines/Scatterplots/`)

> NOTES: These scripts include compute Cohen's f which is embedded in the script. Scatter plot figure generation scripts were run on my local computer whose image quality is better than generating on Sherlock. I have uploaded these scripts for documentation purposes.

**ROI-Level GLMs on Voxelwise Results — Table S2 and S3**

Scripts: `scripts/taskfmri/groupstats/glm_covar/signal_extraction_DA/TD_ASD_ROI_SigLevel_GLM_n40_n39/Scripts/`

> NOTE: ROI-level GLMs were run on my local computer using Matlab. I have uploaded these scripts for documentation purposes.

**Cross-Validation on Voxelwise Results — Table S2 and S3**

Scripts: `scripts/taskfmri/groupstats/glm_covar/Confirmatory_SVR_SigLevels_Age/`

> NOTE: Cross-validation analysis was run on Sherlock.

---

### gPPI Analysis

#### First level — gPPI

gPPI individual stats for bilateral pSTS seeds were run by Simon as a part of his initial gPPI analysis that seeded all regions included in the *eLife* (2019) gPPI analysis.

Script: `scsnl_gPPI_auto_config_elife19.m`

Sherlock command: `mlsubmit scsnl_gPPI_auto_SL_t.m scsnl_gPPI_auto_config_elife19.m`

**ROI Info:** Bilateral pSTS ROIs for whole brain gPPI Analysis — coordinates are from Belin et al, Nature (2000); same coordinates used in Abrams et al PNAS (2013) and eLife (2019)

| Brain region | Coordinates | Radius |
|---|---|---|
| Left-hemisphere pSTS | [−63 −42 9] | 5 mm |
| Right-hemisphere pSTS | [57 −31 5] | 5 mm |

> **Note:** The first-level gPPI script (`scsnl_gPPI_auto_config_elife19.m`) is not included in this repository. It was run as part of a prior analysis pipeline. See the ELN for details.

#### Second level — gPPI (ASD: n=39; TD: n=40)

##### TD vs ASD: Group x Age

**gPPI: Group x Age Analysis — Main Text Figures 4-6 and SI Figs S6 and S10 (ASD: n=39; TD: n=40)**

gPPI Whole Brain Analysis in SPM12

Scripts (`scripts/taskfmri/groupstats/gppi_covar/`):
- Left pSTS Seed: `gPPI_two_sample_cov_ASD_TD_left_pSTS_n39_n40.m`
- Right pSTS Seed: `gPPI_two_sample_cov_ASD_TD_right_pSTS_n39_n40.m`

**Scatter plots for Main Text Figures 4-6 and SI Figs S6 and S10**

Scatter plots STEP #1: Sherlock: Signal Level Extraction based on peaks in the TD vs ASD group comparison for the Age covariate analysis (`scripts/taskfmri/groupstats/gppi_covar/signal_extraction_DA/ROI_Signal_Extract/`)

Scatter plots STEP #2: Local Matlab: Plot Individ Partic Signal Levels (`scripts/taskfmri/groupstats/gppi_covar/signal_extraction_DA/Plot_Scatters_Compare_Lines/Scripts/`)

**ROI-Level GLMs on gPPI Results — Tables S4-S6**

Scripts: `scripts/taskfmri/groupstats/gppi_covar/signal_extraction_DA/Plot_Scatters_Compare_Lines/Scripts/`

> NOTE: ROI-level GLMs were run on my local computer using Matlab. I have uploaded these scripts for documentation purposes.

**Cross-Validation on gPPI Results — Tables S4-S6**

Scripts: `scripts/taskfmri/groupstats/gppi_covar/signal_extraction_DA/Confirmatory_SVR_gPPI_SigLevels_Age/`

> NOTE: Cross-validation analysis was run on Sherlock.

##### Age x Social Communication within ASD Group

This covers Main Text Figure 7, which includes both Voxelwise and gPPI analyses.

**Second level - GLM (ASD: n=39): Main Text Figure 7a**

Voxelwise Whole Brain Analysis in SPM12

Script: `GLM_one_sample_Age_ADOS_Interact_ASDonly.m`

Scatter plots STEP #1: Sherlock: Signal Level Extraction based on peaks in the ASD SC X Age Voxelwise interaction (`scripts/taskfmri/groupstats/glm_covar/signal_extraction_DA/ROI_Signal_Extract/`)

Scatter plots STEP #2: Local Matlab: Plot Individ Partic Signal Levels (`scripts/taskfmri/groupstats/glm_covar/signal_extraction_DA/GLM_gPPI_Scatters_Age_SC_Interaction_ASD_n39/Scripts/`)

> NOTE: Scatter plot figure generation scripts were run on my local computer whose image quality is better than generating on Sherlock. I have uploaded these scripts for documentation purposes.

**Second level - gPPI (ASD: n=39): Main Text Figure 7b**

gPPI Whole Brain Analysis in SPM12

Scripts (`scripts/taskfmri/groupstats/gppi_covar/one_sample_t_ASD_age_and_SocComm/eLife19/`):
- Left pSTS Seed: `gPPI_ASD_only_left_pSTS_Age_SC_Interaction.m`
- Right pSTS Seed: `gPPI_ASD_only_right_pSTS_Age_SC_Interaction.m`

Scatter plots STEP #1: Sherlock: Signal Level Extraction based on peaks in the ASD SC X Age gPPI interaction (`scripts/taskfmri/groupstats/gppi_covar/signal_extraction_DA/ROI_Signal_Extract/ASD_Only_Age_SC_Interact_Covar/`)

Scatter plots STEP #2: Local Matlab: Plot Individ Partic Signal Levels (`scripts/taskfmri/groupstats/glm_covar/signal_extraction_DA/GLM_gPPI_Scatters_Age_SC_Interaction_ASD_n39/Scripts/`)

> NOTE: Scatter plot figure generation scripts were run on my local computer whose image quality is better than generating on Sherlock. I have uploaded these scripts for documentation purposes.

---

### Acoustical Analysis of Mother's Voice: Figure 1b

> NOTE: These analyses were performed on a local Matlab computer — the paths would need to be changed to re-run scripts

**Compute mean duration of all raw Mother's Voice stim and percentage of duration change required for normalization**

Script: `scripts/Acoustical/Compute_Duration_Raw_MothersVoiceStim/Compute_Duration_Stim.m`

**Compute acoustical features of Mother's Voice stim (Praat scripts): Main Figure 1b**

Scripts: `scripts/Acoustical/Compute_AcousticalFeatures/`
- TDs: `Load and Analyze All ASD Mothers Voices and Control Moms TD n40`
- ASDs: `Load and Analyze All TD Mothers Voices and Control Moms TD n40`

**Plot 3 acoustical (pitch) features of Mother's Voice stim and GLM to compute interaction Group x Age (Matlab scripts): Main Figure 1b**

Script: `scripts/Acoustical/Compute_AcousticalFeatures/GLM_Interaction_Group_Age_For_All_Acoustical_Feature_39_40.m`

> NOTE: Scatter plot figure generation scripts were run on my local computer whose image quality is better than generating on Sherlock. I have uploaded these scripts for documentation purposes.

---

### Mother's Voice Identification Task: Figure 1c

> NOTE: These analyses were performed on a local Matlab computer — the paths would need to be changed to re-run scripts

1. Import behavioral data from EDAT (after EDAT was saved as a CSV)
   - Script: `scripts/MothersVoice_Identification_Task/REDO2_MothersVoice_ID_Import_and_IndividStats.m`

2. Examine Age x Group interactions for Mother's Voice Identification Accuracy and RT
   - Script: `scripts/MothersVoice_Identification_Task/REDO2_MothersVoice_ID_GroupAnalyses.m`

---

### Control Analyses

**Control Analysis #1: Acoustical Features influence on GLM and gPPI Results**

- Do acoustical features of the mother's voices stimuli influence group differences in age-related changes in voxelwise activity highlighted in Figure 2? **For results see Table S9**
  - Script: `scripts/Acoustical/Compute_AcousticalFeatures/GLM_ROI_Age_CovaryOut_Acoustics_MotherEnv.m`

- Do acoustical features of the mother's voices stimuli influence group differences in age-related changes in gPPI results highlighted in Figures 4 and 6? **For results see Table S10**
  - Mother minus Environment contrast (ie Figure 4): `scripts/Acoustical/Compute_AcousticalFeatures/gPPI_[Left/Right]_pSTS_ROI_Age_CovaryOut_Acoustics_MotherEnv.m`
  - Nonfamilial minus Mothers voice contrast (ie Figure 6): `scripts/Acoustical/Compute_AcousticalFeatures/gPPI_[Left/Right]_pSTS_ROI_Age_CovaryOut_Acoustics_MotherOth_POS.m`

**Control Analysis #2: Behavioral Accuracy from Mother's Voice ID influence on GLM and gPPI Results**

- Does behavioral accuracy influence group differences in age-related changes in voxelwise activity highlighted in Figure 2? **For results see Table S11**
  - Script: `scripts/MothersVoice_Identification_Task/GLM_ROI_Age_CovaryOut_Acoustics_MotherEnv.m`

- Does behavioral accuracy influence group differences in age-related changes in gPPI results highlighted in Figures 4 and 6? **For results see Table S12**
  - Mother minus Environment contrast (ie Figure 4): `scripts/MothersVoice_Identification_Task/gPPI_[Left/Right]_pSTS_ROI_Age_CovaryOut_Acoustics_MotherEnv.m`
  - Nonfamilial minus Mothers voice contrast (ie Figure 6): `scripts/MothersVoice_Identification_Task/gPPI_[Left/Right]_pSTS_ROI_Age_CovaryOut_Acoustics_MotherOth_POS.m`

**Control Analysis #3: Auditory Cortical Control Regions: Group x Age Interactions; See Table S13**

STEP #1: Sherlock: Signal Level Extraction based on ACx Regions (`scripts/taskfmri/groupstats/glm_covar/signal_extraction_DA/ROI_Signal_Extract/`)

STEP #2: Local Matlab: ROI-based GLMs of ACx Regions, including both Group x Age Interactions (see Table S13) and Within-group relationship with Age (see Table S14) (`scripts/taskfmri/groupstats/glm_covar/ACx_Control_GLM_Analysis/`)

---

### Demographic Analyses (see Table 1)

Scripts: `scripts/Demographics_Analysis/`

- **TD vs ASD Neuropsych Group Differences:** `ASD_Diagnostic_Age_Correlations_ADI.m`
- **TD vs ASD Neuropsych Group x Age Interaction:** `ASD_Diagnostic_Age_Correlations_ADI.m`
- **TD vs ASD Sex Differences:** `Sex_Ratio_Age_Analysis.m`
- **TD vs ASD Sex Ratio x Age Differences:** `ASD_Sex_Ratio_Age_Analysis.m`

---

## Notes on Path Configuration

Scripts reference absolute paths from Stanford's Sherlock HPC (`/oak/stanford/groups/menon/projects/leipold/2022_ASD_CrossDevelop/`). These paths would need to be changed to re-run scripts in a different environment.

---

## Data Availability

*[INSERT FROM MANUSCRIPT]*

---

## Citation

Abrams, D.A., Leipold, S., Odriozola, P., Baker, A.E., Padmanabhan, A., Phillips, J.M., & Menon, V. (2026). Developmental divergence in voice-reward circuitry differentiates autistic from typically developing children and adolescents. *Proceedings of the National Academy of Sciences.*
