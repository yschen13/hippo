function [a b inds] = crcns1(trace,f1,dims,ratio)
%this program visualizes spatial LFP in two frequency bands and 
%shows the direction in which they move.
%MODDED TO SHOW RAW LFP AND THETA FILTERED

global step
global h

Fs = 1250/5;
figure('Name','Traveling LFP waves in rat hippocampus');
trace = bsxfun(@minus,trace,mean(trace,2));
trace = bsxfun(@rdivide,trace,std(trace,0,2));
traceT = morFilter(trace,f1,Fs);%hipFilter(trace,f1(1),f1(2),Fs);%
HT = angle(traceT);%hilbert(traceT'))';
traceT = real(traceT);
center = dims([2 1])/2;
scale = 20;
numPast = 500;
histT = nan*ones(numPast,2);
step = 1;
%h = uicontrol('Style','slider','Position', [20 20 100 20],'Value',2,'Min',1,'Max',20, 'Callback',@fixStep);
%tRange = [min(traceT(:)) max(traceT(:))]; gRange = [min(traceG(:)) max(traceG(:))];
tRange = [-1 1]*sqrt(mean(var(traceT(:))))*2; orRange = [-1 1]*sqrt(mean(var(trace(:))))*2;
%colormap gray;
for i = 1:size(trace,2)
    [xt yt] = myGradient(reshape(HT(:,i),dims));
    xt = -xt;yt = flipud(yt);tm = [mean(xt(:)) mean(yt(:))];
    if mod(i,step) == 0
        histT = circshift(histT,[-1 0]);
        histT(numPast,:) = center([2 1]).*ratio+tm*scale;
        subplot('Position',[0 0 1 .48]);
        imagesc((1:dims(1))*ratio(1),(1:dims(2))*ratio(2),flipud(reshape(traceT(:,i),dims)),tRange*.8);hold on;axis off;
        %plot(histT(:,1),histT(:,2),'w','LineWidth',1.5);
        plot(histT(:,1),histT(:,2),'k','LineWidth',1.5);
        quiver(xt,yt,'k');
        %quiver(center(2)*ratio(1),center(1)*ratio(2),tm(1)*scale,tm(2)*scale,'w','LineWidth',5);
        quiver(center(2)*ratio(1),center(1)*ratio(2),tm(1)*scale,tm(2)*scale,'k--','LineWidth',5);
        hold off;
        subplot('Position',[0 .52 1 .48]);%s1);%1,2,2);
        imagesc((1:dims(1))*ratio(1),(1:dims(2))*ratio(2),flipud(reshape(trace(:,i),dims)),orRange*.8);axis off;
        drawnow;
    end
    if i > 1
    m(i-1) = getframe(gcf);
    end
end
movie2avi(m,'crcnsBL.avi');

function fixStep(a,b)
global step
global h
step = round(get(h,'Value'));
