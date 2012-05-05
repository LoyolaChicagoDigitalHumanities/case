PROGRAM Conflate;
USES Crt;
 { Written by Michele Cottrell, ADFA, Computer Centre, Canberra }
 { Translated into Turbo by Boyd Nation, Mississippi State University
   Computing Center, 1986 }
 { This program takes the output of 2 or more ( up to 10 ) COLLATEs.  
   These files are brought together to highlight the differences between the
   different versions of the same manuscript. }

CONST
    smax         = 255;
    seqmax       = 8;
    mfiles       = 10;
    mastersize   = 30;
    comparesize  = 50;

TYPE
    String3    = String[3];
    String80   = String[80];
    Mstring    = Packed Array [1..smax] of Char;
    Stringtype = Record
                     char  : Mstring;
                     lenth : 0..smax
                 End;
    Cmaxstring = Packed Array [1..comparesize] of Stringtype;
    Mints      = Packed Array [1..mfiles] of Integer;
    Cmints     = Packed Array [1..comparesize] of Mints;
    Cnumbs     = Packed Array [1..comparesize] of Integer;
    Sstrg      = Packed Array [1..seqmax] of Char;
    Sstring    = Record
                     char   : Sstrg;
                     lenth  : 0..seqmax
                 End;
    Fsstring   = Packed Array [1..mfiles] of Sstring;
    Fstring    = Packed Array [1..mfiles] of Stringtype;
    Mbool      = Packed Array [1..mfiles] of Boolean;
    Mmaxstring = Packed Array [1..mastersize] of Stringtype;
    Mnumbs     = Packed Array [1..mastersize] of Integer;
    Sstringptr = ^Sstring;
    Stringptr  = ^Stringtype;

VAR
    conflated                           : Text;
    cpointer                            : Mnumbs;
    creading                            : Cmaxstring;
    cstring                             : Stringtype;
    eoff                                : Mbool;
    errname                             : String80;
    error                               : Boolean;
    errorfile                           : Text;
    extrasigs                           : Boolean;
    ff                                  : Packed Array [1..10] of Text;
    inactive                            : Mbool;
    inputrec                            : Fstring;
    inputseq                            : Fsstring;
    inrec                               : Stringtype;
    mastersiglum                        : Sstring;
    mpointer                            : Mnumbs;
    mreading                            : Mmaxstring;
    nextcom                             : Cnumbs;
    numfiles                            : Integer;
    numsigla                            : Cnumbs;
    origin                              : Mnumbs;
    outrec                              : Stringtype;
    overwrite                           : Char;
    percent_matching                    : Real;
    rec                                 : Fstring;
    scstring                            : Sstring;
    seq                                 : Fsstring;
    sigla                               : Cmints;
    siglum                              : Fsstring;
    space                               : Stringtype;
    spaces8                             : Stringtype;
    spaces80                            : Stringtype;
    spaces_rsb                          : Stringtype;
    sptr                                : Stringptr;
    sspaces8                            : Sstring;
    sspace                              : Sstring;
    sspaces_rsb                         : Sstring;
    stat_match_enabled                  : Boolean;
    temp                                : Stringtype;
    tempname                            : String80;
    tempstr                             : String80;
    tmp                                 : Integer;
    tmpch                               : Char;
    tout                                : Stringtype;
    want_error                          : Boolean;
    want_errorc                         : Char;

PROCEDURE Add_ext (VAR filename : String80; ext : String3);
VAR
    dot         : Boolean;
    i           : Integer;
Begin
    dot := false;
    For i := 1 to length(filename) do
        dot := dot or (filename[i] = '.');
    If not dot then
    Begin
        filename := Concat(filename,'.');
        filename := Concat(filename,ext)
    End
End;

PROCEDURE Assine(VAR v:Stringtype; p:Stringptr);
Begin
    If p^.lenth > 0 then
        v := p^
    Else
        v := spaces80
End;

PROCEDURE Sassign(VAR v:Sstring; p:Stringptr);
        { Like assign but with  short string }
VAR 
    i                                   : Integer;
Begin
    v := sspaces8;
    For i := 1 to seqmax do
        v.char[i] := p^.char[i];
    v.lenth := p^.lenth
End;

FUNCTION Conkat(a1,a2:Stringtype): Stringptr;
        { Concatenates 2 strings, returns zero length string if too long }
