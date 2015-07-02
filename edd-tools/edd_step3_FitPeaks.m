clear all
close all
clc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INSTRUMENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TOA  = 6.97005;
ChToEnergyConversion  = [0.0925699 -0.0754175];
MeasurementPlane    = 'h';

%%% NUMBER OF POINTS IN X,Y,Z (GET FROM PYTHON FILE)
NX  = 1; NY  = 1; NZ  = 7;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MATERIAL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BCC Fe
latticeParms    = 2.868 ;                        % IN Angstrom
hkls            = load('bcc.hkls');
d_hkl           = PlaneSpacings(latticeParms, 'cubic', hkls');
pkid_fit        = 4:8;
sqrt_hkls       = sqrt(sum(hkls(pkid_fit, :).*hkls(pkid_fit, :),2));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PAR FILE DESIGNATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pname_pypar     = './strain-examples/';
fname_pypar     = 'mach_feb15_TOA_7_Lap7_1.pypar';
pfname_pypar    = fullfile(pname_pypar, fname_pypar);
pardata         = ReadPythonParFile(pfname_pypar);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PATH WHERE DATA FILES LIVE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pname_data  = './strain-examples/Lap7_1/';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% END OF INPUTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
XS  = pardata.samX;
YS  = pardata.samY;
ZS  = pardata.samZ;

lambda_hkl  = 2.*d_hkl*sind(TOA/2);
E_hkl       = Angstrom2keV(lambda_hkl);

E_grid  = 1:1:2048;
E_grid  = ChToEnergyConversion(1)*E_grid + ChToEnergyConversion(2);

numDV   = length(pardata.day);
for i = 1:1:numDV
    if strcmpi(MeasurementPlane, 'h')
        fname   = pardata.HorzFileName{i}(1:end-1);
    elseif strcmpi(MeasurementPlane, 'v')
        fname   = pardata.VertFileName{i}(1:end-1);
    end
    
    pfname  = fullfile(pname_data, fname);
    datai	= load(pfname);
    
    fname_fit   = [fname, '.fit.mat'];
    pfname_fit  = fullfile(pname_data, fname_fit);
    
    figure(1)
    plot(E_grid, datai, 'k.')
    hold on
    plot(E_hkl, ones(length(E_hkl), 1), 'b^')
    plot(E_hkl(pkid_fit), ones(length(pkid_fit), 1), 'r^')
    grid on
    xlabel('Energy (keV)')
    ylabel('counts')
    for j = 1:1:length(pkid_fit)
        idx1    = find(E_hkl(pkid_fit(j))-3.5 < E_grid);
        idx2    = find(E_hkl(pkid_fit(j))+3.5 < E_grid);
        xdata   = E_grid(idx1:idx2);
        ydata   = datai(idx1:idx2);
        
        p0  = [ ...
            max(ydata); ...
            1; ...
            0.5; ...
            E_hkl(pkid_fit(j)); ...
            0; ...
            0; ...
            ];
        pLB = [ ...
            0; ...
            0; ...
            0; ...
            E_hkl(pkid_fit(j)) - 3; ...
            -inf; ...
            -inf; ...
            ];
        pUB = [ ...
            inf; ...
            inf; ...
            1; ...
            E_hkl(pkid_fit(j)) + 3; ...
            inf; ...
            inf; ...
            ];
        
        [p, rn(j), ~, ef(j)]	= lsqcurvefit(@pfunc, p0, xdata, ydata, pLB, pUB);
        
        yfit0   = pfunc(p0, xdata);
        yfit    = pfunc(p, xdata);
        
        plot(xdata, ydata, 'r.')
        plot(xdata, yfit0, 'g-')
        plot(xdata, yfit, 'b-')
        
        Afit(j) = p(1);
        gfit(j) = p(2);
        nfit(j) = p(3);
        Efit(j) = p(4);
        bkg{j}  = p(5:end);
        
        Rwp(j)  = ErrorRwp(ydata, yfit);
        Re(j)   = ErrorRe(ydata, yfit);
        Rp(j)   = ErrorRp(ydata, yfit);
    end
    figure(1)
    hold off
    
    lambda      = keV2Angstrom(Efit);
    d_hkl_fit   = lambda./2/sind(TOA/2);
    
    xdata       = 1./sqrt_hkls;
    ydata       = d_hkl_fit';
    
    [p, a0_fit_s]   = polyfit(xdata, ydata, 1);
    a0_fit          = p;
    
    figure(10);
    plot(xdata, ydata, 'o')
    hold on
    plot(xdata, polyval(p, xdata), '-') 
    xlabel('1/sqrt(hh+kk+ll)')
    ylabel('d_{hkl} (Angstrom)')
    title('a0 is the slope if the data are from reference state and material is cubic')
    
    save(pfname_fit, 'Afit', 'gfit', 'nfit', 'Efit', 'bkg', 'Rwp', 'Re', 'Rp', 'rn', 'ef', 'a0_fit', 'a0_fit_s');
    pause(1)
end
