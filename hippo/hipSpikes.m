function [spikeMat c] = hipSpikes(file,bin,subSet)

[a,b,c,d] = LoadCluRes(['/media/work/hippocampus/' file '/' file]);
a = ceil(a/d.SampleRate*1000/bin);
if ~exist('subSet','var')
    subSet = max(a);
else
    subSet = subSet*1000/bin;
end
subSet
b(a > subSet) = [];a(a > subSet) = [];
spikeMat = zeros(max(b),max(a));
for i = 1:max(b)
    temp = hist(a(b==i),1:(max(a)+1));
    spikeMat(i,:) = temp(1:(end-1));%a(b == i)) = 1;
end
