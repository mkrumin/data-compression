driveLetter = 'T';
label = DriveName(driveLetter);
targetFolder = 'C:\TapeIndex';
fileName = fullfile(targetFolder, sprintf('%s.json', label));

tree = getFileTree([driveLetter, ':']);
savejson(label, tree, fileName);

