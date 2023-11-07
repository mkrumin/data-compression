% this script is moving that weird *.ap.meta files that come up in the
% kilosort2 subfolder on AV rigs data, which are actually *.ap.bin files in
% disguise...
% Also checking that the *.ap.cbin file exists one folder up before moving
% to Recycle Bin

currentFolder = pwd
%%
% fileNames should include the full filenames of the files to be deleted
for iFile = 1:numel(fileNames)
    source = fileNames{iFile};
    fprintf('[%d/%d] %s\n', iFile, numel(fileNames), source)
    destination = strrep(source, '\\zinu.cortexlab.net\Subjects', '\\zinu.cortexlab.net\Subjects\@Recycle\NPixRawMeta');
    [folder, fName, fExt] = fileparts(source);
    cd(folder)
    cd ..
    if isfile([fName, '.cbin'])
        destDir = fileparts(destination);
        if ~isfolder(destDir)
            mkdir(destDir);
        end
        movefile(source, destination);
        fprintf('Moved\n')
    else
        fprintf('No .cbin file\n');
    end

end
%%
cd(currentFolder)