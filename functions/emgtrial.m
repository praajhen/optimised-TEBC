function [trl, event] = emgtrial(cfg)
% EMGTRIAL  All 60 CS trials (5 CS-alone, 50 CS-US, 5 CS-alone), epoch
% -500 to 1000 ms from CS onset. Stimulus A = CS (tone), Stimulus B = US (airpuff).


cfg.trialdef.eventtype  = 'annotation';
cfg.trialdef.prestim    = 0.500; % in seconds

cfg.trialdef.poststim   = 1; % in seconds


% read the header information and the events from the data
hdr   = ft_read_header(cfg.dataset);
event = ft_read_event(cfg.dataset);

% Find indices of rows with empty event.values
emptyValueIndices = find(arrayfun(@(x) isempty(x.value), event));

% Remove rows with empty event.values
event(emptyValueIndices) = [];

% Find the indices of the even-numbered rows
evenIndices = 2:2:length(event);

% Remove the even-numbered rows
event(evenIndices) = [];

% Keep only Stimulus A and Stimulus B
validIdx = strcmp({event.value}, 'Stimulus A') | strcmp({event.value}, 'Stimulus B');
event = event(validIdx);

% ===== Enforce order: B(5), A(5), (A B)x50, A(5) =====
values = {event.value};
keep = false(1,numel(values));
k = 1;

i = 0; while k<=numel(values) && i<5
    if strcmp(values{k},'Stimulus B'), keep(k)=true; i=i+1; end, k=k+1;
end

% % Skip any leading B (optional initial airpuffs)
% while k<=numel(values) && strcmp(values{k},'Stimulus B')
%     k = k + 1;
% end

i = 0; while k<=numel(values) && i<5
    if strcmp(values{k},'Stimulus A'), keep(k)=true; i=i+1; end, k=k+1;
end

i = 0; while k<numel(values) && i<50
    if strcmp(values{k},'Stimulus A') && strcmp(values{k+1},'Stimulus B')
        keep([k k+1])=true; i=i+1; k=k+2;
    else
        k=k+1;
    end
end

i = 0; while k<=numel(values) && i<5
    if strcmp(values{k},'Stimulus A'), keep(k)=true; i=i+1; end, k=k+1;
end

event = event(keep);

 
% Drop the 5 US-alone trials
event(1:5) = [];
event(116:end) = [];

% search for "trigger" events
value= {event(:).value}';
sample= {event(:).sample}';

% determine the number of samples before and after the trigger
pretrig  = -round(cfg.trialdef.prestim  * hdr.Fs);
posttrig =  round(cfg.trialdef.poststim * hdr.Fs);

trl = zeros(0, 3);
for j = 1:(length(value))
  trg = value{j};
   
        if strcmp(trg, 'Stimulus A') 
            trlbegin = sample{j} + pretrig;       
            trlend   = sample{j} + posttrig;       
            offset   = pretrig;
            newtrl   = [trlbegin trlend offset];
            trl      = [trl; newtrl];
        end


end
