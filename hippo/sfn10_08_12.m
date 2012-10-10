%% panel 3 - Demodulation demo
nSteps = 1000;
x = linspace(0,20*pi,nSteps);
y = exp(1i*x);
A = [zeros(200,1); ones(300,1); zeros(500,1)]/2+1;
win = 20;
A = filtfilt(gausswin(win),sum(gausswin(win)),A);
dP = [zeros(600,1); ones(300,1); zeros(100,1)]*-pi/2;
dP = filtfilt(gausswin(win),sum(gausswin(win)),dP);
z = A'.*exp(1i*(x+dP'));zd = -conj((z.*conj(y))*1i);
angCol = colormap('hsv');
c = ceil((angle(z)+pi)/(2*pi)*64);
figure;plot3(1:nSteps,real(y),imag(y),'k');
hold all;scatter3(1:nSteps,real(z),imag(z),[],bsxfun(@times,angCol(c,:),(A/max(A))),'filled');
sh = 4;
plot3(1:nSteps,real(y),imag(y)-sh,'k');
c = max(1,ceil((angle(zd)+pi)/(2*pi)*64));
hold all;scatter3(1:nSteps,real(zd),imag(zd)-sh,[],bsxfun(@times,angCol(c,:),(A/max(A))),'filled');
set(gca,'xtick',[],'ytick',[],'ztick',[],'linewidth',2);
%% panel 4/5
inds = 52965:53140;angCol = colormap('hsv');
%temp = filtLow(angVel(pos)',1250/32,2);
[posa,s,u] = svds(pos(:,1:2),1);
posa = s*posa;
temp = filtLow(diff(posa(inds)),1250/32,2);
indsa = inds(1)*4:inds(end)*4;
X1 = morFilter(X(:,indsa(1)-1000:indsa(end)+1000),8,1250/8);X1 = X1(:,1001:end-1000);
[u,s,v1] = svds(X1,1);
um = mean(abs(u)).*exp(1i*circ_mean(angle(u)));
v2 = um*s*v1';
%% panel 4
sub = 100:285;mA = max(max(abs(X1(:,sub))));
v1c = mean(abs(v2(sub)))*exp(1i*angle(v2(sub)));
figure;plot3((sub-min(sub))/1250*8,real(v1c),imag(v1c),'k');hold all;
sh = s/50;
plot3((sub-min(sub))/1250*8,real(v1c),imag(v1c)-sh,'k');hold all;
%X1d = bsxfun(@times,X1(:,sub),exp(1i*(-angle(v1c))));
X1d = exp(1i*angle(conj(u*s*v1(sub)'))).*X1(:,sub);
X1d = abs(X1d).*exp(1i*(angle(X1d) + pi/2));
for i = 1:size(X1,1)
    c = ceil((angle(X1(i,sub))+pi)/(2*pi)*64);
    scatter3((sub-min(sub))/1250*8,real(X1(i,sub)),imag(X1(i,sub)),[],bsxfun(@times,angCol(c,:),abs(X1(i,sub)')/mA),'filled');
    c = min(64,max(1,ceil((angle(X1d(i,:))+pi)/(2*pi)*64)));
    scatter3((sub-min(sub))/1250*8,real(X1d(i,:)),imag(X1d(i,:))-sh,[],bsxfun(@times,angCol(c,:),abs(X1(i,sub)')/mA),'filled');
end
%% panel 5
figure;subplot(411);plot(temp*1250/32,'k','linewidth',2);axis tight;
colorbar;set(gca,'xtick',[],'fontsize',16);title('Velocity');ylabel('cm/s');
subplot(412);imagesc(X(:,indsa));set(gca,'ytick',[1 64],'xtick',[],'fontsize',16);colormap jet;colorbar;freezeColors;title('Raw LFP');
subplot(413);imagesc(complexIm(X1,0,1));colorbar;set(gca,'ytick',[1 64],'xtick',[],'fontsize',16);ylabel('Channel #');title('Filtered Theta');
subplot(414);imagesc(linspace(0,size(X1,2)/1250*8,size(X1,2)),1:64,...bsxfun(@times,X1,exp(1i*angle(v1)'))
    complexIm(X1.*exp(1i*-angle(u*v1')),0,2,16));colorbar;set(gca,'ytick',[1 64],'xtick',1:4,'fontsize',16);...
    colormap hsv; freezeColors;title('Demodulated Theta');xlabel('Time (s)');

figure;subplot(4,1,2);imagesc(complexIm(v2,0,1));colorbar;axis off;
c = ceil(mod(angle(v2),2*pi)/(2*pi)*64);%(angle(v2*1i)+pi)
subplot(4,1,3);scatter(1:numel(v2),real(v2),[],angCol(c,:),'filled');
set(gca,'color','w','xtick',[],'ytick',[]);axis tight; colorbar;
%% panel 6