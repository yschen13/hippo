% showbfs.m - function to show basis functions
%
% function hout=showGrid(A,bg,h)
%
% A = bf matrix
% bg = 'black' or 'white' (default='black')

function hout=showGrid(A,gridsize,ratio,bg,h,clim)

if ~exist('bg','var') || isempty(bg)
  bg='black';
end

[L M]=size(A);
buf=1;
% sz=sqrt(L);
% 
% if floor(sqrt(M))^2 ~= M
%   n=sqrt(M/2);
%   m=M/n;
% else
%   m=sqrt(M);
%   n=m;
% end

%if size(A,2) == prod(gridsize)
%    n = gridsize(1);m = gridsize(2);
%else
    n = ceil(sqrt(size(A,2)));
    m = ceil(size(A,2)/n);
%end
sz = gridsize;

if bg=='black'
  array=-ones(buf+n*(sz(1)+buf),buf+m*(sz(2)+buf));
else
  array=ones(buf+n*(sz(1)+buf),buf+m*(sz(2)+buf));
end

k=1;

for j=1:m
  for i=1:n
    if k > size(A,2)
        break
    end
    if ~exist('clim','var') 
        clima=max(abs(A(:,k)));
    else
        clima = clim;
    end
    array(buf+(i-1)*(sz(1)+buf)+[1:sz(1)],buf+(j-1)*(sz(2)+buf)+[1:sz(2)])=...
	reshape(A(:,k),sz(1),sz(2))/clima;
    k=k+1;
    
  end
end
%colormap gray
%subplot(211)
x = 1:size(array,1);
y = 1:size(array,2);
x = x*ratio(1);y = y*ratio(2);
if ~exist('h','var') || isempty(h)
    if nargout>0
        hout=imagesc(x,y,array,[-1 1]);
    else
        imagesc(x,y,array,[-1 1])
    end
    axis off
else
    set(h,'CData',array)
    drawnow
end
% 
% subplot(212)
% 
% normA=sqrt(sum(A.*A));
% bar(normA), axis([0 M+1 0 max(normA)])
% title('basis norm (L2)')

drawnow
