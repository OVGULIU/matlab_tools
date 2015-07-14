clear all
close all
clc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXPERIMENTAL GEOMETRY
% ASSUME FOR NOW A POINT DETECTOR (NO AZIMUTHAL ANGLE)
% THIS IS THE LOWER BOUND FOR THE NUMBER OF GRAINS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TakeOffAngle    = 5;                            % IN deg
IncSlitSizeRad  = 0.2;                          % IN mm
OutSlitSizeRad  = 0.2;                          % IN mm

IncSlitSizeAzi  = 0.2;                          % IN mm
OutSlitSizeAzi  = 0.2;                          % IN mm

OutSlitDsam     = 100;                          % IN mm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MATERIAL & SAMPLE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
AverageGrainVolume  = 100;                      % IN um^3
hkls            = load('fcc.hkls')';
DetectedPeaks   = [1 2 3 4];
qsym            = CubSymmetries;
PointsPerFiber  = 1000;

% %%%%
% fr_refine       =    5;  % refinement level on FR
% sp_refine       =   3;  % refinement level on sphere
% nHarm           = 23;   % number of harmonics
% PointsPerFiber  = 1000;
% 
% pf_hkls ={[1 1 1], [2 0 0], [2 2 0]};
% %
% wsopts = {...
%     'MakePoleFigures',   pf_hkls, ...
%     'PointsPerFiber',  PointsPerFiber, ...
%     'MakeFRL2IP',           'on', ...
%     'MakeFRH1IP',           'on', ...
%     'MakeSphL2IP',          'on', ...
%     'MakeSphH1IP',          'on'  ...
% 	 };
% 
%  cfr0 = CubBaseMesh;
% csym = CubSymmetries;
% cfr  = RefineMesh(cfr0, fr_refine, csym);
% cfr.symmetries = csym;
% %
% sph0 = SphBaseMesh(2, 'Hemisphere', 'off'); % 2d sphere
% sph  = RefineMesh(sph0, sp_refine);
% sph.crd = UnitVector(sph.crd);
% 
% %
% wscub = Workspace(cfr, sph, wsopts{:});
% 
% [dh, eVals] = DiscreteHarmonics(wscub.frmesh, nHarm);
% wscub.frmesh.dh     = dh;
% wscub.frmesh.eVals  = eVals;
% 
% save wscub5x wscub wsopts
% return

ws  = load('wscub5x');
[dh, eVals] = DiscreteHarmonics(ws.wscub.frmesh, 23);

odf.frmesh  = ws.wscub.frmesh;
% odf.field   = ones(odf.frmesh.numind,1);
odf.field   = dh(:,3) + abs(min(dh(:,3))); odf.field   = odf.field + abs(min(odf.field));
odf.field   = odf.field./MeanValue(odf.field, odf.frmesh.l2ip);

% CONVERT TO mm3
AverageGrainVolume  = AverageGrainVolume / 1000 / 1000 / 1000;

GaugeLengthZUS  = IncSlitSizeRad*cosd(TakeOffAngle./2)./sind(TakeOffAngle);
GaugeLengthZDS  = OutSlitSizeRad*cosd(TakeOffAngle./2)./sind(TakeOffAngle);
GaugeLengthZ    = GaugeLengthZUS + GaugeLengthZDS;
GaugeVolume     = GaugeLengthZ * IncSlitSizeAzi;
NumberOfGrains  = GaugeVolume / AverageGrainVolume;

disp(sprintf('IncSlit = %3.3f mm & OutSlit = %3.3f mm', IncSlitSizeRad, OutSlitSizeRad))
disp(sprintf('Gauge Volume                          = %3.3f mm^3', GaugeVolume))
disp(sprintf('Average grain volume                  = %3.0f um^3', AverageGrainVolume * 1000^3))
disp(sprintf('Number of grains in the gauge volume  = %3.0e grains', NumberOfGrains))

%%% SCATTERING VECTOR IN LAB SYSTEM
Ry  = [ ...
    cosd(TakeOffAngle/2) 0 sind(TakeOffAngle/2); ...
    0 1 0; ...
    -sind(TakeOffAngle/2) 0 cosd(TakeOffAngle/2); ...
    ];

Rx  = [ ...
    1 0 0; ...
    0 cosd(-TakeOffAngle/2) -sind(-TakeOffAngle/2); ...
    0 sind(-TakeOffAngle/2) cosd(-TakeOffAngle/2); ...
    ];

qH  = Ry*[1 0 0]';
qV  = Rx*[0 1 0]';

% pdf = odf.field./MeanValue(odf.field, odf.frmesh.l2ip);     %%% PROBABILITY DENSITY FUNCTION FROM ODF
MeanValue(odf.field, odf.frmesh.l2ip)
SumValue(odf.field, odf.frmesh.l2ip)
pdf = odf.field./SumValue(odf.field, odf.frmesh.l2ip);     %%% PROBABILITY DENSITY FUNCTION FROM ODF

PlotFR(odf.frmesh, pdf)
PlotFR(odf.frmesh, odf.field)
return
for i = 1:1:length(DetectedPeaks)    
    odfpf   = BuildOdfPfMatrix(hkls(:,DetectedPeaks(i)), ...
        odf.frmesh, odf.frmesh.symmetries, ...
        [qH qV], PointsPerFiber, 0, 500);
    
    nGrains = odfpf*pdf;
    disp(sprintf('Number of grains interrogated by q(%2.3f, %2.3f, %2.3f) || c{%d %d %d} = %3.2e grains', ...
        qH(1), qH(2), qH(3),  hkls(1,DetectedPeaks(i)), hkls(2,DetectedPeaks(i)), hkls(3,DetectedPeaks(i)), nGrains(1)))
    disp(sprintf('Number of grains interrogated by q(%2.3f, %2.3f, %2.3f) || c{%d %d %d} = %3.2e grains', ...
        qV(1), qV(2), qV(3),  hkls(1,DetectedPeaks(i)), hkls(2,DetectedPeaks(i)), hkls(3,DetectedPeaks(i)), nGrains(2)))
end