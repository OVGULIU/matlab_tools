function csq = ReadPixirad(pfname, varargin)
% ReadPixirad - read Pixirad hexagonal grid file.
%
%   INPUT:
%
%   pfname
%       name of the Pixirad image file.
%
%   nc (optional)
%       number of horizontal nodes (default = 476).
%
%   nr (optional)
%       number of vertical nodes (default = 512).
%
%   nxsq (optional)
%       number of pixels along x in the output square grid data. number of
%       pixels along y is computed based on this number to make the pixel
%       square.
%
%   display (optional)
%       displays the sqaure grid image for confirmation.
%
%   OUTPUT:
%
%   csq
%       Pixirad image file information mapped to an image with square
%       pixels
%

% default options
optcell = {...
    'nc', 476, ...
    'nr', 512, ...
    'nxsq', 476, ...
    'display', 'off', ...
    };

% update option
opts        = OptArgs(optcell, varargin);

% read in image
imdata      = double(imread(pfname));
[nr, nc]    = size(imdata);

if nc ~= opts.nc
    disp(sprintf('user input or default : %d', opts.nc))
    disp(sprintf('image size in x       : %d', nc))
    error('number of columns does not match')
elseif nr ~= opts.nr
    disp(sprintf('user input or default : %d', opts.nr))
    disp(sprintf('image size in y       : %d', nr))
    error('number of rows does not match')
else
    disp(sprintf('%d x %d image', nc, nr))
end

pfname_xymap    = ['pixirad.map.nc.', num2str(nc), '.nr.', num2str(nr), '.mat'];
if exist(pfname_xymap, 'file')
    load(pfname_xymap)
else
    disp(sprintf('pixirad map %s does not exist!', pfname_xymap))
    disp(sprintf('creating %s.', pfname_xymap))
    x1  = 1:1:nc;
    x2  = 0.5:1:(nc-0.5);
    
    x   = [];
    y   = [];
    
    ct  = 1;
    for i = 1:1:nr
        if mod(i,2) == 1
            x   = [x; x1'];
            y   = [y; ct*ones(length(x1),1)./sind(60)];
        else
            x   = [x; x2'];
            y   = [y; ct*ones(length(x2),1)./sind(60)];
        end
        ct  = ct + 1;
    end
    % save(pfname_xymap, 'x', 'y')
end

imdata  = imdata';
imdata  = imdata(:);

%%% CREATE INTERPOLATION
F   = TriScatteredInterp(x, y, imdata);

%%% GENERATE SQUARE GRID
dx  = (max(x) - min(x))/opts.nxsq;
dy  = dx;
xsq = min(x):dx:max(x);
ysq = min(y):dy:max(y);

[xsq, ysq]  = meshgrid(xsq, ysq);

%%% MAP HEX GRID DATA TO SQUARE GRID
csq = F(xsq, ysq);

if strcmp(opts.display, 'on')    
    figure(1000)
    subplot(1,3,1)
    imagesc(log(imdata))
    axis equal
    
    subplot(1,3,2)
    scatter(x, y, 10, log(imdata))
    axis equal tight
    
    subplot(1,3,3)
    scatter(xsq(:), ysq(:), 10, log(csq(:)))
    axis equal tight
end