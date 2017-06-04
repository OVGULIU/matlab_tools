function log = parseGrainData(pfname, qsym, varargin)
% NEED TO CHECK THE COORDINATE TRANSFORMATION!!!!
% parseGrainData Parse the hedm grain file
%   In the case of ff-HEDM, input file is from MIDAS grains.csv file.
%
%   log = parseGrainData(pfname, qsym) reads the grain log file
%   with the name fileName and returns the information in an array of
%   structures with fields:
%       nExpGvec = Number of expected G vectors
%       nMeasGvec = Number of measured G vectors
%       nMeasOnce = Number of G vectors measured once
%       nMeasMore = Number of G vectors measured more than once
%       meanIA = Average internal angle between prediced and measured
%       U = 3x3 Orientation matrix
%       gvec = G vector table
%       hkl = 3 hkl values
% 
%   The columns of the log file are:
%       Sp_ID O[0][0] O[0][1] O[0][2] O[1][0] O[1][1] O[1][2] O[2][0] O[2][1] O[2][2] 
%       X Y Z a b c alpha beta gamma Err1 Err2 Err3 MeanRadius Confidence 
%       
%       where each row describes a grain
%       
%       O[row][col] is the orientation matrix of the grain that takes crystal frame to
%       ESRF lab coordinate system. 
%       X,Y,Z define the center of mass coordinate of the grain in ESRF
%       lab coordinate system
%       a, b, c, alpha, beta, gamma are the crystal lattice
%       parameters of the grain (NEED TO DESCRIBE HOW THESE ARE DEFINED)
%       Err1, Err2, Err3
%       MeanRadius is the size of the grain
%       Confidence is the completeness of the grain (number of g-vectors
%       found / number of g-vectors anticipated)
%
%   In the case of nf-HEDM, input file is from Ice9 file postprocessed with
%   segmentation routine. This functionality was originally provided by
%   Dave Menasche at Carnegie Mellon University.
%
%   The columns of the input file are:
%       grain id
%       Center of mass (x = along beam, y = OB, z = up)
%       Average Orientation in Bunge convention that transforms a vector
%       in crystal frame to the laboratory frame
%       Volume 
%       AverageConfidence (bug in the segmentation routine) 
%       NumberNeighbors
%       IDsofNeighbors
%       MisorsWithNeighbors
%
%   INPUT:
%
%   pfname
%       full file path of the grain log file generated by ff-HEDM code
%
%   qsym 
%       Symmetry operators in quaternions
%
%   These arguments can be followed by a list of
%   parameter/value pairs. Options are:
%
%   'Technique'     far-field (ff) or near-field (nf). default is ff.
%   'CrdSystem'     coordinate system in the log file (default is APS)
%
%   OUTPUT:
%   
%   log
%       content of the grain log file organized into structure array
% 
%   Example:
%     log = parseGrainData(pfname);

% default options
optcell = {...
    'Technique', 'ff-midas', ...
    'CrdSystem', 'APS', ...
    'LabToSample', 0, ...
    'C_xstal', nan, ...
    'OffsetDirection', nan, ...
    'OffsetValue', nan, ...
    };

% update option
opts    = OptArgs(optcell, varargin);

disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
if strcmpi(opts.CrdSystem, 'APS')
    disp('COM / orientations / strains will be converted to the APS coordinate system')
elseif strcmpi(opts.CrdSystem, 'ESRF')
    disp('COM / orientations / strains will be in the ESRF coordinate system')
else
    disp('Unknown coordinate system')
    return
end
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')

if strcmpi(opts.CrdSystem, 'APS')
    R_ESRF2APS  = RMatOfQuat(QuatOfESRF2APS);
else
    R_ESRF2APS  = eye(3,3);
end

disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
if (opts.LabToSample == 0)
    disp(sprintf('The LAB FRAME and SAMPLE FRAME are IDENTICAL WHEN OMEGA = %2.1f deg', opts.LabToSample))
elseif (opts.LabToSample ~= 0) 
    disp(sprintf('The LAB FRAME and SAMPLE FRAME are IDENTICAL WHEN OMEGA = %2.1f deg', opts.LabToSample))
end
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
c   = cosd(opts.LabToSample);
s   = sind(opts.LabToSample);
RLab2Sam    = [
    c 0 -s; ...
    0 1 0; ...
    s 0 c; ...
    ];

disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
if isnan(opts.OffsetDirection) || (length(pfname) == 1)
    disp('No offset for multivolume')