VAR
    c2                                  : Stringtype;
    i                                   : Integer;
    lng1                                : Integer;
    lng2                                : Integer;
Begin
    lng1 := a1.lenth;
    lng2 := a2.lenth;
    If lng1 + lng2 <= smax then
    Begin
        sptr^.char := a1.char;
        c2.char    := a2.char;
        For i := 1 to lng2 do
            sptr^.char[lng1 + i] := c2.char[i];
        sptr^.lenth := lng1 + lng2
    End
    Else
    Begin
        error := true;
        If want_error then
        Begin
            Write(errorfile,'% Cannot concatenate ');
            For i := 1 to lng1 do
                Write(errorfile,a1.char[i]);
            Write(errorfile,' and ');
            For i := 1 to lng2 do
                Write(errorfile,a2.char[i]);
            Writeln(errorfile)
        End;
        Write('% Cannot concatenate ');
        For i := 1 to lng1 do
            Write(a1.char[i]);
        Write(' and ');
        For i := 1 to lng2 do
            Write(a2.char[i]);
        Writeln;
        sptr^.lenth := 0
    End;
    Conkat := sptr
End;

FUNCTION Sconcat(a1,a2:Sstring):Stringptr;
        { Same as Conkat but with short strings }
VAR 
    c2                                  : Sstring;
    i                                   : Integer;
    lng1                                : Integer;
    lng2                                : Integer;
Begin
    lng1 := a1.lenth;
    lng2 := a2.lenth;
    If lng1 + lng2 <= seqmax then
    Begin
        For i := 1 to lng1 do
            sptr^.char[i] := a1.char[i];
        c2.char := a2.char;
        For i := 1 to lng2 do
            sptr^.char[lng1 + i] := c2.char[i];
        sptr^.lenth := lng1 + lng2
    End
    Else
    Begin
        error := true;
        If want_error then
        Begin
            Write(errorfile,'% Cannot concatenate ');
            For i := 1 to lng1 do
                Write(errorfile,a1.char[i]);
            Write(errorfile,' and ');
            For i := 1 to lng2 do
                Write(errorfile,a2.char[i]);
            Writeln(errorfile)
        End;
        Write('% Cannot concatenate ');
        For i := 1 to lng1 do
            Write(a1.char[i]);
        Write(' and ');
        For i := 1 to lng2 do
            Write(a2.char[i]);
        Writeln;
        sptr^.lenth := 0
    End;
    Sconcat := sptr
End;

FUNCTION Substr(b:Stringtype;x1,x2:Integer): Stringptr;
        { Forms substring from X1, length X2 (X2 > 0); rest of string(X2=0) }
VAR 
    i                                   : Integer;
    l                                   : Integer;
Begin
    sptr^ := spaces80;
    If (x1 <= smax) and (x2 <= smax) {To check if range is OK } then
        If x2 = 0 then
        Begin
            l := b.lenth;
            If l > x1 then
            Begin
                For i := 1 to l - x1 + 1 do
                    sptr^.char[i] := b.char[x1 + i - 1];
                sptr^.lenth := l - x1 + 1
            End
        End
        Else
        Begin
            For i := 1 to x2 do
                sptr^.char[i] := b.char[x1 + i - 1];
            sptr^.lenth := x2
        End;
    Substr := sptr
End;

PROCEDURE Read_f(VAR which : Integer);
VAR 
    flag                                : Boolean;
    i                                   : Integer;
Begin
    inrec := spaces80;
    If numfiles >= which then
    Begin
        If not eof(ff[which]) then
        Begin
            Readln(ff[which],tempstr);
            inrec.lenth := length(tempstr);
            flag := true;
            If inrec.lenth > 0 then
                For i := 1 to inrec.lenth do
                Begin
                    If tempstr[i] <> ' ' then
                        flag := false;
                    inrec.char[i] := tempstr[i]
                End;
            If flag then
                Read_f(which)
        End
        Else
            eoff[which] := true
    End
End;

PROCEDURE Read_file(fn:Integer);
        { Update records and read in next line }
