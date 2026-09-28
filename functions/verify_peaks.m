function [amp, t, v, manual] = verify_peaks(time, y, t, v, label)
% VERIFY_PEAKS  Show automatically detected a, b, c and ask for confirmation.
% If rejected, click a (positive), b (negative), c (positive) on the plot.
clf; hold on;
plot(time, y, 'k', 'LineWidth', 1.5); xline(0, '--k');
if ~any(isnan(v)), plot(t, v, 'ro', 'MarkerFaceColor', 'r'); end
xlim([min(time) max(time)]);
title(label, 'Interpreter', 'none'); drawnow;
manual = strcmpi(input(sprintf('%s: peaks OK? (y/n): ', label), 's'), 'n');
if manual
    disp('Click: a (positive), b (negative), c (positive)');
    [t, v] = ginput(3);
    t = t(:)'; v = v(:)';
    plot(t, v, 'go', 'MarkerFaceColor', 'g'); drawnow;
end
amp = ((v(1) - v(2)) + (v(3) - v(2))) / 2;
end
