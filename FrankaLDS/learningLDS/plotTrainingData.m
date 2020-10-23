load('FrankaTrainingData.mat');
close all;
for i = 0 : 7
    plot(X((i*399)+1:399+i*399,2), X((i*399)+1:399+i*399,3), 'linewidth', 2)
    hold on;
end

% Run again for nicer colors haha
for i = 0 : 7
    plot(X((i*399)+1:399+i*399,2), X((i*399)+1:399+i*399,3), 'linewidth', 2)
    hold on;
end

xlabel('y (m)')
ylabel('z (m)')
set(gcf, 'color', 'w')
set(gca,'FontSize',16)