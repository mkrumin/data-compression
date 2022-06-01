function list = getFlatFileList(fileTree)

fprintf('%s\n', fileTree(1).folder);
% first add all the files at the current tree level
tmp = fileTree(~[fileTree.isdir]');
% remove all the unnecessary fields
list = rmfield(tmp, setdiff(fields(tmp), {'folder', 'name', 'bytes', 'date', 'datenum'}));
list = list(:);

% go through all the folders and concatenate their lists (recursively)
for iFile = find([fileTree.isdir])
    if ~isempty(fileTree(iFile).subTree)
        addThis = getFlatFileList(fileTree(iFile).subTree);
        if ~isempty(list)
%             size(list)
            list = cat(1, list, addThis(:));
        else
            list = addThis(:);
        end
    end
end