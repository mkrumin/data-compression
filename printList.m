function printList(list)

for i = 1:length(list)
    fprintf('%s\n', fullfile(list(i).folder, list(i).name));
end