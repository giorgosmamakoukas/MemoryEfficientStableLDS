clear; clc; close all;

path_to_data = 'coffee_cup/'; % change directory to data

dims = [10, 20, 40, 60, 80, 100, 150, 200, 250, 300];
for i = 1 : length(dims)
    dim_i = dims(i);
    load([path_to_data, 'Memory_dim_', num2str(dim_i),'.mat']);
    SOCmem(i) = SOC.mem;
    CGmem(i) = CG.mem;
    WLSmem(i) = WLS.mem;
%     stableLS(i) = LS.stability
    clear WLS SOC CG
end

%%
close all;
KBToMB = 1/2^20;
semilogy(dims, CGmem * KBToMB, ':o', 'linewidth', 1.5); hold on;
semilogy(dims, WLSmem * KBToMB,'--*', 'linewidth', 1.5); hold on;
semilogy(dims, SOCmem * KBToMB, '-s', 'linewidth', 1.5); hold on;
semilogy(dims, dims.^4 * 8 * KBToMB,'--k', 'linewidth', 1.5); hold on;
semilogy(dims, dims.^2 * 8 * KBToMB,'--k', 'linewidth', 1.5);
xlabel('dimensions r')
ylabel('memory (MB)')

MBline = ones(length(dims(1) : dims(end)), 1); 
GBline = ones(length(dims(1) : dims(end)), 1) * 2^10;

hold on; plot(dims(1): dims(end), MBline, '--k');
hold on; semilogy(dims(1): dims(end), GBline, '--k');

text(260, 2.2^10, '1 GB', 'fontsize', 14);
text(260, 2.2, '1 MB', 'fontsize', 14);
text(200, 2.93^10, 'c_1r^4', 'fontsize', 14);
text(200, 0.1, 'c_1r^2', 'fontsize', 14);

set(gcf, 'color', 'w')
set(gca,'FontSize',14)
f = gca; 
grid on
legend('CG', 'WLS', 'SOC');