elseif ~isnan(opts.OffsetDirection) && (length(pfname) > 1)
    disp('Grain COMs will be offset for multivolume');
    disp(sprintf('Grains COM offset along sample frame in %s by %f per layer', ...
        opts.OffsetDirection, opts.OffsetValue));
end
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')

if strcmpi(opts.Technique, 'ff-midas')
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    for iii = 1:1:length(pfname)
        A    = load(pfname{iii});
        nGrains(iii)    = size(A, 1);
    end
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    nCols       = size(A, 2);
    nGrainsAll  = sum(nGrains);
    ct          = 1;
    
    disp(sprintf('total number of grains : %d', nGrainsAll));
    
    log(nGrainsAll) = struct(...
        'GrainID',[], ...
        'R',[], 'quat',[], 'rod',[], ...
        'COM',[], ...
        'lattprms',[], ...
        'DiffPos',[], 'DiffOme',[], 'DiffAngle',[], ...
        'GrainRadius',[], ...
        'Completeness',[], ...
        'StrainFab',[], 'Strain',[], ...
        'PhaseNumber',[], ...
        'V',[],'Esam',[],'Ecry',[],'F',[], ...
        'ReflectionTable', [],  'CrdSys', []);
    
    % Loop over found grains
    for iii = 1:1:length(pfname)
        disp(sprintf('parsing ff-hedm data from %s', pfname{iii}));
        disp(sprintf('number of grains in this layer : %d', nGrains(iii)));
        A    = load(pfname{iii});
        
        % ROTATION FROM MIDAS IS [R]{c} = {l}
        % ROTATOIN TO GO FROM LAB TO SAMPLE IS [RLab2Sam]{l} = {s}
        % [RLab2Sam][R]{c} = [RLab2Sam]{l} = {s}
        for i = 1:1:nGrains(iii)
            RMat    = reshape(A(i, 2:10), 3, 3)';
            COM     = A(i, 11:13);
            
            % COORDINATE TRANSFORMATION
            RMat    = RLab2Sam*R_ESRF2APS*RMat;
            COM     = RLab2Sam*R_ESRF2APS*COM';
            
            if ~isnan(opts.OffsetDirection)
                if strcmpi(opts.OffsetDirection, 'X')
                    COM(1)  = COM(1) + opts.OffsetValue * (iii - 1);
                elseif strcmpi(opts.OffsetDirection, 'Y')
                    COM(2)  = COM(2) + opts.OffsetValue * (iii - 1);
                elseif strcmpi(opts.OffsetDirection, 'Z')
                    COM(3)  = COM(3) + opts.OffsetValue * (iii - 1);
                end
            end
            
            if strcmpi(opts.CrdSystem, 'APS')
                log(ct).CrdSys	= 'APS';
            elseif strcmpi(opts.CrdSystem, 'ESRF')
                log(ct).CrdSys	= 'ESRF';
            end
            Quat    = ToFundamentalRegionQ(QuatOfRMat(RMat), qsym);
            Rod     = RodOfQuat(Quat);
            
            log(ct).GrainID = A(i,1) + 1e7*iii; %% 1e7*iii gives each layer 10M grains
            log(ct).R       = RMat;
            log(ct).rod     = Rod;
            log(ct).quat    = Quat;
            log(ct).COM     = COM(:);
            
            log(ct).lattprms     = A(i, 14:19)';
            log(ct).DiffPos      = A(i, 20);
            log(ct).DiffOme      = A(i, 21);
            log(ct).DiffAngle    = A(i, 22);
            log(ct).GrainRadius  = A(i, 23);
            log(ct).Completeness = A(i, 24);
            
            StrainFab   = reshape(A(i, 25:33), 3, 3);
            Strain      = reshape(A(i, 34:42), 3, 3);
            
            % CONVERT MICRO-STRAIN TO STRAIN
            log(ct).StrainFab   = RLab2Sam*R_ESRF2APS*StrainFab*R_ESRF2APS'*RLab2Sam'./1000000;
            log(ct).Strain      = RLab2Sam*R_ESRF2APS*Strain*R_ESRF2APS'*RLab2Sam'./1000000;
            
            log(ct).StrainFabUnits  = 'strain';
            log(ct).StrainUnits     = 'strain';
            
            if isnan(opts.C_xstal)
                log(ct).StressFab    = nan(3,3);
                log(ct).Stress       = nan(3,3);
                
                log(ct).StressFab_h     = nan(3,3);
                log(ct).StressFab_d     = nan(3,3);
                log(ct).StressFab_vm    = nan(1,1);
                
                log(ct).Stress_h    = nan(3,3);
                log(ct).Stress_d    = nan(3,3);
                log(ct).Stress_vm   = nan(1,1);
                
            elseif (size(opts.C_xstal,1) == 6) && (size(opts.C_xstal,2) == 6)
                %%% STRAIN IS IN SAMPLE FRAME
                R   = RLab2Sam*R_ESRF2APS; % [R]{c}={s}
                T   = VectorizedCOBMatrix(R);
                C   = T*opts.C_xstal*T';  % XSTAL STIFFNESS IN SAMPLE FRAME
                
                %%% FAB
                StrainFab_vec       = VectorOfStressStrainMatrixInVM(log(i).StrainFab);
                StressFab_vec       = C*StrainFab_vec;
                log(ct).StressFab   	= StressFab_vec;
                log(ct).StressFab_mtx   = MatrixOfStressStrainInVM(StressFab_vec);
                log(ct).StressFab_h     = VolumetricStressStrain(StressFab_vec);
                log(ct).StressFab_d     = DeviatoricStressStrain(StressFab_vec);
                log(ct).StressFab_vm    = VMStressStrain(StressFab_vec);
                
                %%% PK
                Strain_vec          = VectorOfStressStrainMatrixInVM(log(i).Strain);
                Stress_vec          = C*Strain_vec;
                log(ct).Stress    	= Stress_vec;
                log(ct).Stress_mtx  = MatrixOfStressStrainInVM(Stress_vec);
                log(ct).Stress_h    = VolumetricStressStrain(Stress_vec);
                log(ct).Stress_d    = DeviatoricStressStrain(Stress_vec);
                log(ct).Stress_vm   = VMStressStrain(Stress_vec);
            end
            log(ct).StrainRMS   = A(i, 43);
            log(ct).C_xstal     = opts.C_xstal;
            
            %%% THIS IS FOR NEWER VERSION OF THE GRAINS OUTPUT
            if nCols > 43
                log(ct).PhaseNumber  = A(i, 44);
            end
            ct  = ct + 1;
        end
    end
