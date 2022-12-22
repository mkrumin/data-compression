%% This is a NPix data compresson script
% Written by Michael Krumin, September 2021

% run the whole script to create file lists, find duplicates etc.
% then manually run the last section of the script to actually start the
% pipeline (after inspecting the automatically generated lists)

% this repo: https://github.com/mkrumin/data-compression.git
addpath('C:\Users\Tape\Documents\GitHub\data-compression');
% get from here: https://github.com/DylanMuir/SlackMatlab.git
addpath('C:\Users\Tape\Documents\GitHub\SlackMatlab');
% from here: https://uk.mathworks.com/matlabcentral/fileexchange/25921-getmd5
addpath('C:\Users\Tape\Documents\MATLAB\GetMD5');

%% get Slack webhook for sending notifications

% text file with a slack incoming webhook, read more here:
% https://slack.com/apps/A0F7XDUAZ-incoming-webhooks?tab=more_info
% this works for now, but might get deprecated
fid = fopen('data-compression-webhook.txt');
slackWebhook = fgetl(fid);
fclose(fid);

%% generate hostname, useful when running multiple bots in parallel
[~, hostName] = system('hostname');
hostName = hostName(1:end-1);

%% defining main paths

p.remoteRoot = '\\zserver.cortexlab.net\Data\Subjects\';
% p.remoteRoot2 = '\\128.40.224.65\Subjects\';
% p.archiveRoot = 'B:\RawNPixArchive\';
% this is the place where raw bin files will be moved after compression
p.remoteRecycleRoot = '\\zserver.cortexlab.net\Data\@Recycle\NPixRaw\';
p.localRoot = 'F:\ProcessingTmp\';
p.logRoot = 'C:\NPixCompressionLogs\';
dbFile = fullfile(p.logRoot, 'compressionZserverDB.xlsx');
% include full path if not in the system path
p.compressionCommand = 'mtscomp';

% if ~isfolder(p.archiveRoot)
%     mkdir(p.archiveRoot);
% end
if ~isfolder(p.localRoot)
    mkdir(p.localRoot);
end
if ~isfolder(p.logRoot)
    mkdir(p.logRoot);
end

%% scrape the server for the file tree
tic
serverTree = getFileTree(p.remoteRoot);
toc
% convert the tree into a flat list (easier to analyze)
tic
serverList = getFlatFileList(serverTree);
toc
%% find all the suspects to be NPix recordings
fileNames = {serverList.name}';
% filenames should end with .ap.bin
pattern = '.ap_CAR.bin';
% pattern = 'temp_wh';
% pattern = 'continuous.dat';
% pattern = 'proc.dat';
% pattern = 'data.bin';
% pattern = '.npy';
% pattern = '2022-05-04';
idx = false(size(fileNames));
for iFile = 1:numel(fileNames)
    try
        idx(iFile) = isequal(fileNames{iFile}(end-length(pattern)+1:end), pattern);
%         idx(iFile) = contains(fileNames{iFile}, pattern);
%         idx(iFile) = isequal(fileNames{iFile}(1:7), pattern);
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
if isfield(p, 'remoteRoot2')
    duplicates2 = check4dups(fileList2);
    duplicates12 = check4dups(fileList, fileList2);
end
fprintf('.done (%g seconds)\n', toc(tStart))

%% full list of all potential duplicates
% these will be excluded from the compression pipeline for the timebeing

dupsFullList = [{duplicates.fileA}'; {duplicates.fileB}'];
if isfield(p, 'remoteRoot2')
dupsFullList = [dupsFullList; ...
    {duplicates2.fileA}'; {duplicates2.fileB}'; ...
    {duplicates12.fileA}'; {duplicates12.fileB}'];
end
dupsFullList = unique(dupsFullList);

%% create a report on duplicates
tt = dupTable(duplicates, p.remoteRoot);
if isfield(p, 'remoteRoot2')
    tt2 = dupTable(duplicates2, p.remoteRoot2);
    tt12 = dupTable(duplicates12, '');
end
% writetable(tt, 'zinu.csv')
% writetable(tt2, 'DRI.xlsx')
% writetable(tt12, 'znasDRI.xlsx')


%%


