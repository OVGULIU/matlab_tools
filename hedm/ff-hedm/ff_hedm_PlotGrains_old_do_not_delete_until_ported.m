clear all
close all
clc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MTEX NEEDS TO BE INSTALLED
% GOTO '/net/s1dserv/export/s1b/__eval/mtex-3.5.0'
% RUN startup_mtex.m

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% User Input
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wsname  = 'wscub4x';      % workspace name
pname   = './examples/';
fname   = 'Grains_example.csv';

% ROTATION MATRIX TAKING VECTOR IN LAB FRAME TO SAMPLE FRAME
% NECESSARY TO GET THE ORIENTATION OF CRYSTALS WITH RESPECT TO SAMPLE FRAME
RLab2Sam    = eye(3,3);

% COLORING SCHEME
% ColorMap = load('cubic_xstal_coloring_scheme.mat');

% XSTAL SYMMETRY IN MTEX CONVENTION
% cs  = symmetry('m-3m');

% SAMPLE SYMMETRY IN MTEX CONVENTION
% ss  = symmetry('-1');

% FILTERS
Thresh_Completeness = 0.7;
Thresh_GrainRadius  = 50;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Execution
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Load workspace for fundamental region.
load(wsname);
eval(['ws = ', wsname, ';']);
clear(wsname)

% Load MIDAS results
pfname  = fullfile(pname, fname);
Grains  = parseGrainData(pfname, ws.frmesh.symmetries);
numpts  = length(Grains);
wts     = ones(1, numpts);

% THRESHOLDING BY COMPLETENESS
idx_Completeness    = [Grains.Completeness] >= Thresh_Completeness;
idx_MeanRadius      = [Grains.GrainRadius] >= Thresh_GrainRadius;
idx = find(idx_Completeness);

grainID = [Grains(idx).GrainID]';
xyz     = [Grains(idx).COM]';
rod     = [Grains(idx).rod];
cidx    = [Grains(idx).Completeness];
quat    = [Grains(idx).quat];
GrainRad    = [Grains(idx).GrainRadius];
lattprm     = [Grains(idx).lattprms];

% ASSIGN COLORS BASED ON IPDF
% ori = orientation('quaternion', quat(1,:), quat(2,:), quat(3,:), quat(4,:), cs, ss);
% hsv	= orientation2color(ori, 'ipdfHSV');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STRAIN JACK PLOTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IN PHYSICAL SPACE
i   = 5;
straini = Grains(idx(i)).Strain;
PlotJack(straini, 'title', sprintf('grain number : %d', grainID(i)))

% COM PLOTS
figure, 
subplot(1,2,1)
scatter3(xyz(:,1), xyz(:,2), xyz(:,3), 30, 'b')
grid on; axis square
hold on
scatter3(xyz(idx(i),1), xyz(idx(i),2), xyz(idx(i),3), 30, 'filled', 'r')
xlabel('z : +=along beam (um)'); ylabel('x : +=OB (um)'); zlabel('y : +=UP (um)')
title('COM of found grains // Strain Jack for the red dot')

% PLOT ORIENTATIONS / ONE COLOR
subplot(1,2,2)
PlotFRPerimeter('cubic');
scatter3(rod(1,:), rod(2,:), rod(3,:), 50, 'b')
hold on
scatter3(rod(1,idx(i)), rod(2,idx(i)), rod(3,idx(i)), 50, 'filled', 'r')
axis square tight off
title('Orientations of found grains // Strain Jack for the red dot')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% POLE FIGURE PLOTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
c   = [1 1 1]';
cu  = UnitVector(c);
for i = 1:1:size(ws.frmesh.symmetries,2)
    R   = RMatOfQuat(ws.frmesh.symmetries(:,i));
    ci(:,i) = R*cu;
end

s   = [];
for i = 1:1:size(quat,2)
    R   = RMatOfQuat(quat(:,i));
    s   = [s RLab2Sam*R*ci];
end

