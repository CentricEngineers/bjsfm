C      *********************************************************
C 
      SUBROUTINE UNLODED(P,DIA,AI,BETA,STEP,NUMPT,STRESS,U,V)
C 
C     CALCULATE STRESS DISTRIBUTION AROUND AN UNLOADED HOLE 
C 
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      INTEGER STEP,NUMPT
      DIMENSION STRESS(3,2,NUMPT),U(2,NUMPT),V(2,NUMPT),AI(3,3)
      DIMENSION WORK(5),COEF(5),RTR(4),RTI(4) 
      COMPLEX*16 R1,R2,COMPLX,XI1,XI2,COM1,COM2,DEN1,DEN2,PHI1,PHI2
      COMPLEX*16 Z,Z1,Z2,P1,P2,Q1,Q2 
Cf2py intent(out) stress
Cf2py intent(out) u
Cf2py intent(out) v
Cf2py depend(numpt) stress
Cf2py depend(numpt) u
Cf2py depend(numpt) v
C 
C 
C     CALCULATE COMPLEX PARAMETERS
C 
C     INITIALIZE COMPLEX NUMBER:  SQRT(-1.) 
C 
      COMPLX=(0.,1.)
      NUMCO=4 
      COEF(1)=AI(2,2)*1000000 
      COEF(2)=-2.*AI(2,3)*1000000 
      COEF(3)=(2.*AI(1,2)+AI(3,3))*1000000
      COEF(4)=-2.*AI(1,3)*1000000 
      COEF(5)=AI(1,1)*1000000 
      CALL ROOTS(COEF,WORK,NUMCO,RTR,RTI,IE)
      R1=RTR(1)+COMPLX*RTI(1) 
      IF(RTI(2).GT.0.0) R1=RTR(2)+COMPLX*RTI(2) 
      R2=RTR(3)+COMPLX*RTI(3) 
      IF(RTI(4).GT.0.0) R2=RTR(4)+COMPLX*RTI(4) 
      P1=AI(1,1)*R1*R1+AI(1,2)-AI(1,3)*R1 
      P2=AI(1,1)*R2*R2+AI(1,2)-AI(1,3)*R2 
      Q1=AI(1,2)*R1+AI(2,2)/R1-AI(2,3)
      Q2=AI(1,2)*R2+AI(2,2)/R2-AI(2,3)
C 
C 
      PI=3.1415926535 
      BETA=BETA*PI/180.0
C 
      DO 20 JJ=1,2 
      DO 10 NN=1,NUMPT
C 
      U(JJ,NN)=0.0
      V(JJ,NN)=0.0
      NNN=NN-1
      JJJ=JJ-1
C 
      THETA=NNN*2.0*PI/NUMPT
      RADIUS=JJJ*STEP+DIA/2.0 
C 
C     CALCULATE X & Y COORDINATES OF POINTS AROUND UNLOADED HOLE
C 
      X=RADIUS*DCOS(THETA) 
      Y=RADIUS*DSIN(THETA) 
C 
C     CALCULATE LOCATION PARAMETERS FOR UNLOADED HOLE EQUATIONS 
C 
      Z1=X+R1*Y 
      Z2=X+R2*Y 
      Z=X+COMPLX*Y
C 
C     MAPPING FUNCTION
C 
      XI1=CDSQRT(Z1*Z1-DIA*DIA/4.-R1*R1*DIA*DIA/4.)
      XI2=CDSQRT(Z2*Z2-DIA*DIA/4.-R2*R2*DIA*DIA/4.)
C 
C     CHOOSE CORRECT SIGN OF CSQRT
C 
      XI1=Z1/XI1
      XI2=Z2/XI2
C 
      IF(DBLE(XI1).LT.-.00001) XI1=-1.*XI1
      IF(DBLE(XI2).LT.-.00001) XI2=-1.*XI2
C 
      XI1=1.-XI1
      XI2=1.-XI2
C 
C     CALCULATE PHI PRIME 
C 
      COM1=R2*DSIN(2.*BETA)+2.*DCOS(BETA)*DCOS(BETA)+COMPLX*(2.*R2*
     1     DSIN(BETA)*DSIN(BETA)+DSIN(2.*BETA))
      COM2=R1*DSIN(2.*BETA)+2.*DCOS(BETA)*DCOS(BETA)+COMPLX*(2.*R1*
     1     DSIN(BETA)*DSIN(BETA)+DSIN(2.*BETA))
