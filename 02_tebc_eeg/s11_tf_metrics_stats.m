%% s11_tf_metrics_stats
% Theta-band (5-10 Hz) ITC and induced power in the 80-300 ms window after
% CS onset, averaged over the ROI; Age x Group ANOVAs; multiple regression
% of the composite N1-P2 on ITC and induced power.
% (SPSS was used for the reported statistics; this script gives the same
% models from the exported table.)
% Input : <work_dir>/tebc/tf/<id>_TF.mat, <work_dir>/tebc/TEBC_N1P2_composite.csv
% Output: <work_dir>/tebc/TF_metrics.csv

clear; clc;
C = tebc_config();

files = dir(fullfile(C.work_dir, 'tebc', 'tf', 'PL*_TF.mat'));
n = numel(files);
Subject = cell(n, 1); AgeGroup = cell(n, 1); Group = cell(n, 1);
ITCmean = nan(n, 1); EVOKEDmean = nan(n, 1); INDUCEDmean = nan(n, 1);

for s = 1:n
    [Subject{s}, AgeGroup{s}, Group{s}] = participant_info(files(s).name, C);
    load(fullfile(files(s).folder, files(s).name), 'ITC', 'EVOKED', 'INDUCED');
    fi = ITC.freq >= C.tf.band(1)   & ITC.freq <= C.tf.band(2);
    ti = ITC.time >= C.tf.window(1) & ITC.time <= C.tf.window(2);
    band_mean = @(X) mean(X(fi, ti), 'all', 'omitnan');
    ITCmean(s)     = band_mean(squeeze(mean(ITC.powspctrm, 1, 'omitnan')));
    EVOKEDmean(s)  = band_mean(squeeze(mean(EVOKED.powspctrm, 1, 'omitnan')));
    INDUCEDmean(s) = band_mean(squeeze(mean(INDUCED.powspctrm, 1, 'omitnan')));
end

TF = table(Subject, AgeGroup, Group, ITCmean, EVOKEDmean, INDUCEDmean);
N1P2 = readtable(fullfile(C.work_dir, 'tebc', 'TEBC_N1P2_composite.csv'), 'TextType', 'char');
TF = innerjoin(TF, N1P2(:, {'Subject', 'Composite'}), 'Keys', 'Subject');
writetable(TF, fullfile(C.work_dir, 'tebc', 'TF_metrics.csv'));
fprintf('Participants with TF and N1-P2 data: %d\n', height(TF));

%% Age x Group ANOVAs
for v = {'ITCmean', 'INDUCEDmean'}
    [~, tbl] = anovan(TF.(v{1}), {TF.AgeGroup, TF.Group}, 'model', 'interaction', ...
        'varnames', {'Age', 'Group'}, 'display', 'off');
    fprintf('\n%s\n', v{1}); disp(tbl);
end

%% Multiple regression: composite N1-P2 ~ ITC + induced power
mdl = fitlm(TF, 'Composite ~ ITCmean + INDUCEDmean');
disp(mdl); disp(anova(mdl, 'summary'));

%% Pearson correlations among measures (correlations with age in years were run in SPSS)
r = corr([TF.Composite TF.ITCmean TF.INDUCEDmean]);
disp(array2table(r, 'VariableNames', {'N1P2', 'ITC', 'Induced'}, 'RowNames', {'N1P2', 'ITC', 'Induced'}));
