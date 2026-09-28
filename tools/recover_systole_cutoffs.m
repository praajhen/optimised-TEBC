%% recover_systole_cutoffs
% Recovers each participant's systole/diastole cutoff (ms after R-peak)
% from the saved passive-task files, so the value typed into
% "5.ecg_bins vs. ERP.m" does not need to be remembered.
%
% For every participant it:
%   1. loads trials\<id>.mat      (trials, tone_start_times)
%   2. loads trials\ecg\<id>.mat  (binMatrices: {1} systole, {2} diastole)
%   3. recomputes the R-peak-to-tone delay exactly as in 5.ecg_bins vs. ERP.m
%   4. matches each binned trial back to its trial number
%   5. reports the cutoff range: max(systole delay) <= cutoff < min(diastole delay)
%
% Output: systole_cutoffs.csv in the current folder. cutoff_ms (= longest
% systole delay) reproduces the original assignment exactly; copy the file
% to <work_dir> for 01_passive_task/s02_cardioresp_state.m.

clear; clc;
addpath('C:\MyTemp\fieldtrip-20230427'); ft_defaults;

trials_folder = 'C:\MyTemp\Personalised TEBC (2024-2025)\intermediate_files\trials';
ecg_folder    = fullfile(trials_folder, 'ecg');
data_folder   = 'C:\MyTemp\Personalised TEBC (2024-2025)\data\auditory';

files = dir(fullfile(ecg_folder, 'PL*.mat'));
roi   = [6 7 106];
out   = {};

for f = 1:numel(files)
    [~, id] = fileparts(files(f).name);
    fprintf('%s ... ', id);

    T = load(fullfile(trials_folder, [id '.mat']), 'trials', 'tone_start_times');
    B = load(fullfile(ecg_folder, [id '.mat']), 'binMatrices');

    % R-peaks and delays, same settings as 5.ecg_bins vs. ERP.m
    cfg = []; cfg.dataset = fullfile(data_folder, [id '.edf']); cfg.channel = 'ecg';
    ecg = ft_preprocessing(cfg);
    [~, locs] = findpeaks(ecg.trial{1}, 'MinPeakProminence', 600, 'MinPeakDistance', 500);
    delay = nan(numel(T.tone_start_times), 1);
    for t = 1:numel(T.tone_start_times)
        prev = locs(locs <= T.tone_start_times(t));
        if ~isempty(prev), delay(t) = T.tone_start_times(t) - max(prev); end
    end

    % Match binned trials back to trial numbers (ROI channels)
    nTr  = size(T.trials{1}, 1);
    bin  = nan(nTr, 1);
    for b = 1:2
        for i = 1:numel(B.binMatrices{b})
            x = B.binMatrices{b}{i};
            for tr = 1:nTr
                if isequal(x(roi(1),:), T.trials{roi(1)}(tr,:)) && ...
                   isequal(x(roi(2),:), T.trials{roi(2)}(tr,:)) && ...
                   isequal(x(roi(3),:), T.trials{roi(3)}(tr,:))
                    bin(tr) = b; break
                end
            end
        end
    end

    sys_max = max(delay(bin == 1));
    dia_min = min(delay(bin == 2));
    ok      = sys_max < dia_min;   % bins separable by one cutoff
    fprintf('cutoff between %d and %d ms%s\n', sys_max, dia_min, ...
        repmat(' (CHECK)', 1, ~ok));

    out(end+1, :) = {id, sum(bin == 1), sum(bin == 2), sum(isnan(bin)), ...
        sys_max, dia_min, ok, sys_max}; %#ok<SAGROW>
end

R = cell2table(out, 'VariableNames', {'id', 'n_systole', 'n_diastole', ...
    'n_unmatched', 'max_systole_delay_ms', 'min_diastole_delay_ms', 'consistent', 'cutoff_ms'});
writetable(R, 'systole_cutoffs.csv');
disp(R);
