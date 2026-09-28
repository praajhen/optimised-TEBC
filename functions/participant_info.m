function [id, age, group] = participant_info(name, C)
% PARTICIPANT_INFO  Participant ID, age group and training group from a file name.
% 'PL01_A.set' -> id 'PL01', age 'young'; 'PLe03_TEBC.edf' -> 'PLe03', 'older'.
[~, base] = fileparts(name);
id = extractBefore([base '_'], '_');
if startsWith(id, 'PLe'), age = 'older'; else, age = 'young'; end
if ismember(id, C.personalised)
    group = 'Personalised';
elseif ismember(id, C.control)
    group = 'Control';
else
    group = '';
end
end
