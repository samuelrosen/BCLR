function a=autocorr(x, lags)
if ~all([length(size(x))==2 , ismember(1, size(x))]);
    error('x must be a vector');
end

if nargin == 1;
    lags = 0:(length(x)-2);
end;

nlag = length(lags);
ntim = length(x);
a = repmat(NaN, [nlag 1]);

for iiii = 1:nlag;
    ind1 = 1:(ntim-abs(lags(iiii)));
    ind2 = (1+abs(lags(iiii))):ntim;
    tem = corrcoef(x(ind1), x(ind2));
    a(iiii) = tem(1,2);
end
