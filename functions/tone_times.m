function [tone_start_times] = tone_times(dataset_filename,erp_trials)
% TONE_TIMES  Tone onset sample for each accepted epoch (epochs start 200 ms
% before the tone, so the matching event lies within 220 samples).
 
  
event = ft_read_event(dataset_filename);
emptyValueIndices = find(arrayfun(@(x) isempty(x.value), event));  % Find indices of rows with empty event.values
event(emptyValueIndices) = []; % Remove rows with empty event.values
  

threshold = 220; % Maximum allowable difference

a = erp_trials.sampleinfo(:, 1);
b = [event.sample]';

tone_start_times = []; % Initialize the accepted matrix with NaN

for i = 1:length(a)
    for j = 1:length(b)
        difference = abs(a(i) - b(j));

        % Check if the difference meets the threshold
        if difference <= threshold
            tone_start_times(i) = b(j); % Save the value from 'b'
            break; % Exit the loop for this value of 'a'
        else
            % Check the next values in 'b'
            next_b_indices = (j + 1):length(b);
            next_differences = abs(a(i) - b(next_b_indices));
            valid_indices = next_b_indices(next_differences <= threshold);
            if ~isempty(valid_indices)
                tone_start_times(i) = b(valid_indices(1)); % Save the value from 'b'
                break; % Exit the loop for this value of 'a'
            end
        end
    end
end

tone_start_times = tone_start_times';