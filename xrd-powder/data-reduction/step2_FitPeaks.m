clear all
close all
clc

%%% INPUT PARAMETERS
XRDIMAGE.Image.pname        = 'O:\nx_aug16_bc';
XRDIMAGE.Image.fbase        = 'groupAB_';
XRDIMAGE.Image.fnumber      = 15:59; % 4116 / 4117
XRDIMAGE.Image.numframe     = 1;
XRDIMAGE.Image.numdigs      = 5;
XRDIMAGE.Image.fext         = 'ge3.sum';
XRDIMAGE.Image.corrected    = 1;
XRDIMAGE.Image.IsHydra      = 0;    % 0 = Single panel; 1 = GE1; 2 = GE2; 3 = GE3; 4 = GE4;

%%% DARK FILES ONLY USED IF THE IMAGES ARE UNCORRECTED
XRDIMAGE.DarkField.pname    = 'O:\nx_aug16_bc';
XRDIMAGE.DarkField.fbase    = 'dark_1.5s_';
XRDIMAGE.DarkField.fnumber  = 338;
XRDIMAGE.DarkField.numframe = 1;
XRDIMAGE.DarkField.numdigs  = 5;
XRDIMAGE.DarkField.fext     = 'ge3';

XRDIMAGE.Calib.pname        = 'O:\nx_aug16_bc';
XRDIMAGE.Calib.fbase        = 'CeO2_0pt3s_';
XRDIMAGE.Calib.fnumber      = 11;
XRDIMAGE.Calib.fext         = 'ge3.sum';

%%% INSTRUMENT PARAMETERS GETS LOADED
Instr.energy        = 0;
Instr.wavelength	= 0;
Instr.distance      = 0;
Instr.centers       = [0, 0];
Instr.gammaX        = 0;
Instr.gammaY        = 0;
Instr.detsizeHorz	= 0;
Instr.detsizeVert   = 0;
Instr.pixelsizeHorz	= 0;
Instr.pixelsizeVert	= 0;
Instr.numpixelsHorz	= 0;
Instr.numpixelsVert	= 0;
Instr.imrotation    = 0;
Instr.dettype       = '2a';
Instr.detpars       = [0 0 0 0 0 0];
pfname  = GenerateGEpfname(XRDIMAGE.Calib);
for i = 1:1:length(XRDIMAGE.Calib.fnumber)
    pfname_instr    = [pfname{i,1}, '.instr.mat'];
    Instri  = load(pfname_instr);
    Instri  = Instri.Instr;
    
    Instr.energy        = Instr.energy + Instri.energy;
    Instr.wavelength    = Instr.wavelength + Instri.wavelength;
    Instr.distance      = Instr.distance + Instri.distance;
    Instr.centers       = Instr.centers + Instri.centers;
    Instr.gammaX        = Instr.gammaX + Instri.gammaX;
    Instr.gammaY        = Instr.gammaY + Instri.gammaY;
    Instr.detsizeHorz   = Instr.detsizeHorz + Instri.detsizeHorz; 
    Instr.detsizeVert   = Instr.detsizeVert + Instri.detsizeVert; 
    Instr.pixelsizeHorz	= Instr.pixelsizeHorz + Instri.pixelsizeHorz;
    Instr.pixelsizeVert	= Instr.pixelsizeVert + Instri.pixelsizeVert;
    Instr.numpixelsHorz	= Instr.numpixelsHorz + Instri.numpixelsHorz;
    Instr.numpixelsVert	= Instr.numpixelsVert + Instri.numpixelsVert;
    Instr.detpars       = Instr.detpars + Instri.detpars;
    Instr.imrotation    = 0;
    Instr.dettype       = '2a';
end
Instr.energy        = Instr.energy./length(XRDIMAGE.Calib.fnumber);
Instr.wavelength    = Instr.wavelength./length(XRDIMAGE.Calib.fnumber);
Instr.distance      = Instr.distance./length(XRDIMAGE.Calib.fnumber);
Instr.centers       = Instr.centers./length(XRDIMAGE.Calib.fnumber);
Instr.gammaX        = Instr.gammaX./length(XRDIMAGE.Calib.fnumber);
Instr.gammaY        = Instr.gammaY./length(XRDIMAGE.Calib.fnumber);
Instr.detsizeHorz   = Instr.detsizeHorz./length(XRDIMAGE.Calib.fnumber);
Instr.detsizeVert   = Instr.detsizeVert./length(XRDIMAGE.Calib.fnumber);
Instr.pixelsizeHorz	= Instr.pixelsizeHorz./length(XRDIMAGE.Calib.fnumber);
Instr.pixelsizeVert	= Instr.pixelsizeVert./length(XRDIMAGE.Calib.fnumber);
Instr.numpixelsHorz	= Instr.numpixelsHorz./length(XRDIMAGE.Calib.fnumber);
Instr.numpixelsVert	= Instr.numpixelsVert./length(XRDIMAGE.Calib.fnumber);
Instr.detpars       = Instr.detpars./length(XRDIMAGE.Calib.fnumber);

Instr.omega = 0;
Instr.chi   = 0;

