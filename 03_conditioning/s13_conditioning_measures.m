%% s13_conditioning_measures
% Per-participant conditioning measures (Methods 2.7), exported for SPSS/JASP:
%   CR% in CS-alone trials before conditioning, in five blocks of 10 paired
%   trials, and in CS-alone trials after conditioning (bad trials excluded);
%   peak performance = highest CR% in blocks 3-5;
%   good learner     = peak performance >= 60 %;
%   learning rate    = paired trial on which the 5th CR occurred (NaN if < 5 CRs);
%   strict sample (as in Santhana Gopalan et al., 2024): excluded if > 30 % bad
%   trials, < 5 CRs in the paired trials, or > 2 blinks in the first CS-alone trials.
% Input : <work_dir>/conditioning/CR_flags.csv
% Output: <work_dir>/conditioning/conditioning_measures.csv

clear; clc;
C = tebc_config();
T = readtable(fullfile(C.work_dir, 'conditioning', 'CR_flags.csv'));
ids = T.Properties.VariableNames';
F = table2array(T);
n = numel(ids);

pct = @(x) 100 * sum(x == 1) / sum(x ~= -1);   % CR% among good trials

R = table();
for s = 1:n
    cr = F(:, s);
    [~, age, group] = participant_info(ids{s}, C);
    paired = cr(C.trials.paired);

    blocks = arrayfun(@(b) pct(paired((b-1)*10 + (1:10))), 1:5);
    crpos  = find(paired == 1);

    row = table(ids(s), {age}, {group}, 'VariableNames', {'Subject', 'AgeGroup', 'Group'});
    row.CR_pre  = pct(cr(C.trials.cs_pre));
    for b = 1:5, row.(sprintf('CR_block%d', b)) = blocks(b); end
    row.CR_post = pct(cr(C.trials.cs_post));
    row.PeakPerformance = max(blocks(3:5));
    row.GoodLearner     = row.PeakPerformance >= 60;
    row.NumCR_paired    = numel(crpos);
    if numel(crpos) >= 5, row.LearningRate = crpos(5); else, row.LearningRate = NaN; end

    % Strict-sample criteria (as in the analysis): bad-trial % over all 60
    % trials; pre-conditioning blinks = CR% in the first 5 CS-alone trials / 20
    row.BadTrialPct   = 100 * sum(cr == -1) / numel(cr);
    row.PreBlinks     = round(row.CR_pre / 20);
    row.StrictInclude = row.BadTrialPct <= 30 && row.NumCR_paired >= 5 && row.PreBlinks <= 2;
    R = [R; row]; %#ok<AGROW>
end
writetable(R, fullfile(C.work_dir, 'conditioning', 'conditioning_measures.csv'));

fprintf('Strict sample: %d of %d\n', sum(R.StrictInclude), n);
fprintf('Reached 5 CRs: %d of %d\n', sum(~isnan(R.LearningRate)), n);

%% Good learners by age and by group (chi-square)
for v = {'AgeGroup', 'Group'}
    [tbl, chi2, p] = crosstab(R.(v{1}), R.GoodLearner);
    fprintf('\nGood learners by %s: chi2(1) = %.2f, p = %.3f\n', v{1}, chi2, p); disp(tbl);
end
