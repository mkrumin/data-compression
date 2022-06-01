function tbl = dupTable(dups, repoPath)

% only keep files that have the same hash
dupShort = dups([dups.eqHash]);
nDups = length(dupShort);
for iDup = 1:nDups
    % shorten the fileNames to be easier-readable
    dupShort(iDup).commonPath = strrep(dupShort(iDup).commonPath, repoPath, '');
    dupShort(iDup).fileA = strrep(dupShort(iDup).fileA, [repoPath, dupShort(iDup).commonPath], '');
    dupShort(iDup).fileB = strrep(dupShort(iDup).fileB, [repoPath, dupShort(iDup).commonPath], '');
    dupShort(iDup).sizeGB = dupShort(iDup).bytes/1024^3;
    %     dupShort(iDup).fileA = strrep(dupShort(iDup).fileA, [repoPath], '');
    %     dupShort(iDup).fileB = strrep(dupShort(iDup).fileB, [repoPath], '');
end
tbl = struct2table(dupShort);
