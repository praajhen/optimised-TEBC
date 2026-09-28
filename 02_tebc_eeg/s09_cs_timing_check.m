%% s09_cs_timing_check
% Post-hoc check of CS timing. For each participant, ECG and respiration are
% plotted +-2 s around the onset of each of the 50 paired CS-US trials
% (CS = Stimulus A followed by the US, Stimulus B, 700-900 ms later).
% The cardiorespiratory state at each CS onset (EXP/INS x SYS/DIA) was then
% classified visually from these figures and compared with the intended state.
% Split recordings (e.g. PL38_TEBC1/2.edf) are combined in trial order.
% Input : raw TEBC .edf files
% Output: <work_dir>/tebc/cs_timing/<id>_1.png (trials 1-25), <id>_2.png (26-50)

clear; clc; close all;
C = tebc_config();

out_dir = fullfile(C.work_dir, 'tebc', 'cs_timing');
if ~exist(out_dir, 'dir'), mkdir(out_dir); end

win   = 2 * C.fs;
t     = (-win:win) / C.fs;
files = dir(fullfile(C.raw_tebc, '*_TEBC*.edf'));
ids   = unique(regexprep({files.name}, '_TEBC[0-9]*\.edf$', ''), 'stable');

for p = 1:numel(ids)
    id = ids{p};
    pf = files(startsWith({files.name}, [id '_TEBC']));
    [~, order] = sort({pf.name}); pf = pf(order);

    figs = {figure('Color', 'w', 'Position', [50 50 1600 1000]), ...
            figure('Color', 'w', 'Position', [50 50 1600 1000])};
    n = 0;
    for f = 1:numel(pf)
        edf = fullfile(C.raw_tebc, pf(f).name);
        ev  = ft_read_event(edf);
        ev(arrayfun(@(x) isempty(x.value), ev)) = [];
        A = [ev(strcmp({ev.value}, 'Stimulus A')).sample];
        B = [ev(strcmp({ev.value}, 'Stimulus B')).sample];

        % Paired trials: A followed by B 700-900 ms later
        cs = [];
        for i = 1:numel(A)
            nb = B(B > A(i));
            if ~isempty(nb) && (nb(1) - A(i)) / C.fs * 1000 >= 700 && (nb(1) - A(i)) / C.fs * 1000 <= 900
                cs(end+1) = A(i); %#ok<AGROW>
            end
        end
        if isempty(cs), continue; end

        hdr  = ft_read_header(edf);
        dat  = ft_read_data(edf);
        ecg  = double(dat(find(contains(lower(hdr.label), 'ecg'), 1), :));
        resp = double(dat(find(contains(lower(hdr.label), 'resp'), 1), :));

        for tr = 1:numel(cs)
            n = n + 1;
            idx = cs(tr) - win : cs(tr) + win;
            if idx(1) < 1 || idx(end) > numel(ecg), continue; end
            figure(figs{1 + (n > 25)});
            subplot(5, 5, n - 25 * (n > 25));
            yyaxis left;  plot(t, ecg(idx), 'k');  ylabel('ECG');
            yyaxis right; plot(t, resp(idx), 'b'); ylabel('Resp');
            xline(0, 'r', 'LineWidth', 1.5); xlim([-2 2]);
            title(sprintf('Trial %d', n)); grid on;
        end
    end

    if n ~= 50
        warning('%s has %d paired trials instead of 50; figures not saved.', id, n);
        close(figs{:}); continue
    end
    for k = 1:2
        figure(figs{k});
        sgtitle(sprintf('%s: trials %d-%d, +-2 s around CS onset', id, 25 * (k - 1) + 1, 25 * k));
        exportgraphics(figs{k}, fullfile(out_dir, sprintf('%s_%d.png', id, k)), 'Resolution', 200);
    end
    close(figs{:});
end