XRDIMAGE.Instr  = Instr;

%%% CAKE PARAMETERS
XRDIMAGE.CakePrms.bins(1)   = 36;           % number of azimuthal bins
XRDIMAGE.CakePrms.bins(2)   = 1000;         % number of radial bins
XRDIMAGE.CakePrms.bins(3)   = 10;            % number of angular bins

XRDIMAGE.CakePrms.origin(1) = 1024.190;     % apparent X center in pixels // THIS IS WHAT YOU SEE ON FIGURE 1
XRDIMAGE.CakePrms.origin(2) = 1024.110;     % apparent Y center in pixels // THIS IS WHAT YOU SEE ON FIGURE 1
XRDIMAGE.CakePrms.origin(2) = XRDIMAGE.Instr.numpixelsVert-XRDIMAGE.CakePrms.origin(2); %%% CONVERT TO IMAGE COORDIANTES

XRDIMAGE.CakePrms.sector(1) = -360/XRDIMAGE.CakePrms.bins(1)/2;     % start azimuth (min edge of bin) in degrees
XRDIMAGE.CakePrms.sector(2) = 360-360/XRDIMAGE.CakePrms.bins(1)/2;  % stop  azimuth (max edge of bin) in degrees
XRDIMAGE.CakePrms.sector(3) = 150;  % start radius (min edge of bin) in pixels
XRDIMAGE.CakePrms.sector(4) = 1000;  % stop  radius (max edge of bin) in pixels

eta_step    = (XRDIMAGE.CakePrms.sector(2) - XRDIMAGE.CakePrms.sector(1))/XRDIMAGE.CakePrms.bins(1);
eta_ini     = XRDIMAGE.CakePrms.sector(1) + eta_step/2;
eta_fin     = XRDIMAGE.CakePrms.sector(2) - eta_step/2;
azim        = eta_ini:eta_step:eta_fin;
XRDIMAGE.CakePrms.azim      = azim;
XRDIMAGE.CakePrms.fastint   = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% MATERIAL PARAMETERS - CeO2
XRDIMAGE.Material.num       = 1;
XRDIMAGE.Material.lattparms = 5.411651;        % CeO2
XRDIMAGE.Material.structure = 'fcc';
XRDIMAGE.Material.hkls      = load([XRDIMAGE.Material.structure, '.hkls']);

%%% CALCULATE THEORETICAL TTH
[d, th] = PlaneSpacings(XRDIMAGE.Material.lattparms, ...
    'cubic', XRDIMAGE.Material.hkls', ...
    XRDIMAGE.Instr.wavelength);
tth     = 2*th;
d_spacing_range = 0.01;
d_spacing_UB    = (1 + d_spacing_range)*d;
d_spacing_LB    = (1 - d_spacing_range)*d;

tth_UB  = 2.*asind(XRDIMAGE.Instr.wavelength/2)./d_spacing_LB;
tth_LB  = 2.*asind(XRDIMAGE.Instr.wavelength/2)./d_spacing_UB;

XRDIMAGE.Material.tth       = tth;
XRDIMAGE.Material.d_spacing = d;
XRDIMAGE.Material.numpk     = 10;
XRDIMAGE.Material.numbounds = 10;
XRDIMAGE.Material.pkidx     = {...
    [1] [2] [3] [4] [5] [6] [7] [8] [9] [10]
    };
for i = 1:1:XRDIMAGE.Material.numbounds
    XRDIMAGE.Material.pkrange(:,i)  = [ ...
        min(tth_LB(XRDIMAGE.Material.pkidx{i})); ...
        max(tth_UB(XRDIMAGE.Material.pkidx{i})); ...
        ];
end
XRDIMAGE.Material.pkbck     = 2;
XRDIMAGE.Material.pkfunc    = 4;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% DATA REDUCTION FLAGS
Analysis_Options.make_polimg    = 0;
Analysis_Options.save_polimg    = 0;
Analysis_Options.fits_spectra   = 1;
Analysis_Options.save_fits      = 1;
Analysis_Options.find_instrpars = 0;
Analysis_Options.save_instrpars = 0;
Analysis_Options.find_detpars	= 0;
Analysis_Options.generateESG    = 0;

%%% PK FITTING OPTIONS
Analysis_Options.PkFuncOptions.pfunc_type	= 'pseudoVoigt';
Analysis_Options.PkFuncOptions.pbkg_order	= 2;
Analysis_Options.PkFitOptimizationOptions   = optimset(...
    'MaxIter', 5e5, ...
    'MaxFunEvals',3e5);

Analysis_Options.InstrPrmFitOptions = optimset(...
    'DerivativeCheck', 'off', ...
    'MaxIter', 1e5, ...
    'MaxFunEvals', 3e5, ...
    'TypicalX',[100 -100 100 0.1 0.1 XRDIMAGE.Instr.detpars], ...
    'Display','iter');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LOAD XRD IMAGES
