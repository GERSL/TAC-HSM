function clearStackData(folderpath_cold, msg)
%CLEARSTACKDATA Clear all the stack data after change detection process finished.
%
% INPUT:
%
%   folderpath_cold:        Locate to COLD working folder, in which the
%                           change folder <TSFitLine> is necessery, and
%                           this folder was created by <COLD.m>.
%
%   msg (optional)          [false/true] Display processing status (default
%                           value: false)

% folderpath_cold = '/lustre/scratch/qiu25856/TestGERSToolbox/h029v005';

if ~exist('msg', 'var')
    msg = false;
end

[~, foldername_working] = fileparts(folderpath_cold);

if msg
    fprintf('Start to clear the stack dataset for %s\r\n', foldername_working);
end

folderpath_stack = fullfile(folderpath_cold, 'StackData');

%% check the stack folder <StackData>, and if no, just return
if ~isfolder(folderpath_stack)
    if msg
        fprintf('Already no the stack dataset for %s\r\n', foldername_working);
    end
    return;
end

folderpath_tsf = fullfile(folderpath_cold, 'TSFitLine');
alldone = true; % label for all process done


%% Check the results in <TSFitLine>
% too slow to once delete all the dataset
load(fullfile(folderpath_cold, 'metadata.mat'));
files_reg = dir(fullfile(folderpath_tsf, 'record_change*.mat'));
if length(files_reg) == metadata.nrows
    tic
    rmdir(folderpath_stack, 's');
    if msg
        fprintf('Finished deleting the folder <StackData> of %s with %0.2f mins\r\n', foldername_working, toc/60); 
    end
end

%% Check the results in <TSFitLine> row by row
stackrows = dir(fullfile(folderpath_stack, 'R*'));%% Locate to a certain task, one task for one row folder
for irf = 1:length(stackrows)
    % according to the name of stacking row dataset, the rows # at start and
    % end can be known well.
    foldername_stackrows = stackrows(irf).name;
    % name format: R xxxxx xxxxx
    row_start = str2num(foldername_stackrows(2:6));
    row_end = str2num(foldername_stackrows(7:11));
    rows = row_start: row_end; 
    folderpath_stackrows = fullfile(folderpath_stack, foldername_stackrows);
    
    %% check exsiting record files, and remain the id of the rows that have no results
    ids_more = [];
    for ir = 1: length(rows)
        filepath_rcg = fullfile(folderpath_tsf, sprintf('record_change_r%05d.mat', rows(ir))); % r: row
        if isfile(filepath_rcg)
            ids_more = [ids_more; ir];
            continue;
        else
            alldone = false;
        end
    end
    rows(ids_more) = [];
    
    % if all the rows at current task are well done, just skip to next
    % process
    if isempty(rows)
        tic
        rmdir(folderpath_stackrows, 's');
        if msg
            fprintf('Finished deleting the stack dataset %s of %s with %0.2f mins\r\n', ...
                foldername_stackrows, foldername_working, toc/60); 
        end
    else
        if msg
            fprintf('\nSkip the stack dataset %s of %s since no change results for row #%s\n', ...
                foldername_stackrows, foldername_working, num2str(rows));
        end
    end
end
%% delete the folder <StackData> if all rows finished
if alldone
    rmdir(folderpath_stack, 's');
    if msg
        fprintf('Finished deleting the folder <StackData> of %s\r\n', foldername_working); 
    end
end

end

