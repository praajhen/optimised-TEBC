%% s06_split_half_stats
% Agreement of the optimal state between halves (proportion, Cohen's kappa)
% and split-half correlation of N1-P2 amplitudes per state (Results 3.2).
% Input : <work_dir>/passive/SplitHalfReliability.xlsx

clear; clc;
C = tebc_config();
T = readtable(fullfile(C.work_dir, 'passive', 'SplitHalfReliability.xlsx'));

H1 = [T.EXP_DIA_H1, T.EXP_SYS_H1, T.INS_DIA_H1, T.INS_SYS_H1];
H2 = [T.EXP_DIA_H2, T.EXP_SYS_H2, T.INS_DIA_H2, T.INS_SYS_H2];

%% Optimal-state agreement
[~, w1] = max(H1, [], 2);
[~, w2] = max(H2, [], 2);
match = w1 == w2;
fprintf('Same state: %d/%d (%.1f %%)\n', sum(match), numel(match), 100 * mean(match));

M  = confusionmat(w1, w2, 'Order', 1:4);
N  = sum(M(:));
Po = trace(M) / N;
Pe = sum(sum(M, 2) .* sum(M, 1)') / N^2;
fprintf('Cohen''s kappa = %.3f\n', (Po - Pe) / (1 - Pe));

%% Split-half correlation of amplitudes
for s = 1:4
    [r, p] = corr(H1(:, s), H2(:, s));
    fprintf('%s: r = %.3f, p = %.4f\n', C.states{s}, r, p);
end
