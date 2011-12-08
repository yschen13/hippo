function complexMovies(w,s,gridDim,ratio,movName,speed)
%runs features generated by complex ICA through time

%[junk sorted] = sort(variance,'descend');

% vidObj = VideoWriter('bases.avi');
% vidObj.FrameRate = 10;
% open(vidObj);
if exist('movName','var')
    makeMov = 1;
else
    makeMov = 0;
end

h = figure;

if numel(s) == 0
    t = linspace(0,4*pi,50);%20
    s = repmat(cos(t) + 1i*sin(t),[size(w,2) 1]);
elseif exist('speed','var')
        for i = 1:size(s,1)
            s1(i,:) = decimate(s(i,:),speed);
        end
        s = s1;
end
w = w*diag(1./max(abs(w)));%sqrt(sum(w.*conj(w))));
% temp = zeros(size(s,2),size(w,2),size(w,1));
% for i = 1:size(s,2)
%     temp(i,:,:) = real(w'.*repmat(s(:,i),[1 size(w,1)]));
% end
% showJru(temp,gridDim,ratio);
while 1
    for j = 1:size(s,2)
        tic;
        figure(h);
        showGrid(real(w'.*repmat(s(:,j),[1 size(w,1)]))',gridDim,ratio,[],[],1);colormap('gray');
        if makeMov
            m(j) = getframe(gcf);%currframe;
        else
            pause(.05-toc);
        end
%        writeVideo(vidObj,currFrame)
    end
    if makeMov
        break
    end
end
if makeMov
    movie2avi(m,movName);
end
%close(vidObj);