C 
      DEN1=2.*DIA*(R1-R2)*(1.+COMPLX*R1)
      DEN2=2.*DIA*(R1-R2)*(1.+COMPLX*R2)
C 
      PHI1=-COMPLX*P*DIA*COM1*XI1/(2.*DEN1) 
      PHI2=COMPLX*P*DIA*COM2*XI2/(2.*DEN2)
C 
C     CALCULATE STRESSES AROUND HOLE
C 
      STRESS(1,JJ,NN)=P*DCOS(BETA)*DCOS(BETA)+2.*DBLE(R1*R1*PHI1+ 
     1                R2*R2*PHI2) 
      STRESS(2,JJ,NN)=P*DSIN(BETA)*DSIN(BETA)+2.*DBLE(PHI1+PHI2)
      STRESS(3,JJ,NN)=P*DSIN(BETA)*DCOS(BETA)-2.*DBLE(R1*PHI1+
     1                R2*PHI2)
C 
C     CALCULATE DISPLACEMENTS 
C 
      XI1=1.-XI1
      XI2=1.-XI2
C 
      XI1=Z1/XI1
      XI2=Z2/XI2
C 
      DEN1=16.*(R1-R2)*(Z1+XI1) 
      DEN2=16.*(R1-R2)*(Z2+XI2) 
C 
      PHI1=-P*DIA*DIA*(COMPLX+R1)*COM1/DEN1 
      PHI2=P*DIA*DIA*(COMPLX+R2)*COM2/DEN2
C 
      U(JJ,NN)=2.*DBLE(P1*PHI1+P2*PHI2) 
      V(JJ,NN)=2.*DBLE(Q1*PHI1+Q2*PHI2) 
C 
   10 CONTINUE
   20 CONTINUE
C 
C 
      RETURN
      END 
C 
C     *********************************************************** 
C 
      SUBROUTINE LOADED(P,DIA,S,ALPHA,STEP,NUMPT,STRESS,U,V) 
C 
C     CALCULATES STRESS DISTRIBUTION AROUND A LOADED HOLE 
C     ASSUMING A COSINE BOLT LOAD DISTRIBUTION
C 
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      INTEGER STEP,NUMPT
      COMPLEX*16 R1,R2,COMPLX,Z,Z1,Z2,CPOS(50),CNEG(50),CZERO,CM,
     1AK1,AK2,XI1,XI2,PHI1,PHI2,COM1,COM2,XXI1,XXI2 
      COMPLEX*16 CHECK1,CHECK2,P1,P2,Q1,Q2 
C 
C 
      COMPLEX*16 A1(50),A2(50) 
      DIMENSION AMATRX(4,4),BMATRX(4),STRESS(3,2,NUMPT)
      DIMENSION U(2,NUMPT),V(2,NUMPT),S(3,3)
      DIMENSION WORK(5),COEF(5),RTR(4),RTI(4) 
Cf2py intent(out) stress
Cf2py intent(out) u
Cf2py intent(out) v
Cf2py depend(numpt) stress
Cf2py depend(numpt) u
Cf2py depend(numpt) v
C 
C 
C     INITIALIZE COMPLEX NUMBER:  SQRT(-1.) 
C 
      COMPLX=(0.,1.)
C 
C      CALCULATE COMPLEX PARAMETERS 
C 
      NUMCO=4 
      COEF(1)=S(2,2)*1000000
      COEF(2)=-2.*S(2,3)*1000000
      COEF(3)=(2.*S(1,2)+S(3,3))*1000000
      COEF(4)=-2.*S(1,3)*1000000
      COEF(5)=S(1,1)*1000000
      CALL ROOTS(COEF,WORK,NUMCO,RTR,RTI,IE)
      R1=RTR(1)+COMPLX*RTI(1) 
      IF(RTI(2).GT.0.0) R1=RTR(2)+COMPLX*RTI(2) 
      R2=RTR(3)+COMPLX*RTI(3) 
      IF(RTI(4).GT.0.0) R2=RTR(4)+COMPLX*RTI(4) 
C 
      P1=S(1,1)*R1*R1+S(1,2)-S(1,3)*R1
      P2=S(1,1)*R2*R2+S(1,2)-S(1,3)*R2
      Q1=S(1,2)*R1+S(2,2)/R1-S(2,3) 
      Q2=S(1,2)*R2+S(2,2)/R2-S(2,3) 
C 
C 
C 
      PI=3.1415926535 
