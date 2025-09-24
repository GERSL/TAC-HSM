% Load the CSV file
folderpath = '/gpfs/sharedfs1/zhulab/SCRATCH/kes20012/ProjectTACValidation/ClimateData/';
filename = fullfile(folderpath,'random_samples_10000.csv'); % Change this if your file has a different name
data = readtable(filename);

% Get the total number of rows
num_rows = height(data);
num_files = 100;
rows_per_file = num_rows / num_files;

% Ensure we are splitting correctly
if mod(num_rows, num_files) ~= 0
    error('The number of rows is not evenly divisible by 100.');
end

% Loop to create and save each file
for i = 1:num_files
    % Select the rows for the current file
    subset = data((i-1)*rows_per_file + 1 : i*rows_per_file, :);
    
    % Generate the filename with a three-digit index
    output_filename = sprintf('random_samples_set%03d.csv', i);
    
    % Write the subset to a new CSV file
    writetable(subset, fullfile(folderpath,'RandomSample',output_filename));
    
    fprintf('Created file: %s\n', output_filename);
end

fprintf('All 100 files have been successfully created.\n');
