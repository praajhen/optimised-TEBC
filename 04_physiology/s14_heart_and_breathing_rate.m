%% s14_heart_and_breathing_rate
% Mean heart rate and breathing rate per participant for the passive task
% and the TEBC session (Results 3.1).
%   Heart rate: R-peaks with findpeaks (prominence 700, distance 600 samples).
%   Breathing rate: 0.1-0.5 Hz band-pass (2nd-order Butterworth), peaks of the
%   filtered respiration signal.
% Input : raw .edf files of both sessions
% Output: <work_dir>/physiology_rates.csv

clear; clc;
C = tebc_config();

sessions = {'passive', C.raw_passive; 'TEBC', C.raw_tebc};
rows = {};
for k = 1:size(sessions, 1)
    files = dir(fullfile(sessions{k, 2}, 'PL*.edf'));
    for f = 1:numel(files)
        dataset = fullfile(sessions{k, 2}, files(f).name);
        [id, age] = participant_info(files(f).name, C);

        cfg = [];
        cfg.dataset    = dataset;
        cfg.channel    = 'Resp';
        cfg.bpfilter   = 'yes';
        cfg.bpfreq     = [0.1 0.5];
        cfg.bpfilttype = 'but';
        cfg.bpfiltord  = 2;
        resp = ft_preprocessing(cfg);
        [~, blocs] = findpeaks(resp.trial{1});

        cfg = []; cfg.dataset = dataset; cfg.channel = 'ecg';
        ecg = ft_preprocessing(cfg);
        [~, rlocs] = findpeaks(ecg.trial{1}, 'MinPeakProminence', 700, 'MinPeakDistance', 600);

        rows(end+1, :) = {id, age, sessions{k, 1}, files(f).name, ...
            60 / mean(diff(rlocs) / C.fs), 60 / mean(diff(blocs) / C.fs)}; %#ok<SAGROW>
    end
end

T = cell2table(rows, 'VariableNames', {'Subject', 'AgeGroup', 'Session', 'File', 'HeartRate_bpm', 'BreathingRate_bpm'});
writetable(T, fullfile(C.work_dir, 'physiology_rates.csv'));
disp(groupsummary(T, {'Session', 'AgeGroup'}, {'mean', 'std'}, {'HeartRate_bpm', 'BreathingRate_bpm'}));
