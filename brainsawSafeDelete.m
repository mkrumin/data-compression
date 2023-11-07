% this repo: https://github.com/mkrumin/data-compression.git
addpath('C:\Users\Tape\Documents\GitHub\data-compression');
% get from here: https://github.com/DylanMuir/SlackMatlab.git
addpath('C:\Users\Tape\Documents\GitHub\SlackMatlab');
% from here: https://uk.mathworks.com/matlabcentral/fileexchange/25921-getmd5
addpath('C:\Users\Tape\Documents\MATLAB\GetMD5');


%%

% folder2Purge = '\\znas.cortexlab.net\Brainsaw\@Recycle\BrainsawRawDataCompressed';
% clonePath = '\\znasclone.cortexlab.net\Subjects\BrainsawRawDataCompressed';
%
% files2Delete = dir(folder2Purge);
% files2Delete = files2Delete(~[files2Delete.isdir]);

folder2Purge = '\\znas.cortexlab.net\Brainsaw\@Recycle\Moved\ToZinuData';
clonePath = '\\zinuclone.cortexlab.net\Data\ALI-NY\histology';
folder2Purge = '\\znas.cortexlab.net\Subjects\@Recycle\LEW038_bkp';
clonePath = '\\znasclone.cortexlab.net\Subjects\LEW038';
files2Delete = subdir(folder2Purge);
files2Delete = files2Delete(~[files2Delete.isdir]);
[~, idx] = sort([files2Delete.bytes], 'descend');
files2Delete = files2Delete(idx);

nFiles = numel(files2Delete);

for iFile = 1:nFiles
    %     fileName = fullfile(files2Delete(iFile).folder, files2Delete(iFile).name);

    fileName = files2Delete(iFile).name;
    fprintf('[%d/%d] %s\n', iFile, nFiles, fileName)
    cloneFilename = strrep(fileName, folder2Purge, clonePath);
    if isfile(cloneFilename)
        fprintf('\tCalculating original MD5 ...');
        md5_orig = GetMD5(fileName, 'File');
        fprintf('\n\tOriginal MD5 is: %s\n', md5_orig);
        fprintf('\tCalculating MD5 on the clone ...');
        md5_clone = GetMD5(cloneFilename, 'File');
        fprintf('\n\tClone MD5 is: %s\n', md5_clone)
        if isequal(md5_clone, md5_orig)
            fprintf('\tMD5s are the same, deleting the local file..')
            delete(fileName);
            fprintf('.done\n')
        else
            fprintf('\tMD5s are different, skipping...\n')
        end
        fprintf('\n');
    else
        fprintf('\tNo file on clone, skipping\n');
    end
end