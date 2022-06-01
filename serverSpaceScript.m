fileSize = [znasList.bytes]';
fileDate = floor([znasList.datenum]');
%%
binSize = 1;
firstMonday = min(fileDate) - weekday(min(fileDate)) + 2;
subs = floor((fileDate - firstMonday)/binSize) + 1;
% increments in TB
deltaVolume = accumarray(subs, fileSize)/1024^4;
figure;
dateAxis = firstMonday + binSize*(0:numel(deltaVolume)-1);
startDateVec = [2021 07 05 0 0 0];

subplot(2, 1, 1);
stairs(dateAxis, deltaVolume, 'LineWidth', 2);
xlim([datenum(startDateVec), now])
% datetick('x', 1, 'keeplimits', 'keepticks')
h1 = gca;
% h.XTickLabelRotation = 45;
h1.XTickLabels = [];
title('Daily increment of space used by DRI/Subjects')
ylabel('Daily \Delta [TB]');
% xlabel('Date');
box off;
h1.FontSize = 12;

subplot(2, 1, 2);
startIdx = find(dateAxis == datenum(startDateVec));
stairs(dateAxis, cumsum(deltaVolume) - sum(deltaVolume(1:startIdx)), 'LineWidth', 2);
xlim([datenum(startDateVec), now])
h2 = gca;
datetick('x', 1, 'keeplimits', 'keepticks')
h2.XTickLabelRotation = 30;
title('Total space used by DRI/Subjects')
ylabel('Volume [TB]');
% xlabel('Date');
box off;
h2.FontSize = 12;





