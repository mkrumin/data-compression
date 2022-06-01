p.remoteRoot = '\\128.40.224.65\Subjects\';
p.remoteRoot2 = '\\128.40.224.65\Subjects\@Recycle';

%% scrape the server for the file tree
serverTree = getFileTree(p.remoteRoot);
% convert the tree into a flat list (easier to analyze)
serverList = getFlatFileList(serverTree);
%% find all the suspects to be NPix recordings
fileNames = {serverList.name}';
% filenames should end with .ap.bin
pattern = '.ap.bin';
idx = false(size(fileNames));
for iFile = 1:numel(fileNames)
    try
        idx(iFile) = isequal(fileNames{iFile}(end-6:end), pattern);
    catch
    end
end
fileList = serverList(idx);

%% do the same for the second server as well
if isfield(p, 'remoteRoot2')
    serverTree2 = getFileTree(p.remoteRoot2);
    serverList2 = getFlatFileList(serverTree2);
    fileNames2 = {serverList2.name}';
    % filenames should end with .ap.bin
    pattern = '.ap.bin';
    idx = false(size(fileNames2));
    for iFile = 1:numel(fileNames2)
        try
            idx(iFile) = isequal(fileNames2{iFile}(end-6:end), pattern);
        catch
        end
    end
    fileList2 = serverList2(idx);
end

%% checking for duplicates within each server

tStart = tic;
fprintf('Looking for duplicates..');
duplicates = check4dups(fileList);
duplicates2 = check4dups(fileList2);
duplicates12 = check4dups(fileList, fileList2);
fprintf('.done (%g seconds)\n', toc(tStart))

%% full list of all potential duplicates
% these will be excluded from the compression pipeline for the timebeing

dupsFullList = [{duplicates.fileA}'; {duplicates.fileB}'; ...
    {duplicates2.fileA}'; {duplicates2.fileB}'; ...
    {duplicates12.fileA}'; {duplicates12.fileB}'];
dupsFullList = unique(dupsFullList);

%% create a report on duplicates
tt = dupTable(duplicates, p.remoteRoot);
tt2 = dupTable(duplicates2, p.remoteRoot2);
tt12 = dupTable(duplicates12, '');

%%
return;

idx = [duplicates12.eqHash];
sum([duplicates12(idx).bytes])/1024^4
for iFile = 1:length(duplicates12)
    
    if duplicates12(iFile).eqHash && contains(duplicates12(iFile).fileB, '\Subjects\@Recycle\')
    fprintf('%d Delete %s?\n', iFile, duplicates12(iFile).fileB);
%     pause
    delete(duplicates12(iFile).fileB)
    end
end