PlotSPF(s', ones(size(s,2),1), 'Title', sprintf('{ %d%d%d } in sample frame', c(1), c(2), c(3)))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PLOTS IN PHYSICAL SPACE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% PLOT COM / ONE COLOR
figure, scatter3(xyz(:,1), xyz(:,2), xyz(:,3), 30, 'filled', 'b')
grid on; axis square
xlabel('z : +=along beam (um)'); ylabel('x : +=OB (um)'); zlabel('y : +=UP (um)')
title('COM of found grains')

%%%% PLOT COM / COMPLETENESS AS COLOR
figure, scatter3(xyz(:,1), xyz(:,2), xyz(:,3), 30, cidx, 'filled')
grid on; axis square
colorbar vert; caxis([0.5 1])
xlabel('z : +=along beam (um)'); ylabel('x : +=OB (um)'); zlabel('y : +=UP (um)')
title('COM of found grains // colors denote completeness')

%%%% PLOT COM / COMPLETENESS AS COLOR
% figure, scatter3(xyz(:,1), xyz(:,2), xyz(:,3), 30, hsv, 'filled')
% grid on; axis square; colormap jet
% xlabel('z : +=along beam (um)'); ylabel('x : +=OB (um)'); zlabel('y : +=UP (um)')
% title('COM of found grains // colors in ipdf')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PLOTS IN ORIENTATION SPACE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PLOT ORIENTATIONS / ONE COLOR
figure, PlotFRPerimeter('cubic');
scatter3(rod(1,:), rod(2,:), rod(3,:), 50, 'filled', 'b')
axis square tight off
title('Orientations of found grains')

%%% PLOT ORIENTATIONS / COMPLETENESS AS COLOR
figure, PlotFRPerimeter('cubic');
scatter3(rod(1,:), rod(2,:), rod(3,:), 50, cidx, 'filled')
axis square tight off
colorbar vert; caxis([0.5 1])
title('Orientations of found grains // colors denote completeness')

%%% PLOT ORIENTATIONS / IPDF COLORS
% figure, PlotFRPerimeter('cubic');
% scatter3(rod(1,:), rod(2,:), rod(3,:), 50, hsv, 'filled') %% COMPLETENESS
% axis square tight off
% title('Orientations of found grains // colors in ipdf')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% STATISTICAL PLOTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% HISTOGRAM OF GRAIN SIZES NORMALIZED BY MAX GRAIN SIZE
figure, 
hist(GrainRad./max(GrainRad), 20)
xlabel('relative grain radius (-)')
ylabel('number of grains (-)')
title(sprintf('Max grain size : %5.0f (micron)', max(GrainRad)))

figure, 
subplot(2,3,1)
hist(lattprm(1,:))
xlabel('a (Angstrom)')
ylabel('number of grains (-)')
% title(sprintf('a0 = %5.4f A', a0))
view([0 90])
% axis([3.58 3.61 0 150])
grid on

subplot(2,3,2)
hist(lattprm(2,:))
xlabel('b (Angstrom)')
ylabel('number of grains (-)')
% title(sprintf('a0 = %5.4f A', a0))
view([0 90])
% axis([3.58 3.61 0 150])
grid on

subplot(2,3,3)
hist(lattprm(3,:))
xlabel('c (Angstrom)')
ylabel('number of grains (-)')
% title(sprintf('a0 = %5.4f A', a0))
view([0 90])
% axis([3.58 3.61 0 150])
grid on

subplot(2,3,4)
hist(lattprm(4,:))
xlabel('\alpha (degrees)')
ylabel('number of grains (-)')
view([0 90])
% axis([89.7 90.3 0 150])
grid on

subplot(2,3,5)
hist(lattprm(5,:))
xlabel('\beta (degrees)')
ylabel('number of grains (-)')
view([0 90])
% axis([89.7 90.3 0 150])
grid on

subplot(2,3,6)
hist(lattprm(6,:))
xlabel('\gamma (degrees)')
ylabel('number of grains (-)')
view([0 90])
% axis([89.7 90.3 0 150])
grid on
