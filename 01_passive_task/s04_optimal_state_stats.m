%% s04_optimal_state_stats
% Optimal cardiorespiratory state per participant and related statistics
% (Results 3.2):
%   - distribution of optimal states, chi-square vs. uniform and young vs. older
%   - maximal N1-P2 per state, relative maximum (% of mean over the 4 states)
%   - mean N1-P2 over all passive-task trials (trial-weighted mean of the 4 states)
% Age x state and age x group ANOVAs were run in SPSS on the exported table.
% Input : <work_dir>/passive/CardioResp_N1P2_allSubjects.mat
% Output: <work_dir>/passive/optimal_state.csv

clear; clc;
C = tebc_config();
load(fullfile(C.work_dir, 'passive', 'CardioResp_N1P2_allSubjects.mat'), 'all_result');

subjects = unique(all_result.Subject);
best = table();
for i = 1:numel(subjects)
    T = all_result(strcmp(all_result.Subject, subjects{i}), :);
    [bestAmp, k] = max(T.Amp);
    [~, age, group] = participant_info(subjects{i}, C);
    best.Subject{i, 1}     = subjects{i};
    best.AgeGroup{i, 1}    = age;
    best.Group{i, 1}       = group;
    best.Condition{i, 1}   = T.Condition{k};
    best.Amp(i, 1)         = bestAmp;
    best.RelativeMax(i, 1) = bestAmp / mean(T.Amp) * 100;
    best.MeanAmpAllTrials(i, 1) = sum(T.Amp .* T.Ntrials) / sum(T.Ntrials);
end
writetable(best, fullfile(C.work_dir, 'passive', 'optimal_state.csv'));

%% Distribution of optimal states
counts = cellfun(@(s) sum(strcmp(best.Condition, s)), C.states);
disp(array2table(counts, 'VariableNames', strrep(C.states, '-', '_')));
E = mean(counts) * ones(size(counts));
chi2 = sum((counts - E).^2 ./ E);
fprintf('Uniform: chi2(%d) = %.2f, p = %.3f\n', numel(counts) - 1, chi2, 1 - chi2cdf(chi2, numel(counts) - 1));

%% Young vs older
tbl = zeros(2, numel(C.states));
ages = {'young', 'older'};
for a = 1:2
    tbl(a, :) = cellfun(@(s) sum(strcmp(best.Condition, s) & strcmp(best.AgeGroup, ages{a})), C.states);
end
E = sum(tbl, 2) * sum(tbl, 1) / sum(tbl(:));
chi2 = sum((tbl - E).^2 ./ E, 'all');
df = (size(tbl, 1) - 1) * (size(tbl, 2) - 1);
fprintf('Young vs older: chi2(%d) = %.2f, p = %.3f\n', df, chi2, 1 - chi2cdf(chi2, df));

%% Maximal N1-P2 per state and relative maximum
disp(groupsummary(best, 'Condition', {'mean', 'std'}, 'Amp'));
y = strcmp(best.AgeGroup, 'young');
fprintf('Relative max: young %.2f +- %.2f %%, older %.2f +- %.2f %%\n', ...
    mean(best.RelativeMax(y)), std(best.RelativeMax(y)), mean(best.RelativeMax(~y)), std(best.RelativeMax(~y)));
[~, p, ~, st] = ttest2(best.RelativeMax(y), best.RelativeMax(~y));
fprintf('t(%d) = %.2f, p = %.3f\n', st.df, st.tstat, p);
