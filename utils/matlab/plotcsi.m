function [] = plotcsi( csi, nfft, normalize )
%PLOTCSI Summary of this function goes here
%   Detailed explanation goes here

csi_buff = fftshift(csi,2);             % Shift the zero frequency component
% csi_buff is matrix of complex number, to obtain the phase:
csi_phase = rad2deg(angle(csi_buff));   

% then, to obtain the magnitude:
for cs = 1:size(csi_buff,1)             % for cs = 1 until 1000 (size of csi)
    csi = abs(csi_buff(cs,:));          % csi = absolute value of csi_buff
    
    if normalize
        % right division (./) : divide each element of csi with maximum csi
        csi = csi./max(csi);
    end
    csi_buff(cs,:) = csi; % Now, csi_buff contain the magnitude instead of complex value
end

figure
x = -(nfft/2):1:(nfft/2-1); % x is number of subcarrier (eg. -32 to 31)

subplot(3,1,3)
% Display image in scaled colour
colormap(turbo)
imagesc([1 : size(csi_buff,1)],[min(x) max(x)],csi_buff.')
colorbar
% size(csi_buff,1) get the size of first dimension of csi_buff (1000)
% so y = [1 1000]
% imagesc syntax : imagesc(x,y,C)
myAxis = axis();
axis([0, size(csi_buff,1)+0.5, myAxis(3), myAxis(4)])
set(gca, 'Ydir', 'reverse')
xlabel('Packet Number')
ylabel('Subcarrier')

max_y = max(csi_buff(:));
for cs = 1:size(csi_buff,1)
    csi = csi_buff(cs,:);
    
    subplot(3,1,1)
    plot(x,csi);
    grid on
    myAxis = axis();
    axis([min(x)-0.5, max(x)+0.5, 0, max_y])
    xlabel('Subcarrier')
    ylabel('Magnitude')
    title('Channel State Information')
    text(max(x),max_y-(0.05*max_y),['Packet #',num2str(cs),' of ',num2str(size(csi_buff,1))],'HorizontalAlignment','right','Color',[0.75 0.75 0.75]);
    
    subplot(3,1,2)
    plot(x,csi_phase(cs,:));
    grid on
    myAxis = axis();
    axis([min(x)-0.5, max(x)+0.5, -180, 180])
    xlabel('Subcarrier')
    ylabel('Phase')
    disp('Press any key to continue..');
    waitforbuttonpress();
end
close

end

