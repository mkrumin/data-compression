function removeStuds(path)

% will recursively remove all the empty subfolders of path 
if nargin < 1
    path = 'F:\ProcessingTmp';
end
list = dir(path);
for iList = 1:numel(list)
    if list(iList).isdir 
        if isequal(list(iList).name, '.') || isequal(list(iList).name, '..')
            continue;
        end
        rmdirRec(fullfile(list(iList).folder, list(iList).name)); 
        success = rmdir(fullfile(list(iList).folder, list(iList).name));
    end
end

end


function rmdirRec(dirPath)
% will recursively remove all the empty subfolders of dirPath 
% and then the dirPath itself as well 
list = dir(dirPath);
for iList = 1:numel(list)
    if list(iList).isdir 
        if isequal(list(iList).name, '.') || isequal(list(iList).name, '..')
            continue;
        end
        rmdirRec(fullfile(list(iList).folder, list(iList).name));
        success = rmdir(fullfile(list(iList).folder, list(iList).name));
    end
end

end