nFiles = length(fileList);
fileFullNames = cell(nFiles, 1);
[~, idx] = sort([fileList.datenum], 'ascend');
fileListSorted = fileList(idx);
for iFile = 1:nFiles
    %     fileListSorted(iFile).date = datestr(fileListSorted(iFile).datenum);
    fileListSorted(iFile).sizeGB = fileListSorted(iFile).bytes/1024^3;
    fileFullNames{iFile} = fullfile(fileListSorted(iFile).folder, fileListSorted(iFile).name);
end

hasMeta = false(nFiles, 1);
hasLFP = false(nFiles, 1);
hasLfpMeta = false(nFiles, 1);
hasCbin = false(nFiles, 1);
hasCh = false(nFiles, 1);
for iFile = 1:nFiles

    hasMeta(iFile) = isfile([fileFullNames{iFile}(1:end-8), '.meta']);
%     hasMeta(iFile) = isfile([fileFullNames{iFile}(1:end-4), '.meta']);
    hasLFP(iFile) = isfile([fileFullNames{iFile}(1:end-7), '.lf.bin']);
    hasLfpMeta(iFile) = isfile([fileFullNames{iFile}(1:end-7), '.lf.meta']);
    hasCbin(iFile) = isfile([fileFullNames{iFile}(1:end-4), '.cbin']);
    hasCh(iFile) = isfile([fileFullNames{iFile}(1:end-4), '.ch']);

end

%%
% can only process files with associated .meta file, otherwise parameters
% should be provided manually

% only compress files that have meta information and also were not already
% compressed (i.e. there is no .cbin and .ch file nearby)



candidates = fileFullNames(hasMeta & ~hasCbin);

