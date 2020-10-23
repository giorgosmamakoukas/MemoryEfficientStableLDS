clear; close all; clc; 

load('steamLDS.mat');
steam = load('steam');

writerObj = VideoWriter('test.mp4', 'MPEG-4');
writerObj.FrameRate = 10;
open(writerObj);

figure(1)
set(gcf,'Position',[100 50 1200 900])%set dimensions of figure

for i = 1 : 10 : 1000
    subplot(2,4,[2 3]);
    I_ls = U * LS.A^i * X0;
    I_cg = U * CG.A^i * X0;
    I_wls = U * WLS.A^i * X0; 
    I_soc = U * SUB.A^i * X0;
    
    subplot(2,4,[2 3]);

     if i <= 100
        imshow(reshape(steam.data(:,i), [170, 120])'); title('Original', 'FontSize', 26);
     else
        imshow(reshape(steam.data(:,100), [170, 120])');  title('Original', 'FontSize', 26);
    end
    subplot(2,4,5); imshow(reshape(I_ls, [170, 120])'); title('Least Squares', 'FontSize', 20);    
    subplot(2,4,6); imshow(reshape(I_soc, [170, 120])'); title('SOC', 'FontSize', 20);
    
    subplot(2,4,7); imshow(reshape(I_wls, [170, 120])');  title('WLS', 'FontSize', 20);
    subplot(2,4,8); imshow(reshape(I_cg, [170, 120])'); title('CG', 'FontSize', 20);    

    timeFrame = ['Frames: ', num2str(i+9)]; 
    text(-320,-100, timeFrame, 'FontSize', 26);
    pause(0.01);
    writeVideo(writerObj,getframe(gcf));

end
close(writerObj);
