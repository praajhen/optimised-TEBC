%% s01_epoch_passive
% Passive auditory task: 1-30 Hz band-pass, epochs -200 to 1000 ms around
% tone onset, baseline correction, peak-to-peak rejection, average reference.
% Input : ICA-cleaned EEGLAB files (<ica_passive>/PLxx_A.set), see README
% Output: <work_dir>/passive/epochs/<id>.mat (erp_trials, tone_start_times)
%         <work_dir>/passive/erp/<id>_A.mat (ERP)
%         <work_dir>/passive/trial_counts.csv

clear; clc;
C = tebc_config();

files   = dir(fullfile(C.ica_passive, 'PL*.set'));
ep_dir  = fullfile(C.work_dir, 'passive', 'epochs');
erp_dir = fullfile(C.work_dir, 'passive', 'erp');
if ~exist(ep_dir, 'dir'), mkdir(ep_dir); end
if ~exist(erp_dir, 'dir'), mkdir(erp_dir); end

counts = {};
for f = 1:numel(files)
    dataset = fullfile(C.ica_passive, files(f).name);
    id      = participant_info(files(f).name, C);

    cfg          = [];
    cfg.dataset  = dataset;
    cfg.bpfilter = 'yes';
    cfg.bpfreq   = [1 30];
    data_filtered = ft_preprocessing(cfg);

    cfg                     = [];
    cfg.dataset             = dataset;
    cfg.trialfun            = 'ft_trialfun_general';
    cfg.trialdef.eventtype  = 'trigger';
    cfg.trialdef.eventvalue = 1;   % tone
    cfg.trialdef.prestim    = 0.2;
    cfg.trialdef.poststim   = 1;
    cfg.baselinewindow      = [-0.2 0];
    cfg.demean              = 'yes';
    cfg  = ft_definetrial(cfg);
    data = ft_redefinetrial(cfg, data_filtered);
    erp  = ft_preprocessing(cfg, data);
    n_before = numel(erp.trial);

    keep = reject_trials_amplitude(erp, C.reject);
    cfgs = []; cfgs.trials = find(keep);
    erp  = ft_selectdata(cfgs, erp);

    cfg = []; cfg.reref = 'yes'; cfg.refmethod = 'avg'; cfg.refchannel = 'all';
    erp_trials = ft_preprocessing(cfg, erp);

    tone_start_times = tone_times(dataset, erp_trials);
    save(fullfile(ep_dir, [id '.mat']), 'erp_trials', 'tone_start_times', '-v7.3');

    ERP = ft_timelockanalysis([], erp_trials);
    save(fullfile(erp_dir, [id '_A.mat']), 'ERP');

    counts(end+1, :) = {id, n_before, numel(erp_trials.trial)}; %#ok<SAGROW>
end

T = cell2table(counts, 'VariableNames', {'id', 'n_epochs', 'n_accepted'});
T.pct_rejected = 100 * (1 - T.n_accepted ./ T.n_epochs);
writetable(T, fullfile(C.work_dir, 'passive', 'trial_counts.csv'));
fprintf('Rejected %.2f +- %.2f %%, retained %.0f +- %.0f trials (range %d-%d)\n', ...
    mean(T.pct_rejected), std(T.pct_rejected), mean(T.n_accepted), std(T.n_accepted), ...
    min(T.n_accepted), max(T.n_accepted));
