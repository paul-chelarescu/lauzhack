function [  RMSEs ] = EvalRMSE( evalPoints, refl, reflCorr )
%EVALRMSE Summary of this function goes here
%   Detailed explanation goes here

[~,~,B] = size(refl);
nPoints = length(evalPoints);
RMSEs = zeros([nPoints 1]);
for i = 1:nPoints
    pt = evalPoints{i};
    reference = squeeze(refl(pt.refRowCol(1), pt.refRowCol(2), :));
    corrected = squeeze(reflCorr(pt.corrRowCol(1),pt.corrRowCol(2),:));
    refErr = norm ( reference - corrected )/sqrt(B);
    RMSEs(i) = refErr;
end
end

