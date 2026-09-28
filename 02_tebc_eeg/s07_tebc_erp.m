%% s07_tebc_erp
% ERPs to the tone-CS in the 50 paired CS-US trials of TEBC: 1-30 Hz
% band-pass, epochs -100 to 500 ms around CS onset, baseline -100 to 0 ms,
% peak-to-peak rejection, average reference.
% Input : ICA-cleaned TEBC recordings (<ica_tebc>), see README
% Output: <work_dir>/tebc/erp/<id>_TEBC.mat (ERP)

clear; clc;
C = tebc_config();

files   = tebc_eeg_files(C.ica_tebc);
erp_dir = fullfile(C.work_dir, 'tebc', 'erp');
if ~exist(erp_dir, 'dir'), mkdir(erp_dir); end

for f = 1:numel(files)
    dataset = fullfile(C.ica_tebc, files(f).name);
    id      = participant_info(files(f).name, C);

    cfg          = [];
    cfg.dataset  = dataset;
    cfg.bpfilter = 'yes';
    cfg.bpfreq   = [1 30];
    data_filtered = ft_preprocessing(cfg);

    cfg                = [];
    cfg.dataset        = dataset;
    cfg.trialfun       = 'tebcerp';   % -100 to 500 ms
    cfg.baselinewindow = [-0.1 0];
    cfg.demean         = 'yes';
    cfg  = ft_definetrial(cfg);
    data = ft_redefinetrial(cfg, data_filtered);
    erp  = ft_preprocessing(cfg, data);

    keep = reject_trials_amplitude(erp, C.reject);
    cfgs = []; cfgs.trials = find(keep);
    erp  = ft_selectdata(cfgs, erp);

    cfg = []; cfg.reref = 'yes'; cfg.refmethod = 'avg'; cfg.refchannel = 'all';
    erp = ft_preprocessing(cfg, erp);

    ERP = ft_timelockanalysis([], erp);
    save(fullfile(erp_dir, [id '_TEBC.mat']), 'ERP');
    fprintf('%s: %d/%d trials\n', id, sum(keep), numel(keep));
end
