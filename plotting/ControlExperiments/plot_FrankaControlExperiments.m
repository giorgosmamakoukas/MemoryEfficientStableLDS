%%

clc; clear; close all;
color_order = get(gca,'colororder');

filename = '../../data/Franka_ControlExperiments';
load(filename);
X_d = desired_trajectory;
for i =  1 : 3
%     exp_file = [filename, num2str(i)];    
    
    figure(1);
    X = eval(['experiment', num2str(i),'.X']);
    U = eval(['experiment', num2str(i),'.U']);
    plot(X(:,2), X(:,3), 'linewidth', 1.0 ); 
    hold on;

    tt = 0: length(X) - 1;
    tt = tt * 1/50; % sampled at 50Hz
    figure(2);
    plot(tt, X(:,2), 'color', color_order(i,:)); hold on; plot(tt, X_d(:,2), '--k', 'linewidth', 1.5)

    plot(tt, X(:,3), 'color',  color_order(i,:)); hold on; plot(tt, X_d(:,3), '--k', 'linewidth', 1.5)
end

figure(1);
plot(X_d(:,2), X_d(:,3), '--k', 'linewidth', 1.5)

figure(2);
set(gcf, 'color', 'w')
set(gca,'FontSize',14)
xlabel('time (s)');
ylabel('y-z coordinates (m)');

figure(1);
set(gcf, 'color', 'w')
set(gca,'FontSize',14)
xlabel('y (m)');
ylabel('z (m)');
xlim([-0.35, 0.38])
