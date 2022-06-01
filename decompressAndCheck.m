% this script will copy a .cbin file locally, decompress it, and, if there is an
% original raw file, compare to it using and MD5 checksum

addpath('C:\Users\Tape\Documents\MATLAB\GetMD5');
p.localRoot = 'F:\ProcessingTmp\';
p.remoteRoot = '\\znas.cortexlab.net\Subjects\';

remoteCbin = 
remoteCh = [remoteCbin(1:end-4), '.ch'];
remoteBin = [remoteCbin(1:end-4), '.bin'];

if contains(fileNameCbin, p.remoteRoot)
    localFolder = strrep(fileparts(remoteCbin), p.remoteRoot, p.localRoot);
    localCbin = strrep(remoteCbin, p.remoteRoot, p.localRoot);
    localCh = strrep(remoteCh, p.remoteRoot, p.localRoot);
else
    localFolder = p.localRoot;
    [ff, fn, fe] = fileparts(remoteCbin);
    localCbin = fullfile(localFolder, [fn, fe]))
end