Begin  
    seq[fn] := inputseq[fn];
    rec[fn] := inputrec[fn];
    If not eoff[fn] then
    Begin
        Read_f(fn); 
        If not eoff[fn] then 
        Begin
            Sassign(inputseq[fn],Substr(inrec,1,8));
            Assine(inputrec[fn],substr(inrec,9,0))
        End
    End 
    Else
    Begin
        seq[fn].char[1]      := ' ';
        seq[fn].lenth        := 0;
        inputseq[fn].char[1] := ' ';
        inputseq[fn].lenth   := 0
    End
End;

PROCEDURE Produce_line;
        { Get next line to output }
VAR 
    i                                   : Integer;
    j                                   : Integer;
Begin
    j := 0;
    While outrec.lenth > 8 do
    Begin
        j := j + 1;
        If outrec.lenth <= 75 then
        Begin
            tout   := outrec;
            outrec := spaces80
        End
        Else 
        Begin 
            i := 74;
            While (outrec.char[i] <> ' ') and (i > 0) do
                i := i - 1;
            Assine(tout,Substr(outrec,1,i - 1));   { Error in original?}
            Assine(temp,Substr(outrec,i + 1,0));
            Assine(outrec,conkat(spaces8,temp))
        End;
        If (tout.char[1] = '*') then
            Write(conflated,' *',tmpch)
        Else
            If j > 1 then
                Write(conflated,' +',tout.char[1])
            Else
                Write(conflated,'  ',tout.char[1]);
        For i := 2 to tout.lenth do
            Write(conflated,tout.char[i]);
        Writeln(conflated)
    End
End;

PROCEDURE Set_up;
        { Sets up variables, gets user input }
VAR 
    i                                   : Integer;

PROCEDURE Get_name(VAR x:Sstring);
VAR 
    j                                   : Integer;
    tmp : Integer;
Begin 
    Readln(tempname);
    x.lenth := length(tempname);
    For j := 1 to x.lenth do
        x.char[j] := tempname[j]
End;

Begin  { GET SYSIN ??? }                { Set Up }
    New(sptr);
    Rewrite(conflated);
    error := false;
    For i := 1 to seqmax do
    Begin
        sspaces8.char[i] := ' ';
        spaces8.char[i]  := ' '
    End;
    For i := 1 to smax do
        spaces80.char[i] := ' ';
    sspaces8.lenth := 0;
    tmpch := ' ';
    spaces8.lenth  := 8;
    spaces80.lenth := 0;
    outrec   := spaces80;
    cstring  := spaces80;
    cstring.char[1]  := 'C';
    cstring.lenth    := 8;
    scstring := sspaces8;
    scstring.char[1] := 'C';
    scstring.lenth   := 8;
    spaces_rsb := spaces80;
    spaces_rsb.char[5]  := ']';
    spaces_rsb.lenth    := 5;
    sspaces_rsb := sspaces8;
    sspaces_rsb.char[5] := ']';
    sspaces_rsb.lenth   := 5;
    space.char[1]  := ' ';
    space.lenth    := 1;
    sspace.char[1] := ' ';
    sspace.lenth   := 1;
    mastersiglum   := sspaces8;
    For i := 1 to numfiles do
        siglum[i]  := sspaces8;
    Write('Enter siglum for master text : ');
    Get_name(mastersiglum);
    Sassign(mastersiglum,Sconcat(mastersiglum,sspace));
    For i:=1 to numfiles do
    Begin
        eoff[i]     := false;
        inactive[i] := false;
        tmp := i;
        Read_f(tmp);
        Sassign(inputseq[i],Substr(inrec,1,8));
        Assine(inputrec[i],Substr(inrec,9,0));
        Read_file(i);
        Write('Enter siglum for compare text # ',i,' : ');
        Get_name(siglum[i]);
        Sassign(siglum[i],Sconcat(siglum[i],sspace))
    End
End;            { Set Up }

FUNCTION Any_not_empty: Boolean;
        { Checks if any files are not empty }
VAR 
    flag                                : Boolean;
    i                                   : Integer;
Begin  
    flag := false;
    For i := 1 to numfiles do
        If not eoff[i] then
            flag  := true;
    Any_not_empty := flag
End;

PROCEDURE Conflate_sequence_number;
        { Compares files to collect similar variations }
VAR 
    i                                   : Integer;
    insertedsome                        : Boolean; 
    lastmaster                          : Integer;
    lastcompare                         : Integer;
    nextseq                             : Sstring;

FUNCTION Least_seq_num: Integer;
        { Find lowest sequence number of current lines }
