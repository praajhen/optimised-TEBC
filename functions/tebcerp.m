function [trl, event] = tebcerp(cfg)
% TEBCERP  Trials for the 50 paired CS-US trials of TEBC, time-locked to CS
% onset ('A - Stimulation'). Default epoch -100 to 500 ms; set
% cfg.trialdef.prestim/poststim to change it.


cfg.trialdef.eventtype  = 'annotation';
if ~isfield(cfg,'trialdef') || ~isfield(cfg.trialdef,'prestim'),  cfg.trialdef.prestim  = 0.1; end % s; default for ERPs

if ~isfield(cfg,'trialdef') || ~isfield(cfg.trialdef,'poststim'), cfg.trialdef.poststim = 0.5; end % s; TF analysis uses 1.0/1.0


  

% read the header information and the events from the data
hdr   = ft_read_header(cfg.dataset);
event = ft_read_event( cfg.dataset);

% Find indices of rows with empty event.values
emptyValueIndices = find(arrayfun(@(x) isempty(x.value), event));

% Remove rows with empty event.values
event(emptyValueIndices) = [];

% Find the indices of the even-numbered rows
evenIndices = 2:2:length(event);

% Remove the even-numbered rows
event(evenIndices) = [];
 
% Drop the 5 US-alone and 5 CS-alone trials, keep the 50 paired trials
event(1:10) = [];
event(101:end) = [];

% Find the indices of the even-numbered rows
evenIndices = 2:2:length(event);

% Remove the even-numbered rows
event(evenIndices) = [];

% search for "trigger" events
value= {event(:).value}';
sample= {event(:).sample}';

% determine the number of samples before and after the trigger
pretrig  = -round(cfg.trialdef.prestim  * hdr.Fs);
posttrig =  round(cfg.trialdef.poststim * hdr.Fs);

trl = zeros(0, 3);
for j = 1:(length(value))
  trg = value{j};
   
        if strcmp(trg, 'A - Stimulation') 
            trlbegin = sample{j} + pretrig;       
            trlend   = sample{j} + posttrig;       
            offset   = pretrig;
            newtrl   = [trlbegin trlend offset];
            trl      = [trl; newtrl];
        end


end
