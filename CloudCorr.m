%Load data from LauzHack format
%hyperIm = imread('OrthoVNIR.tif');
%hyperIm = hyperIm(3000:5000,1:3000,:); % Reduce image size if you experience RAM issues
clear all;
hyperIm = imread('ortho.tif');
% First channel in monochromatic in the 470-650 nm range
panChannel = hyperIm(:,:,1);
% Image coming from the VIS camera 470-650 nm
visIm = hyperIm(:,:,2:17);
% Image coming from the NIR camera 650-950 nm
nirIm = hyperIm(:,:,18:42);
% alpha channel of the image
alpha = hyperIm(:,:,43);
clear('hyperIm');
%% Regroup VIS and NIR images into reflectance structure, convert alpha to logical
refl = single(cat(3, visIm, nirIm));
alpha = alpha > 0;
clear('visIm','nirIm');
%hyper.refl = bsxfun(@rdivide, hyper.refl, max(max(hyper.refl)));
% Scale integer data to 0..1 reflectance range
refl = (refl - min(refl(:))) / (max(refl(:)) - min(refl(:)));

%% Compute RGB, extract Refl size
rgb = refl(:,:,[16 8 2]);
rgb(:) = imadjust(rgb(:),stretchlim(rgb(:),[.01 .99]));
[N M B] = size(refl);

%% Generate shadow map
% Currently computed as geometric mean of channels
shadowMap = ones([N M]);
visShadowMap = shadowMap;
for b = 1:B
    shadowMap = shadowMap .* (1-refl(:,:,b)) ;
end
% Normalize shadow map between 0..1
aux = shadowMap(alpha).^(1/B);
shadowMap(alpha) = imadjust(aux,stretchlim(aux,[.1 .9999]));

% Show the shadow map vs rgb
figure(1);
p1 = subplot(1,2,1);
imagesc(rgb);
axis image;
p2 = subplot(1,2,2);
imagesc(shadowMap);
colormap gray;
axis image;
linkaxes([p1 p2]);

% Show distribution of shadow map
figure(2);
hist(shadowMap(alpha),200);

%% Compute per band shadow correction

% Select Resolution used to convert shadow map to correction map
computeResolution = [256 256];
%computeResolution = [N M];
maxCorrAmplitude = 7;

shadowMapSmall = imresize(shadowMap,computeResolution);

% Plot resized Shadow map
figure(3);
imagesc(shadowMapSmall);
colormap gray;
axis image;
pause(0.5);

% For every band
bandsToCompute = [16 8 2]; % Only RGB for fast visual validation
bandsToCompute = 1:B; % All image bands
reflCorr = refl * 0; % Allocate memory for output reflectance cube
for b = bandsToCompute
    
    % Resize band b to computation resolution
    bandIm = refl(:,:,b);
    bandIm = imresize(bandIm,computeResolution);
    
    nParams = 2; % Select number of PCHIP parameters to define shadowMap -> correctionMap conversion
    x = linspace(0.1,0.9,nParams);
    y = zeros([nParams+1 1])+0.1;
    x = x(:); y = y(:);
    gamma = 1;
    
    % Parameter structure of our CloudCorrFuncMinXY, the function which should be minimal when cloud corr is optimal
    xy = [x; y; gamma];
    
    % Set search space for each parameter
    % X between 0.1 and 0.9 (mapping input shadow map intensity)
    % Y between 0.1 and MaxCorrectionFactor (mapping output correction intensity)
    % Gamma between 0.1 and 2 (forcing and exponential compensation if necessary)
    lowerBound = [ x*0 + 0.1; y*0 + 0.1;              0.1 ];
    upperBound = [ x*0 + 0.9; y*0 + maxCorrAmplitude;  2 ];
    options = [];
    % Find optimal parameters
    xySolved = fminsearchbnd(@CloudCorrFuncMinXY,xy,lowerBound, upperBound, options, shadowMapSmall, bandIm);
    
    % Recover PCHIP optimal params
    xSolved = xySolved(1:nParams);
    ySolved = xySolved(nParams+1:end-1);
    gammaSolved = xySolved(end);
    corrPoly = pchip([0; xSolved(:); 1],[0; ySolved(:)]);
    
    
    % Apply correction on reflectance image
    reflCorr(:,:,b) = (refl(:,:,b).^gammaSolved  .* ( 1 + ppval(corrPoly, shadowMap)) ).^(1/gammaSolved);
    reflCorr(:,:,b) = max(min(reflCorr(:,:,b),1),0);
    
    % Show corrected band vs original band
    figure(4);
    p1 = subplot(2,2,4);
    imagesc(refl(:, :, b)); axis image; colormap gray;
    title(sprintf('Original band'));
    p2 = subplot(2,2,[1 3]);
    imagesc(reflCorr(:, :, b)); axis image; colormap gray;
    linkaxes([p1 p2]);
    title(sprintf('Band %d, Gamma %.2f', b, gammaSolved));
    subplot(2,2,2);
    xPlot = linspace(0,1,100);
    plot(xPlot, ppval(corrPoly,xPlot) );
    title(sprintf('Curve function from shadow map to correction map'));
    pause(0.001);
    %waitforbuttonpress;
