function polimg = PolarBinXRD(mesh, instr, cakeParms, img)
% PolarBinXRD - Polar integration of image data
%
%   USAGE:
%
%   polimg = PolarBinXRD(mesh, instr, cakeParms, img)
%
%   INPUT:
%
%   mesh
%       mesh structure for finite element integration
%
%   instr
%       instrument parameters to correct for the experimental geometry
%
%   cakeParms
%       caking parameters for integration
%
%   img
%       image data for integration
%
%   OUTPUT:
%
%   polimg
%       radially integrated data organized in struct variable

% save('PolarBinXRD_input.mat')
% return
% clear all
% close all
% clc
% load('PolarBinXRD_input.mat')
% cakeParms.fastint   = 1;
% cakeParms.sector(3) = 240;
% cakeParms.sector(4) = 272;
% cakeParms.bins(2)   = 5;

img     = double(img); 
imgi    = img;

L   = instr.detectorsize/instr.pixelsize;

% !!! THESE ARE IN THE CARTESIAN FRAME !!!
x0  = cakeParms.origin(1);   % in pixels
y0  = cakeParms.origin(2);   % in pixels

x0plt   = x0;
y0plt   = instr.numpixels - y0;

figure(1000)
% imagesc(log(abs(rot90(img,1))))
imagesc(rot90(img,1))
hold on
axis equal tight
plot(x0plt, y0plt, 'rh')
xlabel('X_L (pixels)')
ylabel('Y_L (pixels)')

startAzi    = cakeParms.sector(1);
endAzi      = cakeParms.sector(2);

startRho    = cakeParms.sector(3);
endRho      = cakeParms.sector(4);

%%% NUMBER OF AZIMUTHAL BINS OVER ANGULAR RANGE DEFINED BY cakeParms.sector(1) AND cakeParms.sector(2)
numAzi  = cakeParms.bins(1);
%%% NUMBER OF RADIAL POINTS PER AZIMHUTHAL BIN OVER RADIAL RANGE DEFINED BY startRho AND endRho
numRho  = cakeParms.bins(2);
%%% NUMBER OF ETA POINTS PER AZIMUTH
numEta  = cakeParms.bins(3);

dAzi    = (endAzi - startAzi)/numAzi;
dEta    = dAzi/numEta;

R   = startRho:(endRho-startRho)/numRho:endRho;
R   = repmat(R, numEta + 1, 1)';

Rlist   = mean((R(1:end - 1,:) + R(2:end,:))./2,2);

polimg.azimuth   = cakeParms.azim;
polimg.radius    = zeros(numRho, numAzi);
polimg.intensity = zeros(numRho, numAzi);

for ii = 1:1:numAzi
    fprintf('Processing sector %d of %d\n', ii, numAzi);
    tic;
    
    azi_ini = polimg.azimuth(ii) - dAzi/2;
    azi_fin = polimg.azimuth(ii) + dAzi/2;
    
    TH  = azi_ini:dEta:azi_fin;
    TH  = repmat(TH, numRho + 1, 1);
    
    [x, y]	= pol2cart(deg2rad(TH),R);
    x   = x0 + x; y   = y0 + y;
    
    THplt   = azi_ini:dEta:azi_fin;
    THplt   = repmat(-THplt, numRho + 1, 1);
    
    [xplt, yplt]    = pol2cart(deg2rad(THplt),R);
    xplt    = x0 + xplt; yplt    = y0plt + yplt;

    figure(1000)
    title(num2str(polimg.azimuth(ii)))
    plot(xplt, yplt, 'k.')
    
    tic
    V   = zeros(numRho + 1, numEta + 1);
    for i = 1:1:(numRho + 1)
        for j = 1:1:(numEta + 1)
            xy  = [x(i,j); y(i,j)];
            V(i,j) = DataCoordinates(xy, L, mesh, imgi);
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % SOME BENCHMARK TESTS
            % gridNum     = (L - 1)*(fix(xy(2)) - 1) + fix(xy(1));
            % elemNums    = [gridNum*2-1 gridNum*2];
            %
            % P1  = mesh.crd(:, mesh.con(:,elemNums(1)));
            % P2  = mesh.crd(:, mesh.con(:,elemNums(2)));
            % IN1 = inpolygon(xy(1), xy(2), P1(1,:), P1(2,:));
            % IN2 = inpolygon(xy(1), xy(2), P2(1,:), P2(2,:));
            % if IN1
            %     A1  = [P1(1,1)-P1(1,3) P1(1,2)-P1(1,3);P1(2,1)-P1(2,3) P1(2,2)-P1(2,3)];
            %     B1  = [xy(1)-P1(1,3); xy(2)-P1(2,3)];
            %     Y1  = A1\B1;
            %     
            %     fele    = elemNums(1);
            %     fcrd    = [Y1(1) Y1(2) 1-Y1(1)-Y1(2)];
            % elseif IN2
            %     A2  = [P2(1,1)-P2(1,3) P2(1,2)-P2(1,3);P2(2,1)-P2(2,3) P2(2,2)-P2(2,3)];
            %     B2  = [xy(1)-P2(1,3); xy(2)-P2(2,3)];
            %     Y2  = A2\B2;
            %     
            %     fele    = elemNums(2);
            %     fcrd    = [Y2(1) Y2(2) 1-Y2(1)-Y2(2)];
            % else
            %     fprintf('UH-OH')
            % end
            % fcon    = img(mesh.con(:, fele));
            % V(i,j)  = dot(fcon, fcrd', 1);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        end
    end
    
    if ~isfield(cakeParms, 'fastint') || ~cakeParms.fastint
        Ilist   = BuildMeshPolarXRD(R, V, mesh.qrule);
    else
        V       = mean(V,2);
        V       = (V(1:end-1) + V(2:end))/2;
        Ilist   = V;
    end
    
    polimg.radius(:,ii)    = Rlist';
    polimg.intensity(:,ii) = Ilist';
    
    dtime   = toc;
    fprintf('Processing time for sector %d is %1.4f\n', ii, dtime);
end

polimg.radius       = polimg.radius';
polimg.intensity    = polimg.intensity';

% close(figure(1000))