%     COM = [Grains(:).COM]';
%     vm  = [Grains(:).StressFab_vm]';
%     pfname  = 'test.csv';
%     fid = fopen(pfname, 'w');
%     fprintf(fid, 'x,y,z,vm\n');
%     fclose(fid);
%     dlmwrite('test.csv', [COM vm], 'delimiter', ',', '-append')
elseif strcmpi(opts.Technique, 'nf')
    disp(sprintf('parsing nf-hedm data from %s', pfname));
    
    fid = fopen(pfname);
    tline = fgetl(fid);
    counter = 1;
    
    while ischar(tline)
        A	= sscanf( tline , '%f', 10)';
        
        COM	= A(2:4);
        %%% THIS IS Bunge Angles GOING FROM LAB TO CRYSTAL
        BungeAngles = A(5:7)';
        %%% CONVERTS BUNGE ANGLES TO ROT MATRIX THEN TRANSPOSE TO CHANGE
        %%% ITS MEANING TO "CRYSATL TO LAB"
        RMat    = RMatOfBunge(BungeAngles, 'degrees')';
        
        RMat    = R_ESRF2APS*RMat;
        COM     = R_ESRF2APS*COM';
        Quat    = ToFundamentalRegionQ(QuatOfRMat(RMat), qsym);
        
        if strcmpi(opts.CrdSystem, 'APS')
            log(counter).CrdSys	= 'APS';
        elseif strcmpi(opts.CrdSystem, 'ESRF')
            log(counter).CrdSys	= 'ESRF';
        end
        
        log(counter).BungeAngles    = BungeAngles;
        log(counter).RMat           = RMat;
        log(counter).Quat           = Quat;
        log(counter).COM            = COM(:);
        
        log(counter).Volume       = A(8);
        log(counter).Confidence   = A(9);
        
        log(counter).NumNeighbors	= A(10);
        
        B   = sscanf(tline,'%f',10+2*A(10));
        log(counter).IDofNeighbors      = B(11:11+A(10)-1);
        log(counter).MisWithNeighbors   = B(11+A(10):end);
        tline = fgetl(fid);
        counter = counter+1;
    end
    fclose(fid);
end