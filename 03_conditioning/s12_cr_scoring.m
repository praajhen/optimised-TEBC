%% s12_cr_scoring
% Conditioned eyeblink scoring from orbicularis oculi EMG for all 60 CS trials
% (5 CS-alone, 50 CS-US, 5 CS-alone):
%   high-pass 60 Hz (8th-order two-pass Butterworth), rectify,
%   low-pass 20 Hz (8th-order two-pass Butterworth), epochs -500 to 1000 ms.
% Per trial, threshold = mean + 2.5 SD of the -500 to 0 ms baseline.
%   bad trial : blink (peak > threshold) in the 200 ms before CS onset
%   CR        : peak > threshold 600-800 ms after CS onset
% Input : raw TEBC .edf files (one file per participant)
% Output: <work_dir>/conditioning/CR_flags.csv (rows = trials, columns = participants;
%         1 = CR, 0 = no CR, -1 = bad), per-participant figures

clear; clc; close all;
C = tebc_config();

out_dir = fullfile(C.work_dir, 'conditioning');
if ~exist(out_dir, 'dir'), mkdir(out_dir); end
files = dir(fullfile(C.raw_tebc, 'PL*_TEBC.edf'));

flags = [];
ids   = {};
for f = 1:numel(files)
    dataset = fullfile(C.raw_tebc, files(f).name);
    id = participant_info(files(f).name, C);

    cfg = [];
    cfg.dataset  = dataset;
    cfg.trialfun = 'emgtrial';
    cfg = ft_definetrial(cfg);
    cfg.channel    = 'emg';
    cfg.hpfilter   = 'yes'; cfg.hpfreq = C.emg.hp; cfg.hpfilttype = 'but';
    cfg.hpfiltord  = C.emg.order; cfg.hpfiltdir = 'twopass';
    emg = ft_preprocessing(cfg);

    cfg = []; cfg.rectify = 'yes';
    emg = ft_preprocessing(cfg, emg);

    cfg = [];
    cfg.lpfilter  = 'yes'; cfg.lpfreq = C.emg.lp; cfg.lpfilttype = 'but';
    cfg.lpfiltord = C.emg.order; cfg.lpfiltdir = 'twopass';
    emg = ft_preprocessing(cfg, emg);

    EMG = cell2mat(cellfun(@(x) x(:)', emg.trial(:), 'UniformOutput', false));
    t   = linspace(-500, 1000, size(EMG, 2));
    bsl = t >= C.emg.baseline(1)   & t <= C.emg.baseline(2);
    pre = t >= C.emg.bad_window(1) & t <= C.emg.bad_window(2);
    crw = t >= C.emg.cr_window(1)  & t <= C.emg.cr_window(2);

    th = mean(EMG(:, bsl), 2) + C.emg.k .* std(EMG(:, bsl), [], 2);
    cr = zeros(size(EMG, 1), 1);
    cr(max(EMG(:, crw), [], 2) > th) = 1;
    cr(max(EMG(:, pre), [], 2) > th) = -1;   % bad trial overrides

    if ~isempty(flags) && numel(cr) ~= size(flags, 1)
        error('%s: %d trials instead of %d.', id, numel(cr), size(flags, 1));
    end
    flags = [flags, cr]; %#ok<AGROW>
    ids{end+1} = id; %#ok<SAGROW>

    % Figure: mean EMG of CR, no-CR and bad paired trials
    p   = C.trials.paired;
    cls = {-1, 'k--', 'bad'; 0, 'k', 'no CR'; 1, 'r', 'CR'};
    figure('Color', 'w', 'Visible', 'off'); hold on;
    lbl = {};
    for k = 1:3
        sel = p(cr(p) == cls{k, 1});
        if isempty(sel), continue; end
        X = EMG(sel, :) - mean(EMG(sel, bsl), 2);   % baseline-subtracted, display only
        plot(t, mean(X, 1), cls{k, 2}, 'LineWidth', 1.5);
        lbl{end+1} = sprintf('%s, n = %d', cls{k, 3}, numel(sel)); %#ok<SAGROW>
    end
    legend(lbl, 'Location', 'northwest'); legend boxoff;
    xlabel('Time from CS onset (ms)'); ylabel('EMG (baseline-corrected)');
    title(id); box off;
    saveas(gcf, fullfile(out_dir, [id '_CR_detection.png']));
    close(gcf);
end

T = array2table(flags, 'VariableNames', ids);
writetable(T, fullfile(out_dir, 'CR_flags.csv'));
