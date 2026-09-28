function [amp, t, v] = n1p2_windows(time_ms, y, P)
% N1P2_WINDOWS  Composite N1-P2 for the TEBC ERPs.
% a = maximum in P.win_a, b = minimum in P.win_b, c = maximum in P.win_c (ms).
% amp = [(a - b) + (c - b)] / 2.
iA = find(time_ms >= P.win_a(1) & time_ms <= P.win_a(2));
iB = find(time_ms >= P.win_b(1) & time_ms <= P.win_b(2));
iC = find(time_ms >= P.win_c(1) & time_ms <= P.win_c(2));
[~, a] = max(y(iA)); [~, b] = min(y(iB)); [~, c] = max(y(iC));
idx = [iA(a) iB(b) iC(c)];
t = time_ms(idx);
v = y(idx);
amp = ((v(1) - v(2)) + (v(3) - v(2))) / 2;
end
