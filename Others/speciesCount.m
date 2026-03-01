%% Read the data
data = readtable('C:\ProjectTACValidation\data\FieldData\Species_9plots.csv');

% Display column names (check once if unsure)
disp(data.Properties.VariableNames);

%% ---- MODIFY IF COLUMN NAMES DIFFER ----
siteCol = 'Site';
speciesCol = 'Species';

%% Remove missing values
data = data(~ismissing(data.(siteCol)) & ~ismissing(data.(speciesCol)), :);

%% 1. Number of unique species per site
[uniqueSites, ~, siteIdx] = unique(data.(siteCol));
speciesPerSite = zeros(length(uniqueSites),1);

for i = 1:length(uniqueSites)
    siteSpecies = unique(data.(speciesCol)(siteIdx == i));
    speciesPerSite(i) = length(siteSpecies);
end

resultTable = table(uniqueSites, speciesPerSite, ...
    'VariableNames', {'Site','Number_of_Species'});

disp('Number of species per site:')
disp(resultTable)

%% 2. Total number of unique species across all sites
allUniqueSpecies = unique(data.(speciesCol));
totalUniqueSpecies = length(allUniqueSpecies);

fprintf('\nTotal number of unique species across all sites: %d\n', totalUniqueSpecies);

%% 3. List duplicate species (appear more than once in entire dataset)
[uniqueSpecies, ~, speciesIdx] = unique(data.(speciesCol));
speciesCounts = accumarray(speciesIdx, 1);

duplicateMask = speciesCounts > 1;
duplicateSpecies = uniqueSpecies(duplicateMask);
duplicateCounts = speciesCounts(duplicateMask);

duplicateTable = table(duplicateSpecies, duplicateCounts, ...
    'VariableNames', {'Species','Count'});

disp('Duplicate species (appearing more than once in dataset):')
disp(duplicateTable)
