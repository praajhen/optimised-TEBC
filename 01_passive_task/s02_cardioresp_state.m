%% s02_cardioresp_state
% Cardiorespiratory state at tone onset for every accepted passive-task trial.
% Respiration: Hilbert phase, rounded to 2 decimals; -pi..0 = inspiration,
%              0..pi = expiration.
% Cardiac: time from the preceding R-peak; <= participant's systole cutoff
%          = systole, later = diastole (cutoffs: see tools/recover_systole_cutoffs.m).
% Input : <work_dir>/passive/epochs/<id>.mat, raw .edf (Resp, ecg), systole_cutoffs.csv
% Output: <work_dir>/passive/state/<id>.mat (state table, one row per trial)
%         <work_dir>/passive/state_trial_counts.csv

clear; clc;
C = tebc_config();

% Per-participant systole cutoffs: read from systole_cutoffs.csv if it exists,
% otherwise entered for each participant after inspecting the R-peak-locked
% mean ECG waveform.
cut = [];
if exist(C.cardiac.cutoffs, 'file'), cut = readtable(C.cardiac.cutoffs, 'TextType', 'char'); end
files    = dir(fullfile(C.work_dir, 'passive', 'epochs', 'PL*.mat'));
st_dir   = fullfile(C.work_dir, 'passive', 'state');
if ~exist(st_dir, 'dir'), mkdir(st_dir); end

counts = {};
for f = 1:numel(files)
    id = participant_info(files(f).name, C);
    load(fullfile(files(f).folder, files(f).name), 'tone_start_times');
    edf = fullfile(C.raw_passive, [id '_A.edf']);

    % Respiration phase
    cfg = []; cfg.dataset = edf; cfg.channel = {'Resp'};
    resp  = ft_preprocessing(cfg);
    phase = angle(hilbert(resp.trial{1}));
    ph    = round(phase(tone_start_times(:))', 2);
    resp_bin = discretize(ph, C.resp.edges);

    % Cardiac phase
    cfg = []; cfg.dataset = edf; cfg.channel = 'ecg';
    ecg = ft_preprocessing(cfg);
    [~, locs] = findpeaks(ecg.trial{1}, 'MinPeakProminence', C.rpeak(1), ...
        'MinPeakDistance', C.rpeak(2));
    delay = nan(numel(tone_start_times), 1);
    for t = 1:numel(tone_start_times)
        delay(t) = tone_start_times(t) - max(locs(locs <= tone_start_times(t)));
    end
    if isempty(cut)
        cutoff = input(sprintf('%s: systole cutoff (ms after R-peak): ', id));
    else
        cutoff = cut.cutoff_ms(strcmp(cut.id, id) | strcmp(cut.id, [id '_A']));
    end
    card_bin = discretize(delay, [0 cutoff]);
    card_bin(isnan(card_bin)) = 2; % after the cutoff = diastole

    state = table((1:numel(delay))', ph, delay, ...
        C.resp.labels(resp_bin)', C.cardiac.labels(card_bin)', ...
        'VariableNames', {'trial', 'resp_phase', 'rpeak_delay_ms', 'resp', 'cardiac'});
    state.state = strcat(state.resp, '-', state.cardiac);
    save(fullfile(st_dir, [id '.mat']), 'state');

    counts(end+1, :) = {id, sum(resp_bin == 1), sum(resp_bin == 2), ...
        sum(card_bin == 1), sum(card_bin == 2)}; %#ok<SAGROW>
end

T = cell2table(counts, 'VariableNames', {'id', 'n_INS', 'n_EXP', 'n_SYS', 'n_DIA'});
writetable(T, fullfile(C.work_dir, 'passive', 'state_trial_counts.csv'));
disp(varfun(@(x) sprintf('%.0f +- %.0f', mean(x), std(x)), T, 'InputVariables', 2:5));
