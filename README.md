# Optimised, cardiorespiratory state, trace eyeblink conditioning: analysis code

MATLAB/FieldTrip code for:

> Santhana Gopalan, P. R., & Nokia, M. S. Optimised cardiorespiratory state at tone onset enhances sensory responses but not associative learning in healthy adults. *Manuscript under review, European Journal of Neuroscience.* Preprint: https://doi.org/10.31234/osf.io/36qbz_v1

Code DOI: will be added after the Zenodo release

## Overview

Young (n = 41) and older (n = 19) adults first completed a passive auditory task (~450 tones) while EEG, ECG and respiration were recorded. For each participant, the cardiorespiratory state (inspiration/expiration x systole/diastole) at which the tone evoked the largest composite N1-P2 response was identified. Participants then underwent trace eyeblink conditioning (TEBC) with the tone-CS timed either to their optimal state (Personalised, n = 31) or to diastole during expiration (Control, n = 29).

The code:

1. determines the cardiorespiratory state at tone onset and the composite N1-P2 per state in the passive task,
2. computes the CS-evoked N1-P2 and theta-band time-frequency measures during TEBC,
3. scores conditioned eyeblinks from EMG and derives the learning measures,
4. computes heart and breathing rate.

Statistics were run in IBM SPSS Statistics 30 and JASP 0.98.1 on the exported tables, and the sensitivity power analysis in G*Power 3.1.9.7. These steps are not part of this repository.

## Requirements

- MATLAB (R2022b or later) with the Signal Processing and Statistics toolboxes
- FieldTrip (20230427; the time-frequency analysis was run with 20251218)
- EEGLAB with the ICLabel plugin (preprocessing step 0)

## Data

Participant data are not included. They are available from the corresponding author on reasonable request.

## Usage

Edit the paths at the top of `tebc_config.m`, then run the scripts in order. Scripts marked *interactive* ask you to confirm each automatically detected peak and let you click the peaks if needed.

**Step 0, EEGLAB (not scripted).** Continuous EEG from both sessions was visually inspected and noisy channels were interpolated in EEGLAB. FastICA was run, and components reflecting ocular, line-noise, movement and cardiac artifacts were identified with ICLabel and removed. The cleaned data were saved as `.set` files, which are the input to the scripts below.

| Script | Step | Manuscript |
|---|---|---|
| `01_passive_task/s01_epoch_passive.m` | 1-30 Hz, epochs -200 to 1000 ms, baseline, rejection, average reference | 2.4.2 |
| `01_passive_task/s02_cardioresp_state.m` | Respiration and cardiac phase at tone onset | 2.4.1 |
| `01_passive_task/s03_state_n1p2.m` | Composite N1-P2 per state, optimal state (*interactive*) | 2.4.2, Fig. 2A |
| `01_passive_task/s04_optimal_state_stats.m` | Distribution of optimal states, relative maximum | 3.2, Fig. 2B |
| `01_passive_task/s05_split_half.m` | Split-half optimal state, per participant (*interactive*) | 3.2 |
| `01_passive_task/s06_split_half_stats.m` | Agreement, Cohen's kappa, split-half correlations | 3.2 |
| `02_tebc_eeg/s07_tebc_erp.m` | CS-evoked ERPs, epochs -100 to 500 ms | 2.6.2.1 |
| `02_tebc_eeg/s08_tebc_n1p2.m` | Composite N1-P2 during TEBC (*interactive*) | 2.6.2.1, 3.3, Fig. 3 |
| `02_tebc_eeg/s09_cs_timing_check.m` | ECG and respiration around each CS onset | 2.5, 3.3 |
| `02_tebc_eeg/s10_tf_analysis.m` | Wavelet ITC, total, evoked and induced power | 2.6.2.2 |
| `02_tebc_eeg/s11_tf_metrics_stats.m` | Theta ITC and induced power, ANOVAs, regression | 3.3 |
| `03_conditioning/s12_cr_scoring.m` | EMG envelope and CR scoring per trial | 2.7 |
| `03_conditioning/s13_conditioning_measures.m` | CR% per block, peak performance, good learners, learning rate, strict sample | 2.7, 3.4, Fig. 4 |
| `04_physiology/s14_heart_and_breathing_rate.m` | Heart and breathing rate per session | 2.6.1, 3.1 |

`functions/` contains the trial definitions (`tone_times.m`, `tebcerp.m`, `emgtrial.m`), artifact rejection and the N1-P2 peak routines. `tools/` contains `recover_systole_cutoffs.m` and `combine_split_recording.m` (for one TEBC recording saved in two parts).

## Key parameters

All parameters are set in `tebc_config.m`.

- **Region of interest:** electrodes 6, 7 and 106 (fronto-central).
- **Artifact rejection:** epoch rejected if peak-to-peak exceeds 300 µV in any channel, or 175 µV in more than 25 channels.
- **Respiration phase:** `angle(hilbert(resp))` at tone onset, rounded to two decimals. Negative phase (-π to 0) = inspiration, positive (0 to π) = expiration.
- **Cardiac phase:** time from the preceding R-peak to tone onset. Up to the participant's systole cutoff = systole, later = diastole.
- **Composite N1-P2:** [(a - b) + (c - b)] / 2, with a = first positive peak, b = N1 trough, c = P2 peak.
- **Time-frequency:** epochs -1000 to 1000 ms, 1-30 Hz, 50 Hz notch, baseline -300 to -50 ms, 3-cycle wavelets 4-15 Hz. Theta = 5-10 Hz, 80-300 ms after CS onset.
- **Conditioned responses:** EMG high-pass 60 Hz, rectified, low-pass 20 Hz (8th-order two-pass Butterworth). Threshold = baseline mean + 2.5 SD. Bad trial = blink in the 200 ms before CS onset. CR = blink 600-800 ms after CS onset.

## Notes on implementation details

- **Systole cutoffs.** The systole/diastole cutoff was set for each participant by inspecting the R-peak-locked mean ECG waveform, scaled to the participant's mean inter-beat interval. `s02` asks for the cutoff of each participant.
- **Peak detection.** In the passive task, a, b and c are the first positive peak after tone onset, the following trough and the following peak (at least 75 ms apart). During TEBC they are searched within 50-120, 80-160 and 150-250 ms. In both cases every waveform was visually verified and corrected by hand where needed.
- **Split-half test.** Trials are split at random, and peaks are verified by hand, so a rerun gives a new split. The seed of each split is saved in the output file.
- **CS timing check.** `s09` plots ECG and respiration around each CS onset. The state at each onset was classified visually from these figures.
- **Online gating during TEBC** was done in LabVIEW from amplitude-based respiratory criteria and real-time R-peak detection. That software is not part of this repository.
- **Strict sample.** Bad-trial percentage is computed over all 60 CS trials. Pre-conditioning blinks are counted from the CR percentage in the first five CS-alone trials.

## Citation

If you use this code, please cite the article above and this repository (see `CITATION.cff`).

## License

MIT, see `LICENSE`.

## Contact

Praghajieeth Raajhen Santhana Gopalan, University of Jyväskylä (ORCID [0000-0003-4244-485X](https://orcid.org/0000-0003-4244-485X))
