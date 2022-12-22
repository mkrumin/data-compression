function [success, summary, cmdOutput] = processSingleFile(remoteBinFile, p)

%% This is a NPix data compresson script
% Written by Michael Krumin, September 2021

success = false;
summary = struct;
cmdOutput = '';
processingStartTime = now;
fprintf('[%s] Starting processing\n', datestr(processingStartTime));
overallStartTime = tic;

remoteRoot = p.remoteRoot;
remoteRecycleRoot = p.remoteRecycleRoot;
% archiveRoot = p.archiveRoot;
localRoot = p.localRoot;
cmpCommand = p.compressionCommand;

if nargin < 1 || ~exist(remoteBinFile, 'file')
    if nargin<1
        fprintf('File name not provided\n');
    else
        fprintf('File provided doesn''t exist, check file name:\n''%s''\n', remoteBinFile);
    end
    warning('Exiting now, run again with a valid file name');
end


%% configure all file names and paths

if ~contains(remoteBinFile, remoteRoot)
    fprintf('The file appears to not be in a standard remote location ''%s''\n', remoteRoot)
    warning('Not implemented yet, exiting now');
end

[remoteFolder, fileName, fileExt] = fileparts(remoteBinFile);
if ~isequal(fileExt, '.bin')
    warning('File is not a ''.bin'' file, exiting');
end
localFolder = strrep(remoteFolder, remoteRoot, localRoot);
% archiveFolder = strrep(remoteFolder, remoteRoot, archiveRoot);
remoteRecycleFolder = strrep(remoteFolder, remoteRoot, remoteRecycleRoot);
binFileName = [fileName, fileExt];
cbinFileName = [fileName, '.cbin'];
chFileName = [fileName, '.ch'];
metaFileName = [strrep(fileName, '.ap_CAR', '.ap'), '.meta'];
logFileName = [fileName, '.mtscompLog.txt'];


%% copy files locally

startCopy = tic;
fprintf('[%s] Copying remote raw data files to a local temporary location...\n', datestr(now));
% first copy and parse metadata
copyVerbose(fullfile(remoteFolder, metaFileName), fullfile(localFolder, metaFileName));

%% figure out paths, filenames, parameters etc.

% AP data usually has a filename wildcard of '*.imec?.ap.bin' with ? being
% an integer (realistically single digit, in theory can be more)
% LFP data has similar filname format: '*.imec?.lf.bin'

try
    [sampleRate, nChans, dType] = parseMetaFile(fullfile(localFolder, metaFileName));
catch ME
    fprintf('parseMetaFile failed with the following message\n%s\n', ME.message)
    try
        disp(ME.stack(1));
    end
    return;
end

% if meta file is valid copy the neural data
copyVerbose(fullfile(remoteFolder, binFileName), fullfile(localFolder, binFileName));
timeCopy2Local = toc(startCopy);


%% run compression locally

currentFolder = cd(localFolder);

fileInfo = dir(binFileName);
commandString = sprintf('%s -d %s -s %d -n %d %s %s %s', cmpCommand, dType, sampleRate, ...
    nChans, binFileName, cbinFileName, chFileName);

startCompression = tic;
fprintf('[%s] Compressing %s [%3.1f GB]...\n', datestr(now), binFileName, ...
    fileInfo.bytes/1024^3);
diary off;
[cmdStatus, cmdOutput] = system(commandString, '-echo');
diary on;
% [cmdStatus, cmdOutput] = system(commandString);

fid = fopen(logFileName, 'wt');
fprintf(fid, '%s', cmdOutput);
fclose(fid);

if cmdStatus == 0
    timeCompression = toc(startCompression);
    durStr = durationString(timeCompression);
    fprintf('File %s was compressed in %s [%3.1f GB/h]\n', [fileName, fileExt], ...
        durStr, fileInfo.bytes/timeCompression/1024^3*3600);
else
    cd(currentFolder);
    warning('There was an issue with compression')
    warning('Check %s for more information', logFileName);
    fprintf('Here is the ouptut of mtscomp:\n')
    fprintf(cmdOutput);
    fprintf('\n');    warning('Aborting now');
    return;
end

cd(currentFolder);

%% copy compressed files to the server

startCopy = tic;
fprintf('[%s] Copying compressed files to the server...\n', datestr(now));
copyVerbose(fullfile(localFolder, cbinFileName), fullfile(remoteFolder, cbinFileName));
copyVerbose(fullfile(localFolder, chFileName), fullfile(remoteFolder, chFileName));
copyVerbose(fullfile(localFolder, logFileName), fullfile(remoteFolder, logFileName));
timeCopy2Server = toc(startCopy);

%% confirm MD5 checksums of the compressed files after copying to server

fprintf('[%s] Calculating checksums after copying...\n', datestr(now));
startMD5 = tic;
localMD5 = GetMD5(fullfile(localFolder, chFileName), 'File');
remoteMD5 = GetMD5(fullfile(remoteFolder, chFileName), 'File');
if ~isequal(localMD5, remoteMD5)
    warning('Compressed files did not copy properly to the server')
    warning('Check %s ', fullfile(remoteFolder, chFileName));
    warning('Aborting now');
    return;
end

localMD5 = GetMD5(fullfile(localFolder, cbinFileName), 'File');
remoteMD5 = GetMD5(fullfile(remoteFolder, cbinFileName), 'File');
if ~isequal(localMD5, remoteMD5)
    warning('Compressed files did not copy properly to the server')
    warning('Check %s ', fullfile(remoteFolder, cbinFileName));
    warning('Aborting now');
    return;
end
timeMD5 = toc(startMD5);

%% move original files to archive server, including all the folder structure
% the purpose of moving to the archive server is to save the data to tape
% from there (if we are paranoid enough)
% another option is to delete the data altogether - more reasonable option,
% after we make sure we know how to work with compressed data and are happy
% with it.

