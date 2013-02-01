function kes =freesurf_residual(nnps,nqpts,swt,bigNsurf,n,rjs,beta)% computes surface forces for traction loading% Penalty parameter for free surface conditionpenalty_parm = beta;iend=6*nnps;kes= zeros(iend,iend);bigNsqp= zeros(6,iend);for j=1:1:nqpts  	    % Surface normals    n1=n(j,1);    n2=n(j,2);    n3=n(j,3);        % At each quad point (3x12)    bigNsqp(:,:) = bigNsurf(:,:,j);            % Coefficient matrix (3x6)    T=[ n1 0 0 n2 n3 0;        0 n2 0 n1 0 n3;        0 0 n3 0 n1 n2];%           0 0 0 0 0 0;%           0 0 0 0 0 0;%           0 0 0 0 0 0];        % Constants (weight x jacobian)    xkfac=swt(j)*rjs(j);    % Stiffness at the quad point    kesqp = penalty_parm*xkfac*(bigNsqp'*T'*T*bigNsqp);        % Total stiffness    kes = kes + kesqp;end