function [ outNorm ] = CloudCorrFuncMinXY( xy, shadowIm, bandIm )
%CLOUDCORRFUNCMIN Summary of this function goes here
%   Detailed explanation goes here


try
    nParams = (length(xy))/2;
    x = xy(1:nParams-1);
    y = xy(nParams:end-1);
    gamma = xy(end);
    pp = pchip([0; x(:); 1],[0; y(:)]);
    
    % Corrected band image
    corrBandIm = (bandIm.^gamma .* (1 + ppval(pp,shadowIm))).^(1/gamma);
    % After gamma corr, corrBandIm might be complex
    corrBandIm = abs(corrBandIm);
    
    % Define NORM to be minimized for optimal correction
    % e.g. when outNorm is min, shadow correction is perfect
    % We use the image gradient as a good correction will reduce the gradient
    
    % 2nd order gradient
    % outNorm = sum(sum((imgradient(imgradient((corrBandIm))))));
    
    % 1st order gradient
    outNorm = sum(sum((imgradient( corrBandIm ))));
    
    
catch
    outNorm = Inf;
    disp('CloudCorrFuncMinXY: Whoopsy !');
end


end

    