VAR 
    i                                   : Integer;
    j                                   : Integer;
    l                                   : Integer;
Begin  
    i := 1;
    While eoff[i] do
        i := i + 1;
    l := i;
    For j := i + 1 to numfiles do
        If not eoff[j] then
            If seq[j].char < seq[l].char then
                l := j;
    Least_seq_num := l
End;

FUNCTION Multi_line_master(f:Integer): Boolean;
Begin
    If seq[f].char[1] = inputseq[f].char[1] then
        Multi_line_master := true
    Else
        Multi_line_master := false
End;

PROCEDURE Copy_entry(f:Integer);
VAR 
    i                                   : Integer;
    j                                   : Integer;
    k                                   : Integer;
    outseq                              : Sstring;
    outsig                              : Stringtype;
    tmp                                 : Sstring;
Begin
    outsig := spaces80;  
    outseq := nextseq;
    While seq[f].char[1] = 'M' do
    Begin
        For i := 1 to 8 do 
            outrec.char[i] := outseq.char[i];
        outrec.lenth := 8;
        j := outrec.lenth;
        For i := 1 to rec[f].lenth do
            outrec.char[j + i] := rec[f].char[i];
        outrec.lenth := outrec.lenth + rec[f].lenth;
        If inputseq[f].char[1]='C' then
        Begin  
            outsig := spaces_rsb;
            j := outsig.lenth;
            For i := 1 to mastersiglum.lenth do
                outsig.char[j + i] := mastersiglum.char[i];
            outsig.lenth := j + mastersiglum.lenth;
            If extrasigs then
                For i := 1 to numfiles do
                    If i <> f then
                    Begin  
                        j := outsig.lenth;
                        For k := 1 to siglum[i].lenth do
                            outsig.char[j + k] := siglum[i].char[k];
                        outsig.lenth := j + siglum[i].lenth;
                    End;
            j := outrec.lenth;
            If j + outsig.lenth < smax then
                Assine(outrec, conkat(outrec, outsig))
        End;
        Produce_line;
        Read_file(f);
        outseq := sspaces8
    End;
    outseq := scstring;
    Sassign(tmp,Sconcat(sspaces_rsb,siglum[f]));
    For i := 1 to tmp.lenth do
        outsig.char[i] := tmp.char[i];
    outsig.lenth := tmp.lenth;
    While seq[f].char[1] = 'C' do
    Begin
        For i := 1 to seqmax do
            outrec.char[i] := outseq.char[i];
        outrec.lenth := seqmax;
        Assine(outrec,Conkat(outrec,rec[f]));
        If (inputseq[f].char[1] = 'M') or eoff[f] then
            If outrec.lenth + outsig.lenth <= smax then
                Assine(outrec,Conkat(outrec,outsig));
        Produce_line;
        Read_file(f);
        outseq := sspaces8
    End
End; { Copy_entry }

PROCEDURE Fill_tables(f:Integer);
VAR 
    i                                   : Integer;
    indx                                : Integer;
    j                                   : Integer;
    outsig                              : Stringtype;
    savemas                             : Stringtype;
    where                               : Integer;

FUNCTION Try_exact_match(f:Integer): Integer;
VAR 
    i                                   : Integer;
    try                                 : Integer;
Begin
    try := 0;
    For i := 1 to lastmaster do
        If (mreading[i].char = savemas.char) and (try = 0) then
            try := i;
    Try_exact_match := try
End;

FUNCTION Try_almost_match(f:Integer): Integer;
VAR 
    i                                   : Integer;
    try                                 : Integer;

FUNCTION Statistical_match(f,mindex:Integer): Boolean;
VAR 
    i                                   : Integer;
    ignore                              : Set of Char;
    match                               : Boolean;
    num_in_common                       : Integer;
    nwords                              : Integer;
    string1                             : Stringtype;
    string2                             : Stringtype;
    temp                                : Stringtype;
    temp1                               : Stringtype;
    temp2                               : Stringtype;
    words                               : Packed Array [1..20] of Integer;

FUNCTION Index(a,b:Stringtype): Integer;
VAR 
    equal                               : Boolean;
    i                                   : Integer;
    j                                   : Integer;
    len1                                : Integer;
    len2                                : Integer;
    tmp                                 : Integer;