C 
   10 CONTINUE
      P=4.0*P/PI
C 
C     A COSINE LOAD DISTRIBUTION OVER HALF OF HOLE AT AN ANGLE
C     ALPHA TO X AXIS 
C 
C     CALCULATE COMPLEX CONSTANTS 
C 
      PI2=PI/2.0
      M=-1
   20 CONTINUE
      M=M+1 
      IF(M.EQ.1) GO TO 40 
   30 CONTINUE
      C1=DSIN((M-1)*PI2)/(2*(M-1)) 
      C2=DSIN((M+1)*PI2)/(2*(M+1)) 
      C3=DSIN((M-1)*(-PI2))/(2*(M-1))
      C4=DSIN((M+1)*(-PI2))/(2*(M+1))
      C5=DCOS((M-1)*PI2)/(2*(M-1)) 
      C6=DCOS((M+1)*PI2)/(2*(M+1)) 
      C7=DCOS((M-1)*(-PI2))/(2*(M-1))
      C8=DCOS((M+1)*(-PI2))/(2*(M+1))
      CM=P*((C1+C2-C3-C4)-COMPLX*(-C5-C6+C7+C8))/(2.0*PI) 
      IF(M.EQ.0) CZERO=CM 
      IF(M.GT.1) CPOS(M)=CM 
      IF(M.LT.-1) MN=-1*M 
      IF(M.LT.-1) CNEG(MN)=CM 
      IF(M.LE.0) GO TO 50 
      M=-1*M
      GO TO 30
   40 CONTINUE
      C1=PI2
      C2=DSIN(2.*(PI2))/4. 
      C3=DSIN(2.*(-PI2))/4.
      C4=DSIN(PI2)*DSIN(PI2)/2. 
      C5=DSIN(-PI2)*DSIN(-PI2)/2. 
      CM=P*((C1+C2-C3)-M*COMPLX*(C4-C5))/(2.*PI)
      IF(M.EQ.1) CPOS(1)=CM 
      IF(M.EQ.-1) CNEG(1)=CM
      IF(M.EQ.-1) GO TO 50
      M=-1*M
      GO TO 40
   50 CONTINUE
      M=IABS(M) 
      IF(M.LT.49) GO TO 20
C 
C     TRANSFORM COMPLEX PARAMETERS INTO REAL AND IMAGINARY PARTS
C 
      S1=DBLE(R1) 
      S2=DBLE(R2) 
      T1=DIMAG(R1)
      T2=DIMAG(R2)
C 
C     EQUATING COEFFICIENTS AND SOLVING FOR CONSTANTS 
  
      DO 80 M=1,45
      MN=M-1
      IF(MN.NE.0) GO TO 60
      BMATRX(1)=DBLE(-CZERO*DIA/2.) 
      BMATRX(2)=DIMAG(-CZERO*DIA/2.)
      GO TO 70
   60 CONTINUE
      BMATRX(1)=DBLE(-CPOS(MN)*DIA/(2.*(MN+1))) 
      BMATRX(2)=DIMAG(-CPOS(MN)*DIA/(2.*(MN+1)))
   70 CONTINUE
      MN=M+1
      MNEG=-1*MN
      BMATRX(3)=DBLE(-CNEG(MN)*DIA/(2.*(MNEG+1))) 
      BMATRX(4)=DIMAG(-CNEG(MN)*DIA/(2.*(MNEG+1)))
      AMATRX(1,1)=T1+1. 
      AMATRX(1,2)=S1
      AMATRX(1,3)=T2+1. 
      AMATRX(1,4)=S2
      AMATRX(2,1)=S1
      AMATRX(2,2)=-T1-1.
      AMATRX(2,3)=S2
      AMATRX(2,4)=-T2-1.
      AMATRX(3,1)=1.-T1 
      AMATRX(3,2)=-S1 
      AMATRX(3,3)=1.-T2 
      AMATRX(3,4)=-S2 
      AMATRX(4,1)=S1
      AMATRX(4,2)=1.-T1 
      AMATRX(4,3)=S2
      AMATRX(4,4)=1.-T2 
      CALL SIMULT(AMATRX,BMATRX,4,J)
      IF(J.EQ.1)WRITE(6,705)
 705  FORMAT(' SIMULT CALCULATES A SINGULAR SET OF EQS.') 
      A1(M)=BMATRX(1)+COMPLX*BMATRX(2)
      A2(M)=BMATRX(3)+COMPLX*BMATRX(4)
   80 CONTINUE
