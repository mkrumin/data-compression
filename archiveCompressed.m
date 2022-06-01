%% create list of compressed files and check their existence on tape
forArchiving = sort(alreadyCompressed);

tapeIndexFolder = 'C:\TapeIndex\';
listTape = cell(0);

jsonFiles = dir(fullfile(tapeIndexFolder, '*.json'));
for iJson = 1 : numel(jsonFiles)
    tree = readTreeFromJson(fullfile(jsonFiles(iJson).folder, jsonFiles(iJson).name));
    list = getFlatFileList(tree);
    listFullNames = fullfile({list.folder}, {list.name})';
    listTape = cat(1, listTape, listFullNames);
end

tmp = split(listTape, '\Subjects\');
listTape = tmp(:,2);

tmp = split(forArchiving, '\Subjects\');
listServer = tmp(:, 2);
ok2move = ismember(listServer, listTape);
forArchiving = forArchiving(ok2move);

% make a txt file with the list for e-mail
fid = fopen('forArchiving.txt', 'wt');
for iFile = 1:numel(forArchiving)
    fprintf(fid, '%s\n\r', forArchiving{iFile});
end
fclose(fid);
%%
serverRoot = '\\znas.cortexlab.net\Subjects\';
nFiles = numel(forArchiving);
animalNames = cell(nFiles, 1);
for iFile = 1:nFiles
tmp = split(strrep(forArchiving{iFile}, serverRoot, ''), '\');
animalNames{iFile} = tmp{1};
end
animalNames = unique(animalNames);
for iName = 1:numel(animalNames)
    disp(animalNames{iName})
end

%% create a list of files to be deleted

excludePattern = {'\\znas.cortexlab.net\Subjects\AL038\', '';...
    '\\znas.cortexlab.net\Subjects\AL039\', '';...
    '\\znas.cortexlab.net\Subjects\AL040\', '';...
    '\\znas.cortexlab.net\Subjects\AL041\', '';...
    '\\znas.cortexlab.net\Subjects\AL055\', '';...
    '\\znas.cortexlab.net\Subjects\AL056\', '';...
    '\\znas.cortexlab.net\Subjects\AL058\', '';...
    '\\znas.cortexlab.net\Subjects\AL059\', '';...
    '\\znas.cortexlab.net\Subjects\CB001\', 'audioVis';...
    '\\znas.cortexlab.net\Subjects\CB003\', 'audioVis';...
    '\\znas.cortexlab.net\Subjects\CB005\', 'audioVis';...
    '\\znas.cortexlab.net\Subjects\CB007\', '';...
    '\\znas.cortexlab.net\Subjects\CB008\', '';...
    '\\znas.cortexlab.net\Subjects\JF026\', '';...
    '\\znas.cortexlab.net\Subjects\JF028\', '';...
    '\\znas.cortexlab.net\Subjects\KS047\', '';...
    '\\znas.cortexlab.net\Subjects\KS048\', '';...
    '\\znas.cortexlab.net\Subjects\KS051\', '';...
    '\\znas.cortexlab.net\Subjects\KS052\', '';...
    '\\znas.cortexlab.net\Subjects\KS054\', '';...
    '\\znas.cortexlab.net\Subjects\KS055\', '';...
    '\\znas.cortexlab.net\Subjects\MR001\', '';...
    '\\znas.cortexlab.net\Subjects\MR003\', '';...
    '\\znas.cortexlab.net\Subjects\SP003\', '';...
    '\\znas.cortexlab.net\Subjects\SP004\', '';...
    '\\znas.cortexlab.net\Subjects\SP008\', '';...
    'hjskdhfksjdffhk', ''};

origRoot = '\\znas.cortexlab.net\Subjects\';
archiveRoot = '\\znas.cortexlab.net\Subjects\NPixArchive\';

nFiles = numel(forArchiving);
idxExclude = false(nFiles, 1);
exclSz = size(excludePattern);
for iFile = 1:nFiles
%     idxExclude(iFile) = contains(forArchiving{iFile}, excludePattern(:, 1)) && ...
%     contains(forArchiving{iFile}, excludePattern(:, 2), 'IgnoreCase', true);
    tmp = cellfun(@contains, repmat(forArchiving(iFile), exclSz), excludePattern);
    idxExclude(iFile) = any(tmp(:, 1) & tmp(:, 2));
end

files2Archive = forArchiving(~idxExclude);

%% Move the files to a separate folder before deleting them
% This will make things easier to purge from Recycle bin
for iFile = 1:numel(files2Archive)
    if ~isfile(files2Archive{iFile})
        sprintf('File %s not found\n', files2Archive{iFile})
        continue;
    end
    oldName = files2Archive{iFile};
    newName = strrep(oldName, origRoot, archiveRoot);
    archiveFolder = fileparts(newName);
    if ~isfolder(archiveFolder)
        mkdir(archiveFolder)
    end
    [status, msg, msgID] = movefile(oldName, newName);
    if ~status
        warning('Something went wrong with moving the file')
        warning(msg);
        fprintf('Stopping here to take a look\n')
        keyboard;
    end
end

%% Before deleting confirm that the files are already on tape
tapeIndexFolder = 'C:\TapeIndex\';
listTape = cell(0);

jsonFiles = dir(fullfile(tapeIndexFolder, '*.json'));
for iJson = 1 : numel(jsonFiles)
    tree = readTreeFromJson(fullfile(jsonFiles(iJson).folder, jsonFiles(iJson).name));
    list = getFlatFileList(tree);
    listFullNames = fullfile({list.folder}, {list.name})';
    listTape = cat(1, listTape, listFullNames);
end

tmp = split(listTape, '\Subjects\');
listTape = tmp(:,2);

tree = getFileTree(archiveRoot);
list = getFlatFileList(tree);
listFullNames = fullfile({list.folder}, {list.name})';

listArchive = strrep(listFullNames, archiveRoot, '');

ok2delete = ismember(listArchive, listTape);

% readTreeFromJson
