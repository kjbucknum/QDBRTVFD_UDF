**Free
  Ctl-Opt Nomain
          Option(*Srcstmt:*Nodebugio:*Noshowcpy) Debug(*yes);
 
  // Wrapper for QDBRTVFD API for SQL use.
  // https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_74/apis/qdbrtvfd.htm
 
  // CRTRPGMOD MODULE(KEVIN/UDBRTVFD)
  // CRTSRVPGM SRVPGM(KEVIN/UDBRTVFD) EXPORT(*ALL)
  // Create or Replace Function KEVIN/UDBRTVFD
  // ParFile Char(10),
  // ParLib  Char(10),
  // ParField Char(10))
  // Returns Char(10)
  // Language RPGLE
  // No SQL
  // Not Fenced
  // External Name 'KEVIN/UDBRTVFD(SQLRTVFD)'
  // Parameter Style General
 
  Dcl-Pr SQLRTVFD Char(10);
    *N Char(10);                             // File Name
    *N Char(10);                             // Library
    *N Char(10);                             // Variable to retrieve
  End-Pr;
 
  Dcl-Pr RTVFD  ExtPgm('QDBRTVFD');
    *N Char(65535) Options(*varsize);        // Receiver variable
    *N Int(10)     Const;                    // Length of receiver variable
    *N Char(20);                             // Qualified returned file name
    *N Char(8)     Const;                    // Format name
    *N Char(20)    Const;                    // Qualified file name
    *N Char(10)    Const;                    // Record format name
    *N Char(1)     Const;                    // Override processing
    *N Char(10)    Const;                    // System
    *N Char(10)    Const;                    // Format type
    *N LikeDs(Qusec);                        // Error code
  End-Pr;
 
 
  Dcl-Ds Qusec;
    BytesProvided Int(10) Inz(%Size(Qusec));
    BytesAvailable Int(10);
    ErrorId Char(7);
    Filler Char(1);
    MessageData Char(500);
  End-Ds;
 
  Dcl-Proc SQLRTVFD Export;
    Dcl-Pi *N Char(10);
      FileName Char(10);
      Library Char(10);
      ReturnField Char(10);
    End-Pi;
 
    /Copy Qsysinc/Qrpglesrc,Qdbrtvfd
 
    Dcl-Ds FDH LikeDs(QDBQ25) Based(ptrRcvVar);
    Dcl-DS PFA LikeDs(QDBQ26) Based(ptrPFA);
 
    Dcl-C Bit0 x'80';
    Dcl-C Bit1 x'40';
    Dcl-C Bit2 x'20';
    Dcl-C Bit3 x'10';
    Dcl-C Bit4 x'08';
    Dcl-C Bit5 x'04';
    Dcl-C Bit6 x'02';
    Dcl-C Bit7 x'01';
 
    Dcl-S ptrRcvVar Pointer;
    Dcl-S ptrPFA Pointer;
 
    Dcl-S ActualFile Char(20);
    Dcl-S ReceiveVar Char(4096);
    Dcl-S ReturnValue VarChar(256);
 
    ReturnValue = '*ERROR';
 
    If Library = '';
      Library = '*LIBL';
    EndIf;
 
    RtvFd(ReceiveVar
       :%Len(ReceiveVar)
       :ActualFile
       :'FILD0100'
       :FileName + Library
       :'*FIRST'
       :'0'
       :'*LCL'
       :'*INT'
       :Qusec);
 
    If BytesAvailable > 0;
      Return ErrorId;
    EndIf;
 
    ptrRcvVar = %Addr(ReceiveVar);
    ptrPFA = ptrRcvVar + FDH.QDBPFOF;
 
    Select;
      When ReturnField = 'QDBFHFPL' or ReturnField = 'TYPEOFFILE';
        If %Bitand(%Subst(FDH.QDBBITS27:1:1):Bit2) = Bit2;
          ReturnValue = 'LOGICAL';
        Else;
          ReturnValue = 'PHYSICAL';
        EndIf;
      When ReturnField = 'QDBFHFSU' or ReturnField = 'FILETYPE';
        If %Bitand(%Subst(FDH.QDBBITS27:1:1):Bit4) = Bit4;
          ReturnValue = '*SRC';
        Else;
          ReturnValue = '*DATA';
        EndIf;
      When ReturnField = 'QDBFKFDM' or ReturnField = 'MAINT';
        ReturnValue = FDH.QDBFKFDM00;
      When ReturnField = 'QDBFHAUT' or ReturnField = 'AUT';
        ReturnValue = FDH.QDBFHAUT;
      When ReturnField = 'QDBFHMXM' or ReturnField = 'MAXMBRS';
        ReturnValue = %Char(FDH.QDBFHMXM);
      When ReturnField = 'QDBFHMNUM' or ReturnField = 'NUMMBRS';
        ReturnValue = %Char(FDH.QDBHMNUM);
      When ReturnField = 'QDBFTCID' or ReturnField = 'CCSID';
        ReturnValue = %Char(FDH.QDBFTCID);
      When ReturnField = 'QDBFRDEL' or ReturnField = 'REUSEDLT';
        If %Bitand(PFA.QDBBITS33:Bit0) = Bit0;
          ReturnValue = '*YES';
        Else;
          ReturnValue = '*NO';
        EndIf;
      When ReturnField = 'QDBFAPSZ' or ReturnField = 'ACCPTHSIZ';
        If %Bitand(%Subst(FDH.QDBBITS31:1:1):Bit3) = Bit3;
          ReturnValue = '*MAX1TB';
        Else;
          ReturnValue = '*MAX4GB';
        EndIf;
    EndSl;
 
    Return ReturnValue;
 
   End-Proc; 