% exceptionPatterns = {'\AL038\', '\AL039\', '\AL040\','\AL041\'};
exceptionPatterns = {'fakePatternThatWillNeverOccur'};
exceptionPatterns = {'30042019_data_npxcourse'};
exc = false(numel(candidates), 1);
for iFile = 1:numel(candidates)
    exc(iFile) = contains(candidates(iFile), exceptionPatterns);
end
exceptionsList = candidates(exc);

alreadyCompressed = fileFullNames(hasCbin & hasCh);
% exclude potential duplicates and files from the exceptions list
idx = ~ismember(candidates, dupsFullList);
idx2 = ~ismember(candidates, exceptionsList);
files2process = candidates(idx & idx2);
files2question = fileFullNames(~hasMeta);


%%

fprintf('Current free disk space status:\n');
fprintf('\t%3.1f GB on %s (temporary local processing location)\n', disk_free(p.localRoot)/1024^3, p.localRoot);
% fprintf('\t%3.1f TB on %s (staging for tape archival)\n', disk_free(p.archiveRoot)/1024^4, p.archiveRoot);
fprintf('\t%3.1f TB on %s (original raw data location)\n', disk_free(p.remoteRoot)/1024^4, p.remoteRoot);

return;

%%
filesAsStr = sprintf(['The following files will be compressed soon:\n```']);
for iFile = 1:min(15, numel(files2process))
    filesAsStr = sprintf('%s%s\n', filesAsStr, files2process{iFile});
end
filesAsStr = sprintf('%s```', filesAsStr);
% SendSlackNotification(slackWebhook, filesAsStr, [], 'data-compression-bot');
SendSlackNotification(slackWebhook, filesAsStr, [], hostName);

%%

nFilesTotal = numel(files2process);

for iFile = 5:nFilesTotal
    fullFileName = files2process{iFile};
    if ~isfile(fullFileName)
        % the file had already been processed by a different bot, probably
        continue;
    end
    [folder, file, ~] = fileparts(fullFileName);
    f = dir(fullFileName);
    % check if the file is being processed by a different bot
    % if not, label it as In PROGRESS
    flagFileName = fullfile(f.folder, [f.name, '_INPROGRESS']);
    if isfile(flagFileName)
        fID = fopen(flagFileName, 'r');
        processingHost = fgetl(fID);
        fclose(fID);
        if ~isequal(processingHost, hostName)
            % this file is being processed by a different bot
            % skip to the next file
            continue;
        end
    else
        % create a flag file, so that no oher bot will redo the job
        fID = fopen(flagFileName, 'wt');
        fprintf(fID, '%s', hostName);
        fclose(fID);
    end
    SendSlackNotification(slackWebhook, sprintf('[%s] Starting processing `%s` [%3.1f GB]\n', ...
        datestr(now), fullFileName, f.bytes/1024^3), [], hostName);
    diaryFullFile = fullfile(p.logRoot, sprintf('%s.%s.log', f.name, datestr(now, 'yyyymmdd_hhMMss')));
    diary(diaryFullFile);
    fprintf('[%s] Processing %s\n', datestr(now), fullFileName);
    fprintf('File size: %3.1f GB\n', f.bytes/1024^3);
    % lets check disk space available
    locOK = disk_free(p.localRoot) > f.bytes*1.65; % file size + 65% for compressed + meta
    fprintf('%3.1f GB available on local processing SSD (%s) - %s\n', disk_free(p.localRoot)/1024^3, ...
        p.localRoot, char(' OK'*locOK + 'BAD'*~locOK));
%     archOK = disk_free(p.archiveRoot) > f.bytes*1.05;
%     fprintf('%3.1f GB available in archive location (%s) - %s\n', disk_free(p.archiveRoot)/1024^3, ...
%         p.archiveRoot, char(' OK'*archOK + 'BAD'*~archOK));
    remoteOK = disk_free(p.remoteRoot) > (f.bytes*0.65 + 2*1024^4); % keep extra 2TB for other things
    fprintf('%3.1f GB available on the current server (%s) - %s\n', disk_free(p.remoteRoot)/1024^3, ...
        p.remoteRoot, char(' OK'*remoteOK + 'BAD'*~remoteOK));
%     if ~(locOK && archOK && remoteOK)
    if ~(locOK && remoteOK)
        fprintf('Not enough space in one of the locations, exiting now\n')
        SendSlackNotification(slackWebhook, sprintf('[%s] Not enough disk space, quitting\n', datestr(now)), [], 'data-compression-bot');
        diary off;
        % make sure the file is not blocked from being processed
        delete(flagFileName);
        break;
    end

    [success, summary, mtscompOutput] = processSingleFile(fullFileName, p);

    diary off

    % send Slack notification with summary
    if success
        msg = sprintf('Compression done!\n');
        msg = sprintf('%s```File: %s\n', msg, summary.fileName);
        msg = sprintf('%sOriginal size: %3.1f GB\n', msg, summary.fileSize/1024^3);
        msg = sprintf('%sCompressed size: %3.1f GB (%3.1f%%)\n', msg, ...
            summary.compressedSize/1024^3, summary.compressedSize/summary.fileSize*100);
        msg = sprintf('%sStart time: %s\n', msg, datestr(summary.startTime));
        msg = sprintf('%sEnd time: %s\n', msg, datestr(summary.endTime));
        msg = sprintf('%s```\n', msg);
        SendSlackNotification(slackWebhook, msg, [], hostName);

        % make datenums human readable
        summary.startTime = datestr(summary.startTime);
        summary.endTime = datestr(summary.endTime);

        % add an entry to the log database
        if isfile(dbFile)
            tbl = readtable(dbFile);
            tbl = cat(1, tbl, struct2table(summary));
        else
            tbl = struct2table(summary);
        end
        writetable(tbl, dbFile);
    else
        SendSlackNotification(slackWebhook, sprintf('[%s] Processing `%s` failed, check the logs: `%s`\n', ...
            datestr(now), fullFileName, diaryFullFile), [], hostName);
        fid = fopen(diaryFullFile, 'rt');
        str = fread(fid, '*char')';
        fclose(fid);
        %TODO - deal with long strings (Slack formatting breaks for strings
        %longer than ~3800 characters
%         lines = strsplit(str, char(13));
%         startIdx = 1:3800:(numel(str)-1);
%         endIdx = [startIdx(2:end) - 1,  
        SendSlackNotification(slackWebhook, sprintf('Log:\n```%s```\n', str), [], hostName);
        % add this file name to error log
        fid = fopen(fullfile(p.logRoot, 'failedList.txt'), 'at');
        fseek(fid, 0, 'eof');
        fprintf(fid, '[%s] %s\n', datestr(now), fullFileName);
        fclose(fid);
    end
    % in any case delete the INPROGRESS flag file
    delete(flagFileName);

    % check for STOP flag
    if isfile(fullfile(p.logRoot, 'STOP'))
        SendSlackNotification(slackWebhook, sprintf('[%s] STOP flag detected, exiting\n', datestr(now)), [], hostName);
        break;
    end
end

