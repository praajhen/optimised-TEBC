function [amp, t, v] = n1p2_first_peaks(time, y, min_dist)
% N1P2_FIRST_PEAKS  Composite N1-P2 for the passive task.
% a = first positive peak after 0 s, b = next trough, c = next positive peak
% (peaks at least min_dist s apart). amp = [(a - b) + (c - b)] / 2.
% Returns t = [tA tB tC] (s) and v = [a b c]; NaN if not found.
amp = NaN; t = nan(1,3); v = nan(1,3);
k = time >= 0;
[pPos, lPos] = findpeaks( y(k), time(k), 'MinPeakDistance', min_dist);
[pNeg, lNeg] = findpeaks(-y(k), time(k), 'MinPeakDistance', min_dist);
pNeg = -pNeg;
if isempty(pPos) || isempty(pNeg), return; end
iB = find(lNeg > lPos(1), 1);
if isempty(iB), return; end
iC = find(lPos > lNeg(iB), 1);
if isempty(iC), return; end
t = [lPos(1) lNeg(iB) lPos(iC)];
v = [pPos(1) pNeg(iB) pPos(iC)];
amp = ((v(1) - v(2)) + (v(3) - v(2))) / 2;
end
