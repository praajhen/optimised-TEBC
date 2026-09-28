function files = tebc_eeg_files(folder)
% TEBC_EEG_FILES  ICA-cleaned TEBC recordings: *_TEBC.set, plus *_TEBC.vhdr
% for participants whose split recording was combined (tools/combine_split_recording.m).
files = dir(fullfile(folder, '*_TEBC.set'));
vhdr  = dir(fullfile(folder, '*_TEBC.vhdr'));
for i = 1:numel(vhdr)
    [~, base] = fileparts(vhdr(i).name);
    if ~any(strcmp({files.name}, [base '.set']))
        files = [files; vhdr(i)]; %#ok<AGROW>
    end
end
[~, order] = sort({files.name});
files = files(order);
end
