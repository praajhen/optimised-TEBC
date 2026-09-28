function keep = reject_trials_amplitude(data, R)
% REJECT_TRIALS_AMPLITUDE  Peak-to-peak artifact rejection.
% A trial is rejected if any channel exceeds R.high uV, or if more than
% R.max_channels channels exceed R.low uV (from sample R.first_sample on).
n    = numel(data.trial);
keep = true(1, n);
for tr = 1:n
    x   = data.trial{tr}(:, R.first_sample:end);
    p2p = max(x, [], 2) - min(x, [], 2);
    if any(p2p > R.high) || sum(p2p > R.low) > R.max_channels
        keep(tr) = false;
    end
end
end
