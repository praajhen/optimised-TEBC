%% s03_state_n1p2
% Composite N1-P2 per cardiorespiratory state (EXP-DIA, EXP-SYS, INS-DIA,
% INS-SYS) in the passive task. ERPs are averaged over the fronto-central ROI
% (E6, E7, E106); peaks a, b, c are detected automatically and visually
% verified (manual correction by clicking if needed).
% The state with the largest amplitude was the optimal state used for TEBC in
% the Personalised group.
% Interactive. Already processed participants are skipped, so it can be
% run in several sessions.
% Input : <work_dir>/passive/epochs/<id>.mat, <work_dir>/passive/state/<id>.mat
% Output: <work_dir>/passive/CardioResp_N1P2_allSubjects.mat / .csv (all_result)
%         <work_dir>/passive/state_erp/<id>.mat

clear; clc;
C = tebc_config();

out_file = fullfile(C.work_dir, 'passive', 'CardioResp_N1P2_allSubjects.mat');
erp_dir  = fullfile(C.work_dir, 'passive', 'state_erp');
if ~exist(erp_dir, 'dir'), mkdir(erp_dir); end
if exist(out_file, 'file'), load(out_file, 'all_result'); else, all_result = table(); end

files = dir(fullfile(C.work_dir, 'passive', 'epochs', 'PL*.mat'));
figure('Color', 'w', 'Position', [100 100 900 500]);

for f = 1:numel(files)
    id = participant_info(files(f).name, C);
    if ~isempty(all_result) && any(strcmp(all_result.Subject, id)), continue; end

    load(fullfile(files(f).folder, files(f).name), 'erp_trials');
    load(fullfile(C.work_dir, 'passive', 'state', [id '.mat']), 'state');
    roi = ismember(erp_trials.label, arrayfun(@(x) sprintf('E%d', x), C.roi, 'UniformOutput', false)) | ...
          ismember(erp_trials.label, arrayfun(@num2str, C.roi, 'UniformOutput', false));

    rows = cell(numel(C.states), 1);
    state_erp = struct();
    for s = 1:numel(C.states)
        sel = find(strcmp(state.state, C.states{s}));
        cfg = []; cfg.trials = sel;
        E = ft_timelockanalysis(cfg, erp_trials);
        y = mean(E.avg(roi, :), 1);
        state_erp.(strrep(C.states{s}, '-', '_')) = E;

        [~, t, v] = n1p2_first_peaks(E.time, y, C.peaks.min_dist);
        [amp, ~, v] = verify_peaks(E.time, y, t, v, sprintf('%s %s (n=%d)', id, C.states{s}, numel(sel)));
        rows{s} = {id, C.states{s}, v(1), v(2), v(3), amp, numel(sel)};
    end
    save(fullfile(erp_dir, [id '.mat']), 'state_erp');

    T = cell2table(vertcat(rows{:}), 'VariableNames', {'Subject', 'Condition', 'a', 'b', 'c', 'Amp', 'Ntrials'});
    all_result = [all_result; T]; %#ok<AGROW>
    save(out_file, 'all_result');
    [~, i] = max(T.Amp);
    fprintf('%s: optimal state %s (%.2f uV)\n', id, T.Condition{i}, T.Amp(i));
end

writetable(all_result, strrep(out_file, '.mat', '.csv'));
