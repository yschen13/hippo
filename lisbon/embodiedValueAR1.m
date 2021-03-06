function [Vdd,Vm,runsBin,p] = embodiedValueAR1(x_num, x_cost, t_cost, alpha, valueScale, runs1)
%% plots an example of a value function and the associated bound, when you ...
%% have to move to the target
%% this function simulates trajectories in 1 dimension in response to a 
%% stimulus of constant intensity, sampled from a normal distribution with 
%% variance sig2. Evidence is accumulated with variance 1.

%% parameters:
%% x_num = number of steps it takes to reach either of the two targets from starting point.
%% x_cost = 2-element vector specifying cost of changing position or velocity
%% t_cost = specifies cost of elapsed time.
%% runs1 = an N trials x T timesteps matrix of evidence accumulation trajectories, 
%%          allowing one to compare different parameter settings for trials with the same noise
%% To do:
%% 1) Implement y-direction
%% 2) implement uncertainty about where action places you in next time step
%% 3) Implement contribution of change in acceleration to movement cost

%% settings
if nargin < 1, x_num = 1; end %number of steps needed to move to either L or R target
if nargin < 2, x_cost = [0.1 0]; end;% cost for changing position and velocity
if nargin < 3, t_cost = .1; end % cost of time proceeding
g_num = 10; % discretisation of belief
T = 1; %Time limit on trial
sig2 = .5^2; %prior on variance of input intensity
dt = .05;%0.0125; %time step
ord = 1; %number of time steps in the past that contribute to cost (not yet implemented for ord > 1)

%% inline function to change a matrix into a vector
makeFlat = @(x) x(:);

%% time steps
ts = 0:dt:T;
N = length(ts);

%% First run many simulated trials to generate evidence accumulation trajectories,
%% used to tabulate the probability of making the correct choice, given the current
%% level of evidence and time. It is also used to tabulate the probability of attaining
%% a level of evidence, given the current level of evidence and time.
nInstances = 1000;
numAccum = 100; %number of times to sample nInstances trajectories
x = meshgrid((1:N)-1,1:nInstances); %index passage of time for each trajectory
Vd = zeros(N,g_num,x_num*2+1); %Value of being at a certrain time+evidence+position
ggOr = 0; %The probability of transitioning from evidence_t to evidence_t+1
Vhist = 0; 


for i = 1:numAccum
    runs = randn(nInstances,length(ts)-1)*sqrt(dt);
    rates = randn(nInstances,1)*sqrt(sig2)*dt;%(floor(rand(nInstances,1)*2)-.5)*dt/3;%
    runs = [zeros(nInstances,1) bsxfun(@plus,runs,rates)];
    runs = cumsum(runs,2);
    isRight = bsxfun(@times,ones(size(runs)),sign(rates))/2+.5;
    Vd(:,:,end) = squeeze(Vd(:,:,end)) + accumarray([x(:)+1 binFun(makeFlat(runs(:)),g_num)],isRight(:),[N g_num],@sum);
    Vhist = Vhist + accumarray([x(:)+1 binFun(makeFlat(runs(:)),g_num)],ones(1,numel(isRight)),[N g_num]);
    ggOr = ggOr + accumarray([makeFlat(x(:,1:end-1))+1 binFun(makeFlat(runs(:,1:end-1)),g_num) ...
        binFun(makeFlat(runs(:,2:end)),g_num)],ones(1,(N-1)*nInstances),[N-1 g_num g_num]);
end
Vd(:,:,end) = squeeze(Vd(:,:,end))./Vhist;
%runs = binFun(runs,g_num);
%for i = 1:size(ggOr,2)
%     for j = 1:size(ggOr,3)
%         ggOr(:,i,j) = filtfilt(gausswin(7),sum(gausswin(7)),ggOr(:,i,j));
%
%end
Vd(:,:,end) = meshgrid((1:size(Vd,2))-1,1:size(Vd,1))/(size(Vd,2)-1); %ADDED TO SIMPLIFY VISUALIZATION
Vd(isnan(Vd)) = 0.5;
% for i = 1:size(Vd,2)
%     Vd(:,i,end) = filtfilt(gausswin(.25/dt),sum(gausswin(.25/dt)),Vd(:,i,end));
% end

Vd(:,:,1) = 1-Vd(:,:,end);
Vd = Vd*valueScale;
ggOr = bsxfun(@rdivide, ggOr, sum(ggOr, 3)+eps);
Vm = NaN(N-1, g_num,x_num*2+1,x_num*2+1);
%Vdd = Vm;
Vdd = repmat(Vd,[1 1 1 size(Vd,3)]);
for i = N-1:-1:1
    timeCosts = -t_cost*dt*[0 ones(1,2*x_num-1) 0];   
    for j = 2:2*x_num
        evidence = squeeze(ggOr(i,:,:))*squeeze(Vdd(i+1,:,:,j));
        for k = 2:2*x_num
            moveCosts = -x_cost(1)*((1:2*x_num +1)-j).^2/x_num^2 - x_cost(2)*((1:2*x_num+1)-2*j+k).^2/x_num^2;
            [Vdd(i,:,j,k), Vm(i,:,j,k)] = max(evidence+repmat(moveCosts+timeCosts,[g_num 1]),[],2);
        end
    end