end

%% QA1: Show corrected RGB
figure(5);
rgbCorr = reflCorr(:,:,[16 8 2]);
rgbCorr(:) = imadjust(rgbCorr(:),stretchlim(rgbCorr(:),[.01 .99]));

p3 = subplot(1,2,1);
imagesc(rgbCorr);
title('Corrected');
axis image;
p4 = subplot(1,2,2);
imagesc(rgb);
title('Original');
axis image;
linkaxes([p2 p3 p4]);

%% QA2: Check and compare spectra before and after correction
figID = 6;
figure(figID);
subplot 121
hold off;
imagesc(rgb);
axis image;
title('Press S to stop, X to add eval pt, right click to set reference');

[N,M,B] = size(refl);
reference = [];
evalPoints = cell(0);
set(figID,'CurrentCharacter',char(0)); % Reset last current character to start loop
while 1
    [x,y, button] = ginput(1);
    x = uint32(x);
    y = uint32(y);
    c = char(button);
    % Check if click was on image
    if ( x <= M && y <= N && x > 0 && y > 0)
        X = x; Y = y; % Saved last mouse coordinates on image
        % Check mouse button pressed to choose action
        figure(figID);
        if button == 3 % Right click -> change reference spectrum
            reference = squeeze(refl(y,x,:));
            refRowCol = [y x];
        end
        
        original = squeeze(refl(y,x,:));
        corrected = squeeze(reflCorr(y,x,:));
        
        subplot 122
        hold off;
        plot( original ,'b','LineWidth',2);
        hold on;
        plot(squeeze(corrected),'Color',[ 0 0.7 0.2],'LineWidth',2);
        titleStr = ['Spectra at ' int2str(y) 'x' int2str(x)];
        if ~isempty(reference)
            plot(reference,'Color',[ 1 0 0.2],'LineWidth',2);
            refError = norm ( reference - corrected )/sqrt(B);
            titleStr = sprintf('%s, RefError %.2f %%',titleStr,refError*100);
        end
        title(titleStr);
        xlabel('Band');
        ylabel('Measured intensity');
        legend('Original','Corrected', 'Reference');
        ylim([0 1]);
        
        if (strcmp(c,'x'))  % After left click only
            
        end
    end
    if (strcmp(c,'x'))
        disp('Saving point pair ...');
        try
            subplot 121
            hold on;
            testCoupleCoord.refRowCol = refRowCol;
            testCoupleCoord.corrRowCol = [ Y X ];
            evalPoints{end+1} = testCoupleCoord;
            scatterMat = cat(1,refRowCol, [ Y X]);
            scatter(scatterMat(:,2), scatterMat(:,1), [], rand([1 3]), 'o','LineWidth',2);
            title(sprintf('Eval point added, now at %d',length(evalPoints)));
            set(figID,'CurrentCharacter',char(0)); % Reset last current character
            pause(0.01);
            disp('Point added');
        catch
        end
    elseif ( c == 's')
        disp('Point selection loop stopped.');
        break;
        
    end
end
%% (Customize tests) Save evaluation points
%save('myPts.mat','evalPoints');

%% QA3: Load points, execute evaluation
corrPts = load('cloudyPts.mat');
samePts = load('sunnyPts.mat');

RMSEsCorr = EvalRMSE(corrPts.evalPoints, refl, reflCorr);
RMSEsSame = EvalRMSE(samePts.evalPoints, refl, reflCorr);

figure(7);
subplot 121
hist(RMSEsCorr*100,20);
xlim([0 20]);
xlabel('%');
RMSEcorr = mean(RMSEsCorr);
title('RMSEs for Cloud Corrected Pixels');
subplot 122
hist(RMSEsSame*100,20);
RMSEsame = mean(RMSEsSame);
xlim([0 20]);
xlabel('%');
title('RMSEs for Pixels that shouldn''t change');
fprintf('Total RMSEs of cloud correction are %.4f%%, with false correction error %.6f%% \n', RMSEcorr*100,RMSEsame*100 );
