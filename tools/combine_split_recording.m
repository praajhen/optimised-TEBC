%% combine_split_recording
% Combines a TEBC recording that was saved in two parts (PL38_TEBC1 and
% PL38_TEBC2) into one BrainVision file, shifting the events of the second
% part by the length of the first.
% Output: PL38_TEBC.vhdr/.eeg/.vmrk in the ICA-cleaned TEBC folder

clear; clc;
C = tebc_config();

part1 = fullfile(C.ica_tebc, 'PL38_TEBC1.set');
part2 = fullfile(C.ica_tebc, 'PL38_TEBC2.set');
out   = fullfile(C.ica_tebc, 'PL38_TEBC.vhdr');

hdr  = ft_read_header(part1);
dat1 = ft_read_data(part1); evt1 = ft_read_event(part1);
dat2 = ft_read_data(part2); evt2 = ft_read_event(part2);

for i = 1:numel(evt2)
    if ~isempty(evt2(i).sample), evt2(i).sample = evt2(i).sample + size(dat1, 2); end
end

% Give both event structures the same fields before concatenating
fields = unique([fieldnames(evt1); fieldnames(evt2)]);
for k = 1:numel(fields)
    if ~isfield(evt1, fields{k}), [evt1.(fields{k})] = deal([]); end
    if ~isfield(evt2, fields{k}), [evt2.(fields{k})] = deal([]); end
end
evt = [evt1(:); orderfields(evt2(:), evt1)];

ft_write_data(out, cat(2, dat1, dat2), 'header', hdr, 'event', evt);