end
%alpha = 1.1;
%% make LMDP that approximates this
[x y] = meshgrid(1:size(Vd,3));
distCosts = exp(-x_cost(1)*((x-y).^2)/x_num^2);
distCosts = bsxfun(@rdivide,distCosts,sum(distCosts,2));
cost_nt = t_cost*dt;
temp = exp((alpha-1)*squeeze(-Vd(end,:,:)));%*size(Vd,1)
temp(:,2:end-1) = exp((alpha-1)*cost_nt);%-.5);%
zs(size(Vd,1),:) = temp(:);
for i = (size(zs,1)-1):-1:1
    temp = exp((alpha-1)*(-Vd(i,:,:)));%-cost_nt*i
    zs(i,:) = temp(:);
    pnt = kron(distCosts(2:end-1,:),squeeze(ggOr(i,:,:)));
    zs(i,(g_num+1):end-g_num) = exp((alpha-1)*(cost_nt))*pnt*zs(i+1,:)';%pinv(diag(exp(cost_nt*ones(1,size(zs,2)-2*g_num))))*
end
Vtest = squeeze(Vdd(:,:,:,2));
vls = log(zs)/(alpha-1);
%% make some example runs
if exist('runs1','var')
    runsBin = runs1;
else
    runsBin = binFun(runs,g_num);%round((tanh(runs)+1)/2*(50-1)+1);
end
p = nan*ones(size(runs,1),size(runs,2),ord+1);
p(:,1,:) = x_num+1;
for i = 2:size(runsBin,2)
    for j = 1:size(runsBin,1)
        p(j,i,1:end-1) = p(j,i-1,2:end);
        if p(j,i-1,end) > 1 && p(j,i-1,end) < x_num*2+1%~isnan(p(j,i-1,end)) %&& ~isnan(p(j,i-1,1))
            p(j,i,end) = Vm(i-1,runsBin(j,i-1),p(j,i-1,2),p(j,i-1,1));
        else
            p(j,i,end) = p(j,i-1,end);
        end
    end
end
%% attempt to derive trajectories from LMDP
pl = nan*ones(size(runs));
pl(:,1) = x_num+1;
pl1 = pl;
for i= 2:size(pl,2)
    pnt = kron(distCosts(2:end-1,:),squeeze(ggOr(i-1,:,:)));
    allU = pnt;%((g_num+1):end-g_num,:);
    for j = 1:size(pl,1)
        if pl(j,i-1) > 1 && pl(j,i-1) < x_num*2+1
            temp = allU((pl(j,i-1)-2)*g_num+runsBin(j,i-1),:).*exp(-vls(i,:));
            temp = nanmean(reshape(temp,g_num,[]));
            [~,pl(j,i)] = max(temp);
        else
            pl(j,i) = pl(j,i-1);
        end
        if pl1(j,i-1) > 1 && pl1(j,i-1) < x_num*2+1
            temp = allU((pl1(j,i-1)-2)*g_num+runsBin(j,i-1),:).*exp(Vtest(i,:));
            temp = nanmean(reshape(temp,g_num,[]));
            [~,pl1(j,i)] = max(temp);
        else
            pl1(j,i) = pl1(j,i-1);
        end
    end
end
figure;subplot(121);plot(pl(1:20,:)');
title(['\alpha=' num2str(alpha) ', reward=' num2str(valueScale) ',']); 
xlabel time; ylabel('position (LMDP)');axis tight;
subplot(122);plot(squeeze(p(1:20,:,end))');
title(['xcost=' num2str(x_cost(1)) ', tcost=' num2str(t_cost)]);
xlabel time;ylabel('position (MDP)');axis tight;
figure;subplot(211);plot(-vls(:,:)');axis tight;subplot(212);plot(Vtest(:,:)');axis tight;
figure;subplot(211);plot(-vls(:,:));axis tight;subplot(212);plot(Vtest(:,:));axis tight;
figure;subplot(211);imagesc(-vls(:,:));subplot(212);imagesc(Vtest(:,:));
% temp = permute(reshape(-vls,size(Vtest)),[1 3 2]);
% figure;subplot(211);plot(temp(:,:)');axis tight;title LMDP
% temp = permute(Vtest,[1 3 2]);
% subplot(212);plot(temp(:,:)');axis tight;title MDP
% ylabel Value; xlabel('Position / evidence');
return
%% try to reconstruct value function
sz = size(Vdd);sz = size(Vdd,1:3);
Vhat = zeros(sz);
%[xs,ys,zs] = ndgrid(1:sz(1),1:sz(2),1:sz(3));
%xs = ndgrid(1:sz(1),1:size(p,1));
pT = squeeze(p(:,:,end));
b = accumarray([x(:) runsBin(:) pT(:)],ones(1,size(p,1)),[],@sum);
%pT = squeeze(p(:,:,1));
%a = accumarray([x(:) runsBin(:) pT(:)],ones(1,size(p,1)),[],@sum);
pxx = 1;

function f = loglikV(x,a,b,pxx)
f = a*x + b*log(pxx*exp(-x));   % Cost function

function dat = binFun(dat,nBins)
dat = round((tanh(dat)+1)/2*(nBins-1)+1);

%     pnt = zeros((size(Vd,3)-2)*g_num,size(Vd,3)*g_num);
%     for j = 2:size(Vd,3)-1
%         for k = 1:size(Vd,3)
%             pnt((j-2)*g_num+(1:g_num),(k-1)*g_num+(1:g_num)) = squeeze(ggOr(i,:,:))*distCosts(j,k);%exp(-(j-k)^2)/1.7726;
%         end
%     end