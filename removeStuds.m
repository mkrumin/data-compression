function removeStuds(path)

% will recursively remove all the empty subfolders of path 
if nargin < 1
    path = 'D:\ProcessingTmp';
end
list = dir(path);
for iList = 1:numel(list)
    if list(iList).isdir 
        if isequal(list(iList).name, '.') || isequal(list(iList).name, '..') ||...
                isequal(list(iList).name, '@Recycle') || isequal(list(iList).name, '@Recently-Snapshot')
            continue;
        end
        fprintf('%s ..', list(iList).name);
        rmdirRec(fullfile(list(iList).folder, list(iList).name)); 
        success = rmdir(fullfile(list(iList).folder, list(iList).name));
        fprintf('. done\n');
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