pfname  = GenerateGEpfname(XRDIMAGE.Image);
numimg  = length(pfname);
if Analysis_Options.fits_spectra
    for i = 1:1:numimg
        pfname_polimage = [pfname{i,1}, '.polimg.mat'];
        pfname_pkfit    = [pfname{i,1}, '.pkfit.mat'];
        
        load(pfname_polimage)
        figure(2)
        subplot(1,2,1)
        imagesc(log(polimg.intensity)), axis square tight
        hold off
        
        subplot(1,2,2)
        plot(polimg.radius, polimg.intensity)
        hold off
        
        disp('###########################')
        disp(sprintf('Fitting peaks in %s', pfname{i,1}))
        disp('###########################')
        
        for j = 1:1:XRDIMAGE.CakePrms.bins(1)
            disp(sprintf('Looking at azimuthal bin %d of %d\n', j, XRDIMAGE.CakePrms.bins(1)))
            
            x   = polimg.radius(j,:);
            x   = Pixel2mm(x, XRDIMAGE.Instr.pixelsize);  % CONVERT TO MM FROM PIXELS
            y   = polimg.intensity(j,:);
            
            figure(11)
            subplot(1,2,1)
            plot(x, y, 'k.')
            hold on
            plot(XRDIMAGE.Instr.distance*tand(tth), mean(y), 'g^')
            axis([min(x) max(x) 0 max(y)+100])
            xlabel('radial distance (mm)')
            ylabel('intensity (arb. units)')
            title(['bin number : ', num2str(j)])
            
            for k = 1:1:XRDIMAGE.Material.numpk
                disp(sprintf('Looking at peak number %d of %d', k, XRDIMAGE.Material.numpk))
                if j == 1
                    pkrange = XRDIMAGE.Material.pkrange(:,k);
                    pkrange = XRDIMAGE.Instr.distance.*tand(pkrange);
                    
                    idx = find(x >= pkrange(1) & x <= pkrange(2));
                    xr  = x(idx)';
                    yr  = y(idx)';
                    
                    pr0 = [...
                        max(yr)/5 ...
                        0.5 ...
                        0.15 ...
                        XRDIMAGE.Instr.distance*tand(tth(XRDIMAGE.Material.pkidx{k})) ...
                        0 ...
                        2e3];
                else
                    pkrange = [pkfit.rho(j-1,k)-2.5 pkfit.rho(j-1,k)+2.5];
                    idx = find(x >= pkrange(1) & x <= pkrange(2));
                    xr  = x(idx)';
                    yr  = y(idx)';
                    
                    %%% NEEDS TO BE ADAPTIVE FOR PEAK FUNCTION TYPE
                    pr0 = [...
                        pkfit.amp(j-1,k) ...
                        pkfit.mix(j-1,k) ...
                        pkfit.fwhm(j-1,k) ...
                        pkfit.rho(j-1,k) ...
                        pkfit.bkg{j-1,k}];
                end
                
                pkpars.pfunc_type   = Analysis_Options.PkFuncOptions.pfunc_type;
                pkpars.pbkg_order   = Analysis_Options.PkFuncOptions.pbkg_order;
                pkpars.xdata        = xr;
                
                [pr, rsn, ~, ef]    = lsqcurvefit(@pfunc_switch, pr0, pkpars, yr, ...
                    [], [], Analysis_Options.PkFitOptimizationOptions);
                
                % [pr, rsn, ~, ef]    = lsqcurvefit(@pfunc, pr0, xr, yr, ...
                %     [], [], Analysis_Options.PkFitOptions);
                
                y0	= pfunc_switch(pr0, pkpars);
                yf	= pfunc_switch(pr, pkpars);
                
                % y0  = pfunc(pr0,xr);
                % yf  = pfunc(pr,xr);
                
                figure(11)
                subplot(1,2,1)
                plot(xr, yr, 'b.')
                plot(xr, y0, 'r-')
                plot(xr, yf, 'g-')
                
                subplot(1,2,2)
                plot(xr, yr, 'b.')
                hold on
                plot(xr, y0, 'r-')
                plot(xr, yf, 'g-')
                xlabel('radial distance (mm)')
                ylabel('intensity (arb. units)')
                title(['peak number : ', num2str(k)])
                hold off
                
                %%% MAPPING NEEDS TO BE UPDATED WITH A SWITCH
                pro  = pkfitResultMapping(pkpars, pr);
                
                pkfit.amp(j,k)  = pr(1);
                pkfit.mix(j,k)  = pr(2);
                pkfit.fwhm(j,k) = pr(3);
                pkfit.rho(j,k)  = pr(4);
                pkfit.bkg{j,k}  = pr(5:end);
                pkfit.rsn(j,k)  = rsn;
                pkfit.ef(j,k)   = ef;
                pkfit.rwp(j,k)  = ErrorRwp(yr, yf);
            end
            figure(11)
            subplot(1,2,1)
            hold off
        end
        
        if Analysis_Options.save_fits
            disp('###########################')
            disp(sprintf('Saving peak fits in %s\n', pfname_pkfit))
            save(pfname_pkfit, 'pkfit')
        else
            disp('###########################')
            disp(sprintf('Not saving peak fits for %s\n', pfname{i,1}))
        end
    end
end