FUNCTION Chareq(x,y:Integer): Boolean;
Begin  
    Chareq := a.char[x] = b.char[y]
End;

Begin
    len1   := a.lenth;
    len2   := b.lenth;
    i      := 1;
    j      := 1;
    While len1 - i >= len2 do
        If Chareq(i,j) then
        Begin  
            tmp := i;
            equal := true;
            While equal and (i < len1) and (j < len2) do
            Begin  
                i := i + 1;
                j := j + 1;
                equal := equal and chareq(i,j)
            End;
            j := 1
        End
        Else 
            i := i + 1;
    If equal then
        Index := tmp
    Else 
        Index := 0
End;

Begin 
    ignore := ['(',')',' '];
    If savemas.lenth < mreading[mindex].lenth then
    Begin
        Assine(string1,Conkat(space,mreading[mindex]));
        Assine(string1,Conkat(string1,space));
        Assine(string2,Conkat(space,savemas));
        Assine(string2,Conkat(string2,space))
    End
    Else 
    Begin
        Assine(string1,Conkat(space,savemas));
        Assine(string1,Conkat(string1,space));
        Assine(string2,Conkat(space,mreading[mindex]));
        Assine(string2,Conkat(string2,space))
    End;
    i := 1;
    While i <= string1.lenth do
    Begin
        While (string1.char[i] in ignore) and (i <= string1.lenth) do
        Begin
            If i = 1 then
                Assine(temp1,conkat(spaces80,spaces80))
            Else
                Assine(temp1,substr(string1,1,i - 1));
            If i >= string1.lenth then
                Assine(temp2,conkat(spaces80,spaces80))
            Else
                Assine(temp2,substr(string1,i + 1,0));
            Assine(string1,conkat(temp1,temp2))
        End;
        i := i + 1
    End;
    nwords := 0;
    i := 1;
    While i <= string2.lenth do
    Begin
        If string2.char[i] in ignore then
        Begin  
            nwords := nwords + 1;
            words[nwords] := i;
            While (string2.char[i] in ignore) and (i <= string2.lenth) do
            Begin
                If i = 1 then
                    Assine(temp1,conkat(spaces80,spaces80))
                Else
                    Assine(temp1,substr(string2,1,i - 1));
                If i >= string1.lenth then
                    Assine(temp2,conkat(spaces80,spaces80))
                Else
                    Assine(temp2,substr(string2,i + 1,0));
                Assine(string2,conkat(temp1,temp2))
            End
        End;
        i := i + 1
    End;
    nwords := nwords - 1;
    num_in_common := Round(nwords * percent_matching);
    match := false;
    For i := 1 to nwords - num_in_common do
    Begin
        Assine(temp,Substr(string2,words[i],
               words[i + num_in_common] - words[i] + 1));
        If Index(string1,temp) > 0 then
            match := true
    End;
    Statistical_match := match
End; { of Statistical_match }

Begin  { of Try_almost_match }
    try := 0;
    i   := 1;
    If stat_match_enabled then
        While (i <= lastmaster) and (try = 0) do
        Begin
            If origin[i] <> f then
                If Statistical_match(f,i) then
                    try := i;
            i := i + 1
        End;
    Try_almost_match := try
End;  { of Try_almost_match }

PROCEDURE Insert_compare(f,mindex:Integer);
VAR 
    centry                              : Integer;
    lastc                               : Integer;
Begin  
    lastc := -1;
    If mindex <= 0 then 
        halt;
    centry := cpointer[mindex];
    While centry > 0 do
        If creading[centry].char = rec[f].char then
        Begin
            numsigla[centry] := numsigla[centry] + 1;
            sigla[centry,numsigla[centry]] := f;
            centry := -2
        End
        Else
        Begin
            lastc  := centry;
            centry := nextcom[centry]
        End;
    If centry = -1 then
    Begin
        lastcompare := lastcompare + 1;
        numsigla[lastcompare] := 1;
        sigla[lastcompare,1]  := f;
        nextcom[lastcompare]  := -1;
        creading[lastcompare] := rec[f];
        If lastc > 0 then
            nextcom[lastc]    := lastcompare
        Else 
            cpointer[mindex]  := lastcompare
    End
End; { of Insert_compare }

