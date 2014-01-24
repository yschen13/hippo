function [t1 vels] = runTriggerView1d(pos,v,Xf,accumbins,thresh,r)
%% 1d binning of ICA activations on linear track

bounds = [.1 .9];
pos(pos == -1) = nan;
reject = 0;
for i = 1:size(pos,2)
    reject = reject | min([0; diff(pos(:,i))],flipud([0; diff(flipud(pos(:,i)))])) < -20;
end
pos(reject,:) = nan;
if size(v,1) < size(pos,1)
    pos = pos(1:size(v,1),:);
end
for i = 1:size(pos,2)
    nanInds = find(~isnan(pos(:,i)));
    pos(:,i) = interp1(nanInds,pos(nanInds,i),1:size(pos,1));
end
nanInds = isnan(pos(:,1));
if size(pos,2) > 2
    nanInds = nanInds | isnan(pos(:,3));
end
pos = pos(~nanInds,:);v = v(~nanInds,:);Xf = Xf(:,~nanInds);%sp = sp(:,~nanInds);
if size(pos,2) > 2
    vel = angVel(pos);
else
    vel = diff(pos);
    vel = sqrt(sum(vel.^2,2));
end
vel = [zeros(1,size(vel,2)); vel];
for i = 1:size(vel,2)
    vel(:,i) = filtLow(vel(:,i),1250/32,1);
end
vel = vel(:,1);
vel = vel/max(vel);inds = vel > thresh;
pos = bsxfun(@minus,pos,mean(pos));
[a,~,~] = svd(pos(:,1:2),'econ');pos = a;
for i = 1:2    
    pos(:,i) = pos(:,i) - prctile(pos(:,i),1);%min(pos(:,i));
    pos(:,i) = pos(:,i)/prctile(pos(:,i),99);%(max(pos(:,i)));
    pos(:,i) = max(0,min(pos(:,i),.9999));
    posd(:,i) = floor(pos(:,i)*accumbins(min(numel(accumbins),i)))+1;
end
Xf = [bsxfun(@times,Xf,exp(1i*angle(v(:,1))).')];
inds = bwmorph(inds,'dilate',20);
Xf = Xf(:,inds);posd = posd(inds,:);%veld = veld(inds,:);
pos = pos(inds,:);
if exist('r','var')
    r1 = pinv(r);
    t = r*Xf;%zscore(Xf,0,2);%
else
    t = Xf;
    r1 = ones(size(Xf,1));
end
clear Xf;
% %%FOR 1D TRACK
b = nan*ones(size(pos,1),1);
b(pos(:,1) < bounds(1)) = -1;b(pos(:,1) > bounds(2)) = 1;
nanInds = find(~isnan(b));
b = interp1(nanInds,b(nanInds),1:size(pos,1));
b = [0 diff(b)];
runs = bwlabel(b > 0);
w = watershed(b==0);
w(w == 0) = w(find(w == 0)-1);
w = w-1; 
m = accumarray(w'+1,[0; diff(pos(:,1))],[],@mean);
%posd(mod(w,2) ==1 ,1) = accumbins+posd(mod(w,2) ==1 ,1);% + 2*max(posd(:));
posd(ismember(w+1,find(m>0)) ,1) = accumbins+posd(ismember(w+1,find(m>0)),1);
runs1 = round(w/2);
inds = runs1 > 0 & runs1 <= max(runs);
t1 = zeros(size(t,1),max(runs),accumbins(1)*2);
dP = [0;diff(pos(:,1))];
vels = accumarray([runs1(inds); posd(inds,1)']',dP(inds),[max(runs) 2*accumbins(1)] ,@mean);
for j = 1:size(t,1)
         t1(j,:,:) = accumarray([runs1(inds); posd(inds,1)']',t(j,inds),[max(runs) 2*accumbins(1)] ,@mean);
         t1(j,:,:) = t1(j,:,:)*exp(1i*angle(mean(r1(:,j))));
end
%t1 = reshape(t1(:),size(t1));
%posInds = 1:size(r,1);
%tes = zeros(numel(posInds),max(runs),2*accumbins(1));
%for i = 1:numel(posInds)
%    te = reshape(t1(i,:),[max(runs) 2*accumbins(1)]);
%    u = r1(:,i);
%    tes(i,:,:) = te*exp(1i*angle(mean(u)));
%end