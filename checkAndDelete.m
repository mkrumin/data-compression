function success = checkAndDelete(binFileName, serverCbinName, localTmpFolder, decompCmd)

success = false;

serverChName = [serverCbinName(1:end-4), 'ch'];

fprintf('\t[%s] Copying .cbin locally (%3.1f GB)..', datestr(now, 'HH:MM:SS'), dir(serverCbinName).bytes/1024^3)
tic
copyfile(serverCbinName, localTmpFolder)
fprintf('.done [%g seconds]\n', toc)

fprintf('\t[%s] Copying .ch locally (%3.1f KB)..', datestr(now, 'HH:MM:SS'), dir(serverChName).bytes/1024)
tic
copyfile(serverChName, localTmpFolder)
fprintf('.done [%g seconds]\n', toc)

currentFolder = cd(localTmpFolder);
[~, cBinName, cBinExtension] = fileparts(serverCbinName);
cBinName = [cBinName, cBinExtension];
[~, fName, fExt] = fileparts(binFileName);
localBinName = fullfile(fileparts(cBinName), [fName, fExt]);
cmd = sprintf('%s %s -o %s --overwrite -nc', decompCmd, cBinName, localBinName);

fprintf('\t[%s] Decompressing .cbin locally..', datestr(now, 'HH:MM:SS'))
tic
[status, cmdout] = system(cmd);
fprintf('.done [%g seconds]\n', toc)
if status
    fprintf('\t Decompression failed with the following output\n%s\n', cmdout);
    return;
end

fprintf('\t[%s] Calculating MD5 hash for local .bin..', datestr(now, 'HH:MM:SS'))
tic
md5_local = GetMD5(localBinName, 'File');
fprintf('.done [%g seconds]\n', toc)
fprintf('\t\tMD5(local) = %s\n', md5_local);

fprintf('\t[%s] Calculating MD5 hash for remote .bin..', datestr(now, 'HH:MM:SS'))
tic
md5_remote = GetMD5(binFileName, 'File');
fprintf('.done [%g seconds]\n', toc)
fprintf('\t\tMD5(remote) = %s\n', md5_remote);

if isequal(md5_local, md5_remote)
    fprintf('\t[%s] The files are the same! Deleting the remote .bin file..', datestr(now, 'HH:MM:SS'))
    delete(binFileName);
    fprintf('.done\n');
    fprintf('\tDeleting all the local temporary files..');
    delete(localBinName);
    delete(cBinName);
    [~, fName,~] = fileparts(cBinName);
    delete([fName, '.ch']);
    fprintf('.done\n');
end

success = true;

cd(currentFolder);