PROCEDURE Create_mas_entry(f:Integer; VAR mindex : Integer);
Begin
    lastmaster := lastmaster + 1;
    mreading[lastmaster] := savemas;
    origin[lastmaster]   := f;
    cpointer[lastmaster] := -1;
    mpointer[lastmaster] := -1;
    mindex := lastmaster
End;

PROCEDURE Set_up_corresponding(f,mindex : Integer; VAR where : Integer);
VAR 
    lastm                               : Integer;
    mentry                              : Integer;
Begin  
    tmpch  := nextseq.char[1];
    nextseq.char[1] := '*';
    lastm  := mindex;
    mentry := mpointer[mindex];
    While mentry > 0 do
    Begin
        lastm  := mentry;
        mentry := mpointer[mentry]
    End;
    lastmaster := lastmaster + 1;
    mreading[lastmaster] := savemas;
    mpointer[lastmaster] := -1;
    origin[lastmaster]   := f;
    cpointer[lastmaster] := -1;
    mpointer[lastm] := lastmaster;
    where := lastmaster
End; { of Set_up_corresponding }

Begin  { of Fill_tables }
    outrec  := spaces80;
    outsig  := spaces80;
    savemas := rec[f];
    Read_file(f);
    If inputseq[f].char[1] = 'C' then
    Begin
        Assine(outsig,Sconcat(sspaces_rsb,mastersiglum));
        If extrasigs then
            For indx := 1 to numfiles do
                If indx <> f then
                Begin
                    j := outsig.lenth;
                    For i := 1 to siglum[indx].lenth do
                        outsig.char[j + i] := siglum[indx].char[i];
                    outsig.lenth := j + siglum[indx].lenth;
                End;
            Assine(outrec,Sconcat(nextseq,sspaces8));
            Assine(outrec,Conkat(outrec,savemas));
            j := outrec.lenth;
            For i := 1 to outsig.lenth do
                outrec.char[j + i] := outsig.char[i];
            outrec.lenth := j + outsig.lenth;
            Produce_line;
            Copy_entry(f)
    End
    Else 
    Begin
        insertedsome := true;
        indx := Try_exact_match(f);
        If indx > 0 then
            Insert_compare(f,indx)
        Else 
        Begin 
            indx := Try_almost_match(f);
            If indx > 0 then
            Begin
                Set_up_corresponding(f,indx,where);
                Insert_compare(f,where)
            End
            Else
            Begin
                Create_mas_entry(f,indx);
                Insert_compare(f,indx)
            End
        End;
        Read_file(f)
    End
End; { of Fill_tables }

PROCEDURE Produce_outputs;
VAR 
    i                                   : Integer;
    nextm                               : Integer;

PROCEDURE Do_one_master(mindex:Integer;mainentry:Boolean);
VAR 
    domore                              : Boolean;
    i                                   : Integer;
    j                                   : Integer;
    k                                   : Integer;
    nextc                               : Integer;
    nextm                               : Integer;
    outsig                              : Stringtype;
    s                                   : Mints;
Begin
    outsig := spaces80;
    Assine(outsig,Sconcat(sspaces_rsb,mastersiglum));
    domore := (extrasigs and mainentry);
    If domore then
    Begin
        For i := 1 to numfiles do
            s[i] := i;
        nextm := mindex;
        While nextm > 0 do
        Begin 
            s[origin[nextm]] := 0;
            nextc := cpointer[nextm];
            While nextc > 0 do
            Begin
                For i := 1 to numsigla[nextc] do
                    s[sigla[nextc,i]] := 0;
                nextc := nextcom[nextc]
            End;
            nextm := mpointer[nextm]
        End;
        For i := 1 to numfiles do
            If s[i] > 0 then
            Begin
                j := outsig.lenth;
                For k := 1 to siglum[i].lenth do
                    outsig.char[j + k] := siglum[i].char[k];
                outsig.lenth := j + siglum[i].lenth;
            End
    End;
    Assine(outrec,Sconcat(nextseq,sspaces8));
    Assine(outrec,Conkat(outrec,mreading[mindex]));
    Assine(outrec,Conkat(outrec,outsig));
    Produce_line;
    nextc := cpointer[mindex];
    While nextc > 0 do
    Begin 
        Assine(outrec,Conkat(cstring,creading[nextc]));
        Assine(outrec,Conkat(outrec,spaces_rsb));
        outsig := spaces80;
        For i := 1 to numsigla[nextc] do
        Begin
            j := outsig.lenth;
            For k := 1 to siglum[sigla[nextc,i]].lenth do
                outsig.char[j + k] := siglum[sigla[nextc,i]].char[k];
            outsig.lenth := j + siglum[sigla[nextc,i]].lenth
        End;
        Assine(outrec,Conkat(outrec,outsig));
        Produce_line;
        nextc := nextcom[nextc]
    End
