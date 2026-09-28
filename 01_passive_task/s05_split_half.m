%% s05_split_half
% Split-half reliability of the optimal state. For each participant, the
% trials of each cardiorespiratory state are randomly split into two halves,
% the composite N1-P2 is determined in each half (automatic peaks, visually
% verified) and the optimal state is identified separately per half.
% Interactive; run once per participant (set 'id'). The random seed is saved
% with each row so a split can be repeated.
% Input : <work_dir>/passive/epochs/<id>.mat, <work_dir>/passive/state/<id>.mat
% Output: <work_dir>/passive/SplitHalfReliability.xlsx (one row per participant)

clear; clc;
C = tebc_config();

%--------------------------------------------------------------------------
id = 'PL01';
%--------------------------------------------------------------------------

seed = randi(2^31 - 1);
rng(seed);

load(fullfile(C.work_dir, 'passive', 'epochs', [id '.mat']), 'erp_trials');
load(fullfile(C.work_dir, 'passive', 'state', [id '.mat']), 'state');
roi = ismember(erp_trials.label, arrayfun(@(x) sprintf('E%d', x), C.roi, 'UniformOutput', false)) | ...
      ismember(erp_trials.label, arrayfun(@num2str, C.roi, 'UniformOutput', false));

amp = nan(2, numel(C.states));
figure('Color', 'w', 'Position', [100 100 900 500]);
for s = 1:numel(C.states)
    idx   = find(strcmp(state.state, C.states{s}));
    idx   = idx(randperm(numel(idx)));
    nHalf = floor(numel(idx) / 2);
    halves = {idx(1:nHalf), idx(nHalf+1:end)};
    for h = 1:2
        cfg = []; cfg.trials = halves{h};
        E = ft_timelockanalysis(cfg, erp_trials);
        y = mean(E.avg(roi, :), 1);
        [~, t, v] = n1p2_first_peaks(E.time, y, C.peaks.min_dist);
        amp(h, s) = verify_peaks(E.time, y, t, v, sprintf('%s %s half %d', id, C.states{s}, h));
    end
end

[~, w1] = max(amp(1, :));
[~, w2] = max(amp(2, :));
s1 = sort(amp(1, :), 'descend'); s2 = sort(amp(2, :), 'descend');
if w1 == w2, msg = 'match'; else, msg = 'no match'; end
fprintf('%s: half 1 %s, half 2 %s (%s)\n', id, C.states{w1}, C.states{w2}, msg);

NewRow = table({id}, C.states(w1), C.states(w2), w1 == w2, s1(1) - s1(2), s2(1) - s2(2), ...
    amp(1,1), amp(2,1), amp(1,2), amp(2,2), amp(1,3), amp(2,3), amp(1,4), amp(2,4), seed, ...
    'VariableNames', {'Subject', 'WinnerHalf1', 'WinnerHalf2', 'Match', 'MarginHalf1', 'MarginHalf2', ...
    'EXP_DIA_H1', 'EXP_DIA_H2', 'EXP_SYS_H1', 'EXP_SYS_H2', ...
    'INS_DIA_H1', 'INS_DIA_H2', 'INS_SYS_H1', 'INS_SYS_H2', 'Seed'});

outfile = fullfile(C.work_dir, 'passive', 'SplitHalfReliability.xlsx');
if exist(outfile, 'file')
    R = readtable(outfile);
    R(strcmp(R.Subject, id), :) = [];
    R = [R; NewRow];
else
    R = NewRow;
end
writetable(R, outfile);
