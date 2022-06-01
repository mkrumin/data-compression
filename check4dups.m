function dupList = check4dups(fileList, fileList2)

hashSize = 1e7; % number of 'doubles' to load for calculating hash
dupList = struct();
iDup = 0;

if nargin == 1
    nFiles = numel(fileList);
    for iFile = 1:nFiles-1
        for jFile = iFile+1 : nFiles
            if isequal(fileList(iFile).name, fileList(jFile).name) && ...
                    fileList(iFile).bytes == fileList(jFile).bytes

                iDup = iDup + 1;

                lenA = length(fileList(iFile).folder);
                lenB = length(fileList(jFile).folder);
                minLen = min(lenA, lenB);
                pathCmp = [fileList(iFile).folder(1:minLen) == fileList(jFile).folder(1:minLen), false];
                dupList(iDup).commonPath = fileList(iFile).folder(1:find(~pathCmp, 1, 'first')-1);

                dupList(iDup).fileA = fullfile(fileList(iFile).folder, fileList(iFile).name);
                dupList(iDup).fileB = fullfile(fileList(jFile).folder, fileList(jFile).name);
                dupList(iDup).bytes = fileList(iFile).bytes;

                % if the filenames and sizes are the same let's check other
                % parameters as well
                dupList(iDup).eqDate = fileList(iFile).datenum == fileList(jFile).datenum;

                fid = fopen(fullfile(fileList(iFile).folder, fileList(iFile).name), 'r');
                iData = fread(fid, [hashSize, 1], 'double');
                fclose(fid);
                fid = fopen(fullfile(fileList(jFile).folder, fileList(jFile).name), 'r');
                jData = fread(fid, [hashSize, 1], 'double');
                fclose(fid);
                dupList(iDup).eqHash =  isequal(GetMD5(iData), GetMD5(jData));

                % check if corresponding metadata and lfp data files exist in
                % the same folder (can be useful to figure out which one is the
                % original)
                metaA = isfile(fullfile(fileList(iFile).folder, [fileList(iFile).name(1:end-3), 'meta']));
                metaB = isfile(fullfile(fileList(jFile).folder, [fileList(jFile).name(1:end-3), 'meta']));
                lfpA = isfile(fullfile(fileList(iFile).folder, [fileList(iFile).name(1:end-6), 'lf.bin']));
                lfpB = isfile(fullfile(fileList(jFile).folder, [fileList(jFile).name(1:end-6), 'lf.bin']));

                dupList(iDup).metaA = metaA;
                dupList(iDup).metaB = metaB;
                dupList(iDup).lfpA = lfpA;
                dupList(iDup).lfpB = lfpB;

            end
        end
    end
elseif nargin == 2
    nFiles = numel(fileList);
    nFiles2 = numel(fileList2);
    for iFile = 1:nFiles
        for jFile = 1 : nFiles2
            if isequal(fileList(iFile).name, fileList2(jFile).name) && ...
                    fileList(iFile).bytes == fileList2(jFile).bytes

                iDup = iDup + 1;

                lenA = length(fileList(iFile).folder);
                lenB = length(fileList2(jFile).folder);
                minLen = min(lenA, lenB);
                pathCmp = [fileList(iFile).folder(1:minLen) == fileList2(jFile).folder(1:minLen), false];
                dupList(iDup).commonPath = fileList(iFile).folder(1:find(~pathCmp, 1, 'first')-1);

                dupList(iDup).fileA = fullfile(fileList(iFile).folder, fileList(iFile).name);
                dupList(iDup).fileB = fullfile(fileList2(jFile).folder, fileList2(jFile).name);
                dupList(iDup).bytes = fileList(iFile).bytes;

                % if the filenames and sizes are the same let's check other
                % parameters as well
                dupList(iDup).eqDate = fileList(iFile).datenum == fileList2(jFile).datenum;

                fid = fopen(fullfile(fileList(iFile).folder, fileList(iFile).name), 'r');
                iData = fread(fid, [hashSize, 1], 'double');
                fclose(fid);
                fid = fopen(fullfile(fileList2(jFile).folder, fileList2(jFile).name), 'r');
                jData = fread(fid, [hashSize, 1], 'double');
                fclose(fid);
                dupList(iDup).eqHash =  isequal(GetMD5(iData), GetMD5(jData));

                % check if corresponding metadata and lfp data files exist in
                % the same folder (can be useful to figure out which one is the
                % original)
                metaA = isfile(fullfile(fileList(iFile).folder, [fileList(iFile).name(1:end-3), 'meta']));
                metaB = isfile(fullfile(fileList2(jFile).folder, [fileList2(jFile).name(1:end-3), 'meta']));
                lfpA = isfile(fullfile(fileList(iFile).folder, [fileList(iFile).name(1:end-6), 'lf.bin']));
                lfpB = isfile(fullfile(fileList2(jFile).folder, [fileList2(jFile).name(1:end-6), 'lf.bin']));

                dupList(iDup).metaA = metaA;
                dupList(iDup).metaB = metaB;
                dupList(iDup).lfpA = lfpA;
                dupList(iDup).lfpB = lfpB;

            end
        end
    end
    
end
