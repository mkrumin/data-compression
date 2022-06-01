%% create list of compressed files and check their existence on tape

serverRoot = '\\znas.cortexlab.net\Subjects\';
serverRecycleRoot = '\\znas.cortexlab.net\Subjects\@Recycle\TempWhDat\';
% serverRecycleRoot = '\\zinu.cortexlab.net\Subjects\TempWhDat\';
%%
forArchiving = sort(alreadyCompressed);
forArchiving = sort(files2question);
nFiles = numel(forArchiving);

%% Move the files to a separate folder before deleting them
% This will make things easier to purge from Recycle bin
for iFile = 1:nFiles
    if ~isfile(forArchiving{iFile})
        sprintf('File %s not found\n', forArchiving{iFile})
        continue;
    end
    oldName = forArchiving{iFile};
    newName = strrep(oldName, serverRoot, serverRecycleRoot);
    recycleFolder = fileparts(newName);
    if ~isfolder(recycleFolder)
        mkdir(recycleFolder)
    end
    [status, msg, msgID] = movefile(oldName, newName);
    if ~status
        warning('Something went wrong with moving the file')
        warning(msg);
        fprintf('Stopping here to take a look\n')
        keyboard;
    end
end

%% Before deleting confirm that the compressed files are already on the clone
serverRecycleRoot = '\\znas.cortexlab.net\Subjects\@Recycle\NPixRaw\';
serverRoot = '\\znas.cortexlab.net\Subjects\';
cloneRoot = '\\znasclone.cortexlab.net\Subjects\';

serverRecycleRoot = '\\zinu.cortexlab.net\Subjects\@Recycle\NPixRaw\';
serverRoot = '\\zinu.cortexlab.net\Subjects\';
cloneRoot = '\\zinuclone.cortexlab.net\Subjects\';

tic
fileTreeDelete = getFileTree(serverRecycleRoot);
toc
% convert the tree into a flat list (easier to analyze)
tic
fileListDelete = getFlatFileList(fileTreeDelete);
toc

%%
nFiles = numel(fileListDelete);
ok2delete = false(nFiles, 1);
sameMeta = false(nFiles, 1);
sizeReasonable = false(nFiles, 1);
filesOnClone = false(nFiles, 1);
for iFile = 1:nFiles
    fileName = fullfile(fileListDelete(iFile).folder, fileListDelete(iFile).name);
    fileCbinName = [fileName(1:end-3), 'cbin'];
    fileChName = [fileName(1:end-3), 'ch'];
    serverCbinName = strrep(fileCbinName, serverRecycleRoot, serverRoot);
    serverChName = strrep(fileChName, serverRecycleRoot, serverRoot);
    cloneCbinName = strrep(fileCbinName, serverRecycleRoot, cloneRoot);
    cloneChName = strrep(fileChName, serverRecycleRoot, cloneRoot);
    if exist(serverCbinName, "file") && ...
            exist(serverChName, "file") && ...
            exist(cloneCbinName, "file") && ...
            exist(cloneChName, "file")

        filesOnClone(iFile) = true;
        %check that the file metadata is the same on the server and clone
        if isequal(rmfield(dir(serverCbinName), 'folder'), ...
                rmfield(dir(cloneCbinName), 'folder'))
            sameMeta(iFile) = true;
        end
        if abs((dir(serverCbinName).bytes/dir(fileName).bytes) - 0.5) < 0.2
            % size is 30-70 % of the original
            sizeReasonable(iFile) = true;
        end
    end
    if sameMeta(iFile) && sizeReasonable(iFile) && filesOnClone(iFile)
        ok2delete(iFile) = true;
        fprintf('Deleting %s ..', fileName);
%         pause;
        delete(fileName)
        fprintf('\n');
    else
        fprintf('Skipping %s\n', fileName);
    end
end


