function [Idx,C]=KMeansCustom(X,k)
%KMeansCustom partitions the points in the n-by-d data matrix X into k clusters.
%[Idx,C]= KMeansCustom(X,k) returns 
%n-by-1 vector IDX containing the cluster indices of each point and 
%k-by-d matrix C containing the k cluster centroid locations.
%For n sample points with d dimensions in each point, X has n rows and d columns.
%File name: KMeanCustom.m
%Author: Yan Naing Aye
%Website: http://cool-emerald.blogspot.sg/


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Define maximum number of iterations
MaxIter=500;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[n,d]=size(X);
k=round(k);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%step1 :arbitrarily choose k samples as the initial cluster centers
p=randperm(n);
Mu=X(p(1:k),:);
D=zeros(k,d);
for t=1:MaxIter
 %step2:distribute the samples X  to the clusters 
 for j=1:k
        for i=1:n
            D(j,i)=CustomDist(X(i,:),Mu(j,:));%Use custom distance
        end
 end
 [ValMin,IndexMin]=min(D);
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %step 3: update the cluster centers
    OldMu=Mu;
 for i=1:k
        Mu(i,:)=mean(X(IndexMin==i,:));
 end
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %step4 :check convergence
 if sum(sum(abs(OldMu-Mu))) == 0 %< 1e-9
        break
 end
end
Idx=IndexMin';
C=Mu;