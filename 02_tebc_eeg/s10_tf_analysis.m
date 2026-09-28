%% s10_tf_analysis
% Time-frequency analysis of the 50 paired TEBC trials at the fronto-central
% ROI. Epochs -1000 to 1000 ms around CS onset (to limit edge effects),
% 1-30 Hz band-pass, 50 Hz notch, baseline -300 to -50 ms, average reference.
% Morlet wavelets (3 cycles), 4-15 Hz, -300 to 500 ms.
% Derived per participant: inter-trial coherence (ITC), total power, evoked
% power (power of the ERP) and induced power (total - evoked).
% Input : ICA-cleaned TEBC recordings (<ica_tebc>)
% Output: <work_dir>/tebc/tf/<id>_TF.mat (ITC, TOTAL, EVOKED, INDUCED, META)

clear; clc;
C = tebc_config();

files  = tebc_eeg_files(C.ica_tebc);
tf_dir = fullfile(C.work_dir, 'tebc', 'tf');
if ~exist(tf_dir, 'dir'), mkdir(tf_dir); end
roi = arrayfun(@(x) sprintf('E%d', x), C.roi, 'UniformOutput', false);

for s = 1:numel(files)
    dataset = fullfile(C.ica_tebc, files(s).name);
    id      = participant_info(files(s).name, C);
    fprintf('Processing %d/%d: %s\n', s, numel(files), id);

    cfg = []; cfg.dataset = dataset;
    data = ft_preprocessing(cfg);

    cfg = [];
    cfg.dataset  = dataset;
    cfg.trialfun = 'tebcerp';
    cfg.trialdef.prestim  = 1.0;
    cfg.trialdef.poststim = 1.0;
    cfg = ft_definetrial(cfg);
    tf_data = ft_redefinetrial(cfg, data);

    cfg = [];
    cfg.bpfilter = 'yes'; cfg.bpfreq = [1 30];
    cfg.bsfilter = 'yes'; cfg.bsfreq = [49 51];
    tf_data = ft_preprocessing(cfg, tf_data);

    cfg = []; cfg.demean = 'yes'; cfg.baselinewindow = C.tf.baseline;
    tf_data = ft_preprocessing(cfg, tf_data);

    cfg = []; cfg.reref = 'yes'; cfg.refmethod = 'avg'; cfg.refchannel = 'all';
    tf_data = ft_preprocessing(cfg, tf_data);

    cfg = []; cfg.channel = roi;
    tf_roi = ft_selectdata(cfg, tf_data);

    % Single-trial Fourier spectra (ITC) and total power
    cfg = [];
    cfg.method = 'wavelet'; cfg.output = 'fourier';
    cfg.foi = C.tf.foi; cfg.toi = C.tf.toi; cfg.width = C.tf.width;
    cfg.keeptrials = 'yes'; cfg.pad = 'nextpow2';
    freq_fourier = ft_freqanalysis(cfg, tf_roi);
    cfg.output = 'pow';
    freq_pow = ft_freqanalysis(cfg, tf_roi);

    % Evoked power (power of the averaged response)
    timelock = ft_timelockanalysis([], tf_roi);
    if isfield(timelock, 'sampleinfo'), timelock = rmfield(timelock, 'sampleinfo'); end
    cfg2 = [];
    cfg2.method = 'wavelet'; cfg2.output = 'pow';
    cfg2.foi = C.tf.foi; cfg2.toi = C.tf.toi; cfg2.width = C.tf.width; cfg2.pad = 'nextpow2';
    EVOKED = ft_freqanalysis(cfg2, timelock);

    % ITC
    F = freq_fourier.fourierspctrm;
    ITC = struct('label', {freq_fourier.label}, 'freq', freq_fourier.freq, 'time', freq_fourier.time, ...
        'dimord', 'chan_freq_time', 'powspctrm', abs(squeeze(mean(F ./ (abs(F) + eps), 1))));

    % Total and induced power
    totalpow = squeeze(mean(freq_pow.powspctrm, 1));
    TOTAL = ITC; TOTAL.powspctrm = totalpow;
    INDUCED = EVOKED;
    INDUCED.powspctrm = max(totalpow - EVOKED.powspctrm, 0);

    META = struct('subject_id', id, 'source_file', files(s).name, 'nTrials', numel(tf_data.trial), ...
        'epoch', [-1 1], 'foi', C.tf.foi, 'toi', C.tf.toi, 'width', C.tf.width, ...
        'filter', [1 30], 'notch', 50, 'baseline', C.tf.baseline, 'channels', {roi});
    save(fullfile(tf_dir, [id '_TF.mat']), 'ITC', 'TOTAL', 'EVOKED', 'INDUCED', 'META', '-v7.3');
end
