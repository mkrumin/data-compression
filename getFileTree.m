function fileTree = getFileTree(root)

if nargin<1
    root = '\\znas.cortexlab.net\Subjects\';
end

fprintf('%s\n', root);
tmp = dir(root);
% Exclude the '.' and '..' folders from further recursion, as well as
% Recycle Bin
idxValid = ~ismember({tmp.name}, {'.', '..', '@Recycle', '.Trash-1000', '.phy'});
fileTree = tmp(idxValid);
for iFile = 1:numel(fileTree)
    if fileTree(iFile).isdir
        subRoot = fullfile(fileTree(iFile).folder, fileTree(iFile).name);
        fileTree(iFile).subTree = getFileTree(subRoot);
    end
end