C 
      PX=2.*PI*DIMAG(COMPLX*DIA*CNEG(1)/2.) 
      PY=2.*PI*DBLE(COMPLX*DIA*CNEG(1)/2.)
C 
      AMATRX(1,1)=T1
      AMATRX(1,2)=S1
      AMATRX(1,3)=T2
      AMATRX(1,4)=S2
      AMATRX(2,1)=0.0 
      AMATRX(2,2)=1.0 
      AMATRX(2,3)=0.0 
      AMATRX(2,4)=1.0 
      AMATRX(3,1)=2.*S1*T1
      AMATRX(3,2)=S1*S1-T1*T1 
      AMATRX(3,3)=2.*S2*T2
      AMATRX(3,4)=S2*S2-T2*T2 
      AMATRX(4,1)=-T1/(S1*S1+T1*T1) 
      AMATRX(4,2)=S1/(S1*S1+T1*T1)
      AMATRX(4,3)=-T2/(S2*S2+T2*T2) 
      AMATRX(4,4)=S2/(S2*S2+T2*T2)
      BMATRX(1)=PX/(4.*PI)
      BMATRX(2)=-PY/(4.*PI) 
      BMATRX(3)=(S(1,2)*PY+S(1,3)*PX)/(4.*PI*S(1,1))
      BMATRX(4)=-(S(1,2)*PX+S(2,3)*PY)/(4.*PI*S(2,2)) 
      CALL SIMULT(AMATRX,BMATRX,4,J)
      IF(J.EQ.1)WRITE(6,706)
 706  FORMAT(' SIMULT CALCULATES A SINGULAR SET OF EQS.') 
C 
      AK1=BMATRX(1)+COMPLX*BMATRX(2)
      AK2=BMATRX(3)+COMPLX*BMATRX(4)
C 
      ALPHA=-ALPHA*PI/180.0 
      ALPH=-ALPHA 
      DO 150 JJ=1,2
      DO 140 NN=1,NUMPT 
C 
      U(JJ,NN)=0.0
      V(JJ,NN)=0.0
      NNN=NN-1
      JJJ=JJ-1
      THETA=NNN*2.0*PI/NUMPT
      RADIUS=JJJ*STEP+DIA/2.0 
C 
C     CALCULATE X AND Y COORDINATES OF POINTS AROUND LOADED HOLE
C 
      X=RADIUS*DCOS(THETA+ALPHA) 
      Y=RADIUS*DSIN(THETA+ALPHA) 
C 
C     CALCULATE PARAMETERS FOR LOADED HOLE EQUATIONS
C 
      Z1=X+R1*Y 
      Z2=X+R2*Y 
      Z=X+COMPLX*Y
C 
C     MAPPING FUNCTION
C 
C 
      XXI1=CDSQRT(Z1*Z1-DIA*DIA/4.-R1*R1*DIA*DIA/4.) 
      XXI2=CDSQRT(Z2*Z2-DIA*DIA/4.-R2*R2*DIA*DIA/4.) 
C 
C     CHOOSE CORRECT SIGN OF CSQRT
C 
   90 CONTINUE
      XI1=Z1+XXI1 
      XI2=Z2+XXI2 
      XI1=2.*XI1/(DIA*(1.-COMPLX*R1)) 
      XI2=2.*XI2/(DIA*(1.-COMPLX*R2)) 
      COX1=DBLE(XI1)*DBLE(XI1)+DIMAG(XI1)*DIMAG(XI1)
      COX2=DBLE(XI2)*DBLE(XI2)+DIMAG(XI2)*DIMAG(XI2)
      IF(COX1.GE..99999) GO TO 100
      XXI1=-XXI1
      GO TO 90
  100 CONTINUE
      IF(COX2.GE..99999) GO TO 110
      XXI2=-XXI2
      GO TO 90
  110 CONTINUE
      XXI1=XI1
      XXI2=XI2
C 
C     CALCULATE PHI PRIME 
C 
      COM1=(0.,0.)
      COM2=(0.,0.)
      DO 120 M=1,45 
      COM1=COM1+M*A1(M)*XI1**(-1*M) 
      COM2=COM2+M*A2(M)*XI2**(-1*M) 
  120 CONTINUE
