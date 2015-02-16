clear all
close all
clc

%%% FROM PREVIOUS STEP USING Cd109
ChToEnergyConversion    = [0.0926   -0.0754];
    
%%%%%%%%%%%%%%%
% Nominal Experimental Geometry
TOA0    = 7;

%%%%%%%%%%%%%%%
% X-ray emission lines (eV) - XRAY ORANGE BOOK
% Ce Ka1     Ka2     Kb1     La1    La2    Lb1    Lb2    Lg1  Ma1
CeO2_emission_energy        = load('CeO2.emission.data');
CeO2_emission_energy(1,:)   = CeO2_emission_energy(1,:)/1000;

%%%%%%%%%%%%%%%
% CeO2 lattice constant
% 5.411651
% fcc
LattParms   = 5.411651;
hkls        = load('fcc.hkls')';
d_hkl       = PlaneSpacings(LattParms, 'cubic', hkls);
lambda_hkl0 = 2.*d_hkl*sind(TOA0/2);
E_hkl0      = Angstrom2keV(lambda_hkl0);

%%%%%%%%%%%%%%%%%
% USE Ceria diffraction data
pname_CeO2_spec    = '.\calibration-examples\mach_feb15_calibration\horizontal\calibration\horizontal';
fname_CeO2_spec    = 'ceria_calH_40kV_300s_feb13';
pfname_CeO2_spec   = fullfile(pname_CeO2_spec, fname_CeO2_spec);
[x, y]  = ReadEDDData(pfname_CeO2_spec, 'IDLFile', 1);

E_grid  = ChToEnergyConversion(1)*x + ChToEnergyConversion(2);

figure(1)
plot(E_grid, y, 'b.');
hold on
plot(CeO2_emission_energy(1,:), CeO2_emission_energy(2,:), 'g^')
plot(E_hkl0, ones(length(E_hkl0), 1), 'r^')
grid on
xlabel('energy (keV)')
ylabel('counts')

%%% USE 4 CeO2 PEAKS TO GET TOA
peaks2use   = [3 6 9 10];
for i = 1:1:length(peaks2use)
    E0  = E_hkl0(peaks2use(i));

    idx1    = find(E_grid < (E0 - 2.75));
    idx2    = find(E_grid < (E0 + 2.75));
    idx1    = idx1(end);
    idx2    = idx2(end);
    
    xdata   = E_grid(idx1:idx2);
    ydata   = y(idx1:idx2);
    
    p0  = [ ...
        max(ydata); ...
        2.5; ...
        0.5; ...
        E0; ...
        0; ...
        0; ...
        ];
    
    pLB = [0; 0; 0; E0-3; -inf; -inf];
    pUB = [inf; inf; 1; E0+3; inf; inf];
    
    p   = lsqcurvefit(@pfunc, p0, xdata, ydata, pLB, pUB);
    
    yfit0   = pfunc(p0, xdata);
    yfit    = pfunc(p, xdata);
    
    plot(xdata, ydata, 'm.')
    plot(xdata, yfit0, 'k:')
    plot(xdata, yfit, 'k-')
    
    E_fit(i)    = p(4);
end
lambda_fit  = keV2Angstrom(E_fit);

PolynominalCoefficient  = polyfit(2.*d_hkl(peaks2use), lambda_fit, 1);
TOA = 2.*asind(PolynominalCoefficient(1))

lambda_hkl  = 2.*d_hkl*sind(TOA/2);
E_hkl       = Angstrom2keV(lambda_hkl)

figure(1)
plot(E_hkl, ones(length(E_hkl), 1), 'k^')

figure(2)
plot(2.*d_hkl(peaks2use), lambda_fit, 'ko')
xlabel('2*d_{hkl} (Angstrom)')
ylabel('lambda (Andstrom)')