startCopy = tic;
% fprintf('[%s] Copying raw data files to archive...\n', datestr(now));
% copyVerbose(fullfile(localFolder, binFileName), fullfile(archiveFolder, binFileName));
% copyVerbose(fullfile(localFolder, metaFileName), fullfile(archiveFolder, metaFileName));
timeCopy2Archive = toc(startCopy);

rawInfo = dir(fullfile(localFolder, binFileName));
compInfo = dir(fullfile(localFolder, cbinFileName));

%% delete files

fprintf('[%s] Deleting local files...\n', datestr(now));
fprintf('%s\n', binFileName); delete(fullfile(localFolder, binFileName));
fprintf('%s\n', metaFileName); delete(fullfile(localFolder, metaFileName));
fprintf('%s\n', cbinFileName); delete(fullfile(localFolder, cbinFileName));
fprintf('%s\n', chFileName); delete(fullfile(localFolder, chFileName));
fprintf('%s\n', logFileName); delete(fullfile(localFolder, logFileName));
[status,msg,msgID] = rmdir(localFolder);
if ~status
    fprintf('Local folder %s was not removed\n', localFolder);
    warning(msg)
end
fprintf('[%s] Moving raw data files on the server to Recycle Bin...\n', datestr(now));
% fprintf('Relax, that is not actually happening at the moment during the testing phase\n')
fprintf('%s\n', binFileName); 
mkdir(remoteRecycleFolder);
[status,msg,msgID] = movefile(fullfile(remoteFolder, binFileName), fullfile(remoteRecycleFolder, binFileName));
if ~status
    warning('File was not moved to Recycle Bin with the following message:')
    warning('%s', msg);
    warning('Will not abort, but you should check manually');
    movedToRecycle = false;
else
    movedToRecycle = true;
end


%% we are done

totalTime = toc(overallStartTime);
durStr = durationString(totalTime);
fprintf('Job done! It took %s to compress %3.1f GB into %3.1f GB [%3.1f GB/h, %3.1f%%]\n\n', ...
    durStr, rawInfo.bytes/1024^3, compInfo.bytes/1024^3, ...
    rawInfo.bytes/1024^3/totalTime*3600, compInfo.bytes/rawInfo.bytes*100);

summary.fileName = remoteBinFile;
summary.startTime = processingStartTime;
summary.endTime = now;
summary.fileSize = rawInfo.bytes;
summary.compressedSize = compInfo.bytes;
summary.copyingTime = timeCopy2Local + timeCopy2Server + timeCopy2Archive;
summary.md5CheckTime = timeMD5;
summary.compressionTime = timeCompression;
summary.movedToRecycle = movedToRecycle;


success = true;
end % end of main function

%%=========================================================================

function copyVerbose(source, destination)

fileInfo = dir(source);
[~, fileName, fileExt] = fileparts(source);
fileName = [fileName, fileExt];
copyStart = tic;
if ~exist(fileparts(destination), 'dir')
    mkdir(fileparts(destination));
end

fprintf('[%s] Copying %s...\n', datestr(now), fileName);
[success,msg,msgID] = copyfile(source, destination);

if success
    copyTime = toc(copyStart);
    fprintf('[%s] Finished copying\n', datestr(now));
    fprintf('%s was successfully copied from\n%s\nto\n%s\n', fileName, ...
        fileparts(source), fileparts(destination))
    durStr = durationString(copyTime);
    fprintf('It took %s [%3.1f MB/s]\n', durStr, fileInfo.bytes/copyTime/1024^2);
else
    fprintf('\n');
    warning('There was a problem copying the file:')
    warning(msg);
    warning('Investigate, will abort now');
end

end

%% ==================================================
function outStr = durationString(durInSeconds)

tHours = floor(durInSeconds/3600);
tMins = floor((durInSeconds - tHours * 3600)/60);
tSecs = mod(durInSeconds, 60);
outStr = sprintf('%1dh:%02dm:%02.0fs', tHours, tMins, tSecs);

end

%%========================================================================

function [sampleRate, nChans, dType] = parseMetaFile(metaFile)

% [folderName, fileName, extension] = fileparts(metaFile);
% metaFileName = fullfile(folderName, [fileName, '.meta']);
fID = fopen(metaFile, 'rt');
meta = struct;
while ~feof(fID)
    tLine = fgetl(fID);
    info = split(tLine, '=');
    %remove tildas from the parameter names
    fieldName = strrep(info{1}, '~', '');
    meta.(fieldName) = info{2};
end
fclose(fID);

sampleRate = str2double(meta.imSampRate);
nChans = str2double(meta.nSavedChans);
dur = str2double(meta.fileTimeSecs);
fSize = str2double(meta.fileSizeBytes);

bitsPerSample = 8 * fSize/(sampleRate * nChans * dur);
tol = 1e-9;
if abs(bitsPerSample - 16) < tol
    dType = 'int16';
else
    dType = '';
    fprintf('The data bitdepth seems to be off, not 16 bits. Check manually\n')
    fprintf('sampleRate = %7.5f [samples/s]\n', sampleRate);
    fprintf('nChans = %3d\n', nChans);
    fprintf('dur = %7.5f [s]\n', dur);
    fprintf('fSize = %10d [bytes]\n', fSize);
    fprintf('bitsPerSample = %12.10f\n', bitsPerSample);
    fprintf('It might be necessary to adjust premitted precision tolerance\n');
    error('Returning empty ''dType'', mtscomp will exit with an exception');
end

% we need an integer value, rounding to the nearest 10 Hz to get nominal
% sampling rate (not calibrated)
sampleRate = round(sampleRate/10) * 10;

end