C 
C     CHECK SIGN OF CSQRT 
C 
      XI1=CDSQRT(Z1*Z1-DIA*DIA/4.-DIA*DIA*R1*R1/4.)
      XI2=CDSQRT(Z2*Z2-DIA*DIA/4.-DIA*DIA*R2*R2/4.)
      CHECK1=Z1/XI1 
      CHECK2=Z2/XI2 
      IF(DBLE(CHECK1).LT.-.00001) XI1=-1.*XI1 
      IF(DBLE(CHECK2).LT.-.00001) XI2=-1.*XI2 
      PHI1=(AK1-COM1)/XI1 
      PHI2=(AK2-COM2)/XI2 
C 
C     CALCULATE STRESS COMPONENTS IN LAMINATE AT COORDINATES X,Y
C 
      STRX=2.*DBLE(R1*R1*PHI1+R2*R2*PHI2) 
      STRY=2.*DBLE(PHI1+PHI2) 
      STRXY=-2.*DBLE(R1*PHI1+R2*PHI2) 
      STRESS(1,JJ,NN)=STRX*DCOS(ALPH)*DCOS(ALPH)+STRY*DSIN(ALPH)*
     1                DSIN(ALPH)-2.*STRXY*DSIN(ALPH)*DCOS(ALPH)
      STRESS(2,JJ,NN)=STRX*DSIN(ALPH)*DSIN(ALPH)+STRY*DCOS(ALPH)*
     1                DCOS(ALPH)+2.*STRXY*DSIN(ALPH)*DCOS(ALPH)
      STRESS(3,JJ,NN)=STRX*DSIN(ALPH)*DCOS(ALPH)-STRY*DSIN(ALPH)*
     1                DCOS(ALPH)+STRXY*(DCOS(ALPH)*DCOS(ALPH)- 
     2                DSIN(ALPH)*DSIN(ALPH))
C 
C     CALCULATE DISPLACEMENTS 
C 
      XI1=XXI1
      XI2=XXI2
      COM1=(0.,0.)
      COM2=(0.,0.)
      DO 130 M=1,45 
      COM1=COM1+A1(M)*XI1**(-1*M) 
      COM2=COM2+A2(M)*XI2**(-1*M) 
  130 CONTINUE
      XXI1=CDLOG(XI1)
      XXI2=CDLOG(XI2)
      PHI1=AK1*XXI1+COM1
      PHI2=AK2*XXI2+COM2
      U(JJ,NN)=2.*DBLE(P1*PHI1+P2*PHI2) 
      V(JJ,NN)=2.*DBLE(Q1*PHI1+Q2*PHI2) 
C 
  140 CONTINUE
  150 CONTINUE
C 
      RETURN
      END
C
      SUBROUTINE SIMULT(A,B,N,KS) 
C     TEST FOR ALGORITHMIC SINGULARITY ADDED 01/10/79 
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      DIMENSION A(1),B(1) 
C     MACHINE EPSILON FOR CYBER SINGLE PRECISION
      DATA EPS/7.11D-15/
      TOL=3.18*EPS*(N-1)
      BETA=0.0
      KS=0
      JJ=-N 
      DO 65 J=1,N 
      JY=J+1
      JJ=JJ+N+1 
      BIGA=0.0
      IT=JJ-J 
      DO 30 I=J,N 
      IJ=IT+I 
      IF(ABS(BIGA)-ABS(A(IJ))) 20,30,30 
   20 BIGA=A(IJ)
      IMAX=I
   30 CONTINUE
      IF(ABS(BIGA).GT.BETA)BETA=ABS(BIGA) 
      IF(ABS(BIGA)-TOL*BETA) 35,35,40 
   35 KS=1
      RETURN
   40 I1=J+N*(J-2)
      IT=IMAX-J 
      DO 50 K=J,N 
      I1=I1+N 
      I2=I1+IT
      SAVE=A(I1)
      A(I1)=A(I2) 
      A(I2)=SAVE
   50 A(I1)=A(I1)/BIGA
      SAVE=B(IMAX)
      B(IMAX)=B(J)
      B(J)=SAVE/BIGA
      IF(J-N) 55,70,55
   55 IQS=N*(J-1) 
      DO 65 IX=JY,N 
      IXJ=IQS+IX
      IT=J-IX 
      DO 60 JX=JY,N 
      IXJX=N*(JX-1)+IX
      JJX=IXJX+IT 
   60 A(IXJX)=A(IXJX)-(A(IXJ)*A(JJX)) 
   65 B(IX)=B(IX)-(B(J)*A(IXJ)) 
   70 NY=N-1
      IT=N*N
      DO 80 J=1,NY
      IA=IT-J 
      IB=N-J
      IC=N
      DO 80 K=1,J 
      B(IB)=B(IB)-A(IA)*B(IC) 
      IA=IA-N 
   80 IC=IC-1 
      RETURN
      END 
      SUBROUTINE ROOTS(XCOF,COF,M,ROOTR,ROOTI,IER)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      DIMENSION XCOF(M),COF(M),ROOTR(M),ROOTI(M)
