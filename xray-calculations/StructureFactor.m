function [a, b, c] = StructureFactor(matname)

switch matname
    case 'C'
        a1  = 2.310000;
        b1  = 20.843900;
        a2  = 1.020000;
        b2  = 10.207500;
        a3  = 1.588600;
        b3  = 0.568700;
        a4  = 0.865000;
        b4  = 51.651200;
        c   = 0.215600;
    case 'Al'
        a1  = 6.420200;
        b1  = 3.038700;
        a2  = 1.900200;
        b2  = 0.742600;
        a3  = 1.593600;
        b3  = 31.547200;
        a4  = 1.964600;
        b4  = 85.088600;
        c   = 1.115100;
    otherwise
        disp('material not defined')
end

a   = [a1 a2 a3 a4];
b   = [b1 b2 b3 b4];