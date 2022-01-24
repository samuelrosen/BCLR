% This subroutine aggregates the original data at a different frequence.
% The data have to have the timeseries in col.s.
% fqr = "frequency ratio" 
%(i.e. original data Quarterly, aggregated data  Annual implies fqr=4);
% agr_mod = "kind of aggregation"

function newdata = ta(data,fqr,agr_mod)

[a b] = size(data);

if fqr~=1

n = ceil(a/fqr)-1;
newdata = zeros(n,b);

if agr_mod == 1                   % Time Aggregation of Levels
    f=0;
    for j=1:fqr:fqr*n
        f=f+1;
        newdata(f,:) = sum(data(j:j+fqr-1,:));
    end 
end

if agr_mod == 2                   % Compunding log growth rates or log-returns
    f=0;
    for j=1:fqr:fqr*n
        f=f+1;
        newdata(f,:) = sum(data(j:j+fqr-1,:));
    end 
end

if agr_mod == 3                   % Picking the first element
    f=0;
    for j=1:fqr:fqr*n
        f=f+1;
        newdata(f,:) = data(j,:);
    end 
end

if agr_mod == 4                   % Picking the last element
    f=0;
    for j=1:fqr:fqr*n
        f=f+1;
        newdata(f,:) = data(j+fqr-1,:);
    end 
end

if agr_mod == 5                   % Picking the average
    f=0;
    for j=1:fqr:fqr*n
        f=f+1;
        newdata(f,:) = sum(data(j:j+fqr-1,:))/fqr;
    end 
end

else
    
    newdata = data;
    
end