C      DOUBLE PRECISION XO,YO,X,Y,XPR,YPR,UX,UY,V,YT,XT,U
C     &                ,XT2,YT2,SUMSQ,DX,DY,TEMP,ALPHA,FI
C     &                ,RMPREC,TOL 
C     RELATIVE MACHINE PRECISION (TEST FOR *ALMOST ZERO*) 
      DATA RMPREC/1.0D-14/ ,TOL/1.0D-4/ 
      IFIT=0
      N=M 
      IER=0 
      IF(XCOF(N+1)) 10,25,10
   10 IF(N) 15,15,32
   15 IER=1 
      GO TO 200 
   25 IER=4 
      GO TO 200 
   30 IER=2 
      GO TO 200 
   32 IF(N-36) 35,35,30 
   35 NX=N
      NXX=N+1 
      N2=1
      KJ1 = N+1 
      DO 40 L=1,KJ1 
      MT=KJ1-L+1
   40 COF(MT)=XCOF(L) 
   45 XO=.00500101D0
      YO=0.01000101D0 
      IN=0
   50 X=XO
      XO=-10.D0*YO
      YO=-10.D0*X 
      X=XO
      Y=YO
      IN=IN+1 
      GO TO 59
   55 IFIT=1
      XPR=X 
      YPR=Y 
   59 ICT=0 
   60 UX=0.D0 
      UY=0.D0 
      V =0.D0 
      YT=0.D0 
      XT=1.D0 
      U=COF(N+1)
      IF(DABS(U).LE.RMPREC)GO TO 130
   65 DO 70 I=1,N 
      L =N-I+1
      TEMP=COF(L) 
      XT2=X*XT-Y*YT 
      YT2=X*YT+Y*XT 
      U=U+TEMP*XT2
      V=V+TEMP*YT2
      FI=I
      UX=UX+FI*XT*TEMP
      UY=UY-FI*YT*TEMP
      XT=XT2
   70 YT=YT2
      SUMSQ=UX*UX+UY*UY 
      IF(SUMSQ.LE.RMPREC)GO TO 110
   75 DX=(V*UY-U*UX)/SUMSQ
      X=X+DX
      DY=-(U*UY+V*UX)/SUMSQ 
      Y=Y+DY
   78 IF( DABS(DY)+ DABS(DX).LE.TOL) GO TO 100
   80 ICT=ICT+1 
      IF(ICT-500) 60,85,85
   85 IF(IFIT) 100,90,100 
   90 IF(IN-5) 50,95,95 
   95 IER=3 
      GO TO 200 
  100 DO 105 L=1,NXX
      MT=KJ1-L+1
      RTEMP=XCOF(MT)
      XCOF(MT)=COF(L) 
  105 COF(L)=RTEMP
      ITEMP=N 
      N=NX
      NX=ITEMP
      IF(IFIT) 120,55,120 
  110 IF(IFIT) 115,50,115 
  115 X=XPR 
      Y=YPR 
      GO TO 100 
  120 IFIT=0
  122 IF(DABS(Y)-1.0D-4*DABS(X)) 135,125,125
  125 ALPHA=X+X 
      SUMSQ=X*X+Y*Y 
      N=N-2 
      GO TO 140 
  130 X=0.D0
      NX=NX-1 
      NXX=NXX-1 
  135 Y=0.D0
      SUMSQ=0.D0
      ALPHA=X 
      N=N-1 
  140 COF(2)=COF(2)+ALPHA*COF(1)
  145 DO 150 L=2,N
  150 COF(L+1)=COF(L+1)+ALPHA*COF(L)-SUMSQ*COF(L-1) 
  155 ROOTI(N2)=Y 
      ROOTR(N2)=X 
      N2=N2+1 
      IF(SUMSQ.LE.RMPREC) GO TO 165 
  160 Y=-Y
      SUMSQ=0.D0
      GO TO 155 
  165 IF(N.GT.0)GO TO 45
  200 RETURN
      END 
