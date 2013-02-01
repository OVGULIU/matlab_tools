function [se,fe] = rotate(iele,nnpe,np,gangl,se,fe)%  rotate elemental matrices to local coordinates for bc'sfor  k=1:1:nnpe      k1=np(iele,k);      teta=gangl(k1);      if( teta~=0.0 )        sin1=dsin(teta);        cos1=dcos(teta);        for   l=1:1:nnpe%          Pre-multiplcation [A][K_e]           s1= se(k,l)*cos1      +se(k+nnpe,l)*sin1;           s2= se(k,l+nnpe)*cos1 +se(k+nnpe,l+nnpe)*sin1;           s3=-se(k,l)*sin1      +se(k+nnpe,l)*cos1;           s4=-se(k,l+nnpe)*sin1 +se(k+nnpe,l+nnpe)*cos1;		              se(k,l)=          s1;           se(k,l+nnpe)=     s2;           se(k+nnpe,l)=     s3;           se(k+nnpe,l+nnpe)=s4;%        Post-multiplication [A][K_e][A]^T           s1= se(l,k)*cos1           +se(l,k+nnpe)*sin1;           s2=-se(l,k)*sin1           +se(l,k+nnpe)*cos1;           s3= se(l+nnpe,k)*cos1      +se(l+nnpe,k+nnpe)*sin1;           s4=-se(l+nnpe,k)*sin1      +se(l+nnpe,k+nnpe)*cos1;		              se(l,k)=          s1;           se(l,k+nnpe)=     s2;           se(l+nnpe,k)=     s3;           se(l+nnpe,k+nnpe)=s4;	   end%     Rotate Force vectors due to body forces.        s1 =  fe(2*k-1)*cos1 + fe(2*k)*sin1;        s2 = -fe(2*k-1)*sin1 + fe(2*k)*cos1;        fe(2*k-1) = s1;        fe(2*k)   = s2;      end	  end                                                               