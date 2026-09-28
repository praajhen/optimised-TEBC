function C = tebc_config()
% TEBC_CONFIG  Paths and analysis parameters used by all scripts.
% Edit the paths below before running anything.

%% Paths (edit these)
C.fieldtrip   = 'C:\toolboxes\fieldtrip-20230427';
C.raw_passive = 'C:\data\personalised_tebc\raw\auditory';   % PLxx_A.edf / PLexx_A.edf
C.raw_tebc    = 'C:\data\personalised_tebc\raw\TEBC';       % PLxx_TEBC.edf / PLexx_TEBC.edf
C.ica_passive = 'C:\data\personalised_tebc\ICA_cleaned\auditory'; % EEGLAB .set after ICA
C.ica_tebc    = 'C:\data\personalised_tebc\ICA_cleaned\TEBC';
C.work_dir    = 'C:\data\personalised_tebc\derivatives';

%% Setup
repo = fileparts(mfilename('fullpath'));
addpath(fullfile(repo, 'functions'));
addpath(C.fieldtrip);
ft_defaults;
C.fs = 1000; % Hz (NeurOne)

%% Region of interest (fronto-central)
C.roi = [6 7 106]; % HydroCel electrode numbers

%% Trial rejection (peak-to-peak, uV)
C.reject.low          = 175; % reject if more than max_channels exceed this ...
C.reject.max_channels = 25;
C.reject.high         = 300; % ... or any single channel exceeds this
C.reject.first_sample = 150;

%% Cardiorespiratory state at tone onset (passive task)
% Respiration: Hilbert phase, rounded to 2 decimals, split at 0 rad.
% Bin 1 (-pi..0) = inspiration, bin 2 (0..pi) = expiration.
C.resp.edges  = [-3.14 0 3.14];
C.resp.labels = {'INS', 'EXP'};
% Cardiac: R-peak detection and per-participant systole cutoff (ms after R-peak)
C.rpeak           = [600 500]; % MinPeakProminence, MinPeakDistance (samples)
C.cardiac.cutoffs = fullfile(C.work_dir, 'systole_cutoffs.csv'); % see tools/recover_systole_cutoffs.m
C.cardiac.labels  = {'SYS', 'DIA'};
C.states          = {'EXP-DIA', 'EXP-SYS', 'INS-DIA', 'INS-SYS'};

%% Composite N1-P2 = [(a - b) + (c - b)] / 2
% Passive task: first positive peak after tone onset (a), next trough (b),
% next positive peak (c); peaks at least 75 ms apart; visually verified.
C.peaks.min_dist = 0.075; % s
% TEBC: peaks searched within fixed windows (ms), visually verified.
C.peaks.win_a = [50 120];
C.peaks.win_b = [80 160];
C.peaks.win_c = [150 250];

%% Time-frequency (TEBC paired trials)
C.tf.foi      = 4:1:15;
C.tf.toi      = -0.30:0.01:0.50;
C.tf.width    = 3;
C.tf.baseline = [-0.30 -0.05];
C.tf.band     = [5 10];      % Hz, theta
C.tf.window   = [0.08 0.30]; % s after CS onset

%% Conditioning (EMG)
C.emg.hp = 60; C.emg.lp = 20; C.emg.order = 8;
C.emg.k          = 2.5;        % threshold = baseline mean + k * SD
C.emg.baseline   = [-500 0];   % ms
C.emg.bad_window = [-200 0];   % blink here = bad trial
C.emg.cr_window  = [600 800];  % adaptively timed CR
C.trials.cs_pre  = 1:5;        % CS-alone before conditioning
C.trials.paired  = 6:55;       % 50 CS-US trials
C.trials.cs_post = 56:60;      % CS-alone (extinction)

%% Training groups
C.personalised = {'PL01','PL02','PL03','PL06','PL09','PL11','PL13','PL15','PL17','PL20', ...
                  'PL21','PL23','PL24','PL26','PL29','PL30','PL31','PL36','PL37','PL38','PL41', ...
                  'PLe01','PLe03','PLe04','PLe06','PLe09','PLe11','PLe13','PLe14','PLe15','PLe18'};
C.control      = {'PL04','PL05','PL07','PL08','PL10','PL12','PL14','PL16','PL18','PL19', ...
                  'PL22','PL25','PL27','PL28','PL32','PL33','PL34','PL35','PL39','PL40', ...
                  'PLe02','PLe05','PLe07','PLe08','PLe10','PLe12','PLe16','PLe17','PLe19'};
end