End; { of Do_one_master }

Begin  { of Produce_outputs }
    For i := 1 to lastmaster do
        If origin[i] > 0 then
        Begin  
            Do_one_master(i,true);
            nextm := mpointer[i];
            origin[i] := 0;
            While nextm > 0 do
            Begin
                Do_one_master(nextm,false);
                origin[nextm] := 0;
                nextm := mpointer[nextm]
            End
        End
End; { of Produce_outputs }

Begin  { of Conflate_sequence_number }
    nextseq := seq[Least_seq_num];
    For i := 1 to numfiles do
        If eoff[i] then
            inactive[i] := true
        Else
            If seq[i].char <> nextseq.char then
                inactive[i] := true
            Else
                inactive[i] := false;
    lastmaster  := 0;
    lastcompare := 0;
    For i := 1 to numfiles do
        If not inactive[i] then
        Begin
            insertedsome := false;
            While seq[i].char = nextseq.char do
                If Multi_line_master(i) then
                    Copy_entry(i)
                Else
                    Fill_tables(i);
                inactive[i] := not insertedsome
        End;
    Produce_outputs
End;            { Conflate_sequence_number }

PROCEDURE Get_info;
VAR
    i                                   : Integer;

PROCEDURE Get_boolean(VAR x:Boolean);
VAR 
    ch                                  : Char;
Begin
    Repeat
        Write(' (y/n) ? ');
        Readln(ch)
    Until ch in ['y','Y','n','N'];
    If (ch = 'y') or (ch = 'Y') then
        x := true
    Else 
        x := false           
End;

Begin { read in numbs }
    Repeat
        Write('Number of variant files to be conflated (2-10) : ');
        Readln(numfiles)
    Until numfiles in [2..10];
    percent_matching := 0.5;
    For i := 1 to numfiles do
        Repeat
            Write('Filename for input variants file # ',i,' : ');
            Readln(tempname);
            Add_ext(tempname,'var');
            Assign(ff[i],tempname);
            {$i-}
            Reset(ff[i]);
            {$i+}
            tmp := ioresult;
            If tmp=1 then
                Writeln('File not on disk.')
        Until tmp=0;
    Repeat
        Write('Filename for output (conflated) file : ');
        Readln(tempname);
        Add_ext(tempname,'cfl');
        Assign(conflated,tempname);
        {$i-}
        Reset(conflated);
        {i+}
        tmp := ioresult;
        overwrite := 'n';
        If tmp = 0 then
        Begin
            Write('File already on disk.  Do you want to overwrite it (y/n)? ');
            Readln(overwrite)
        End
    Until (tmp <> 0) or (overwrite = 'y') or (overwrite = 'Y');
    Write('Do you want an error file created (y/n)? ');
    Readln(want_errorc);
    want_error := not((want_errorc = 'n') or (want_errorc = 'N'));
    If want_error then
    Begin
        Repeat
            Write('Filename for error file : ');
            Readln(errname);
            Add_ext(errname,'err');
            Assign(errorfile,errname);
            {$i-}
            Reset(errorfile);
            {$i+}
            tmp := ioresult;
            overwrite := 'n';
            If tmp = 0 then
            Begin
                Write('File already on disk.');
                Write('  Do you want to write over it (y/n)? ');
                Readln(overwrite)
            End
        Until (tmp <> 0) or (overwrite = 'y') or (overwrite = 'Y');
        Rewrite(errorfile)
    End;
    Write('Print extra sigla');
    Get_boolean(extrasigs);
    Write('Enable statistical match');
    Get_boolean(stat_match_enabled)
End;

Begin  { MAIN }
    Get_info;
    Set_up;
    While any_not_empty do
        Conflate_sequence_number;
    Writeln('*** END OF CONFLATION ***');
    If want_error then
        Close(errorfile);
    If error then
    Begin
        Writeln('Press any key to continue.');
        tmpch := ReadKey()
    End;
    Close(conflated)
End.

