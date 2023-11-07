%% Server stats script
% Written by Michael Krumin, October 2022

% this repo: https://github.com/mkrumin/data-compression.git
addpath('C:\Users\Michael\Documents\GitHub\data-compression');
% get from here: https://github.com/DylanMuir/SlackMatlab.git
addpath('C:\Users\Michael\Documents\GitHub\SlackMatlab');
% from here: https://uk.mathworks.com/matlabcentral/fileexchange/25921-getmd5
addpath('C:\Users\Michael\Documents\MATLAB\GetMD5');

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

p.remoteRoot = '\\zinu.cortexlab.net\Subjects\';

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
patterns = cell(0);
patterns{1} = '.ap.bin';
patterns{end+1} = '.ap.cbin';
patterns{end+1} = '.lf.bin';
patterns{end+1} = 'continuous.dat';
patterns{end+1} = 'temp_wh.dat';
patterns{end+1} = 'proc.dat';
patterns{end+1} = '.tif';
patterns{end+1} = 'data.bin';
patterns{end+1} = 'data_chan2.bin';
patterns{end+1} = '.mj2';
patterns{end+1} = '.nd2';
patterns{end+1} = '.npy';
patterns{end+1} = '.tar.bz';

%%
total = sum([serverList.bytes])/1024^4;
fprintf('Total for %s: %3.1f TB\n', p.remoteRoot, total)

for i = 1:numel(patterns)
    pattern = patterns{i};
    idx = false(size(fileNames));
    for iFile = 1:numel(fileNames)
        try
            idx(iFile) = isequal(fileNames{iFile}(end-length(pattern)+1:end), pattern);
            %         idx(iFile) = contains(fileNames{iFile}, pattern{1}) && contains(fileNames{iFile}, pattern{2});
            %         idx(iFile) = isequal(fileNames{iFile}(1:7), pattern);
        catch
        end
    end
    fileList = serverList(idx);
    sz = sum([fileList.bytes])/1024^4;
    fprintf('\t%s : %3.1f TB (%3.1f%%)\n', pattern, sz, sz/total*100)
end
%%
pattern = {'tcat', '.ap.bin'};
idx = false(size(fileNames));
for iFile = 1:numel(fileNames)
    try
        idx(iFile) = contains(fileNames{iFile}, pattern{1}) && contains(fileNames{iFile}, pattern{2});
    catch
    end
end
fileList = serverList(idx);
sz = sum([fileList.bytes])/1024^4;
fprintf('\t_%s_*%s : %3.1f TB (%3.1f%%)\n', pattern{1}, pattern{2}, sz, sz/total*100)

pattern = {'tcat', '.ap.cbin'};
idx = false(size(fileNames));
for iFile = 1:numel(fileNames)
    try
        idx(iFile) = contains(fileNames{iFile}, pattern{1}) && contains(fileNames{iFile}, pattern{2});
    catch
    end
end
fileList = serverList(idx);
sz = sum([fileList.bytes])/1024^4;
fprintf('\t_%s_*%s : %3.1f TB (%3.1f%%)\n', pattern{1}, pattern{2}, sz, sz/total*100)
