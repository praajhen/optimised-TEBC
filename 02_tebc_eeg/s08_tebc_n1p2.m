%% s08_tebc_n1p2
% Composite N1-P2 to the tone-CS during TEBC from the fronto-central ROI.
% a, b and c are searched within 50-120, 80-160 and 150-250 ms and visually
% verified (manual correction by clicking if needed). Interactive.
% Input : <work_dir>/tebc/erp/<id>_TEBC.mat
% Output: <work_dir>/tebc/TEBC_N1P2_composite.csv
% Age x Group ANOVA on the composite was run in SPSS.

clear; clc;
C = tebc_config();

files = dir(fullfile(C.work_dir, 'tebc', 'erp', 'PL*_TEBC.mat'));
rows  = cell(numel(files), 1);
figure('Color', 'w', 'Position', [200 100 900 500]);

for f = 1:numel(files)
    [id, age, group] = participant_info(files(f).name, C);
    load(fullfile(files(f).folder, files(f).name), 'ERP');
    roi = ismember(ERP.label, arrayfun(@(x) sprintf('E%d', x), C.roi, 'UniformOutput', false)) | ...
          ismember(ERP.label, arrayfun(@num2str, C.roi, 'UniformOutput', false));

    t_ms = ERP.time * 1000;
    y    = mean(ERP.avg(roi, :), 1);
    [~, t, v] = n1p2_windows(t_ms, y, C.peaks);
    [amp, t, v, manual] = verify_peaks(t_ms, y, t, v, id);
    rows{f} = {id, age, group, t(1), v(1), t(2), v(2), t(3), v(3), amp, manual};
end

T = cell2table(vertcat(rows{:}), 'VariableNames', ...
    {'Subject', 'AgeGroup', 'Group', 'tA', 'a', 'tB', 'b', 'tC', 'c', 'Composite', 'Manual'});
writetable(T, fullfile(C.work_dir, 'tebc', 'TEBC_N1P2_composite.csv'));
disp(groupsummary(T, {'AgeGroup', 'Group'}, {'mean', 'std'}, 'Composite'));
