PROGRAM Collate;
    { Written by Michele Cottrell, ADFA, Computer Centre, Canberra }
    { Translated into Turbo by Boyd Nation, Mississippi State University
      Computing Center, 1986 }
    { This program uses the file SORTPT.TMP, output from Precollat,
      which is the file of sorted matching points between MASTER and COMPARE.
        It produces the file VARIANTS which are the variations found between
    the files using the parameters PICKUPS and MAXMATCH to format the output.}

CONST 
    hy      = '-';
    maxstrg = 140;
    seqmax  = 7;

TYPE
    String2    = Packed Array [1..2] of Char;
    String3    = String[3];
    String7    = Packed Array [1..seqmax] of Char;
    String22   = Packed Array [1..22] of Char;
    String80   = String[80];
    Packed9    = Packed Array [1..9] of Char;
    String140  = Packed Array [1..maxstrg] of Char;
    Startr     = Record
                     mstpt  : String7;
                     compt  : String7;
                     junk   : String2
                 End;
    Varsaver   = Record
                     varrec : String22
                 End;
    Stringptr  = ^Stringtype;
    Stringtype = Record
                     lenth  : Integer; { length of char string }
                     char   : String140  { char string }
                 End;
    Daskey     = 1..1000;
    Davkey     = 1..2000;
    Fvarsaver  = File of Stringtype;
    Fsaverec   = File of Stringtype;

VAR
    backwards_scan      : Boolean;
    botheof             : Boolean;
    brec                : Packed Array [1..2] of Stringtype;
    compare             : Text;
    delet               : Char;
    endcom              : Stringtype;
    endmas              : Stringtype;
    eofeither           : Boolean;
    eoff                : Packed Array [1..2] of Boolean;
    eofstart            : Boolean;
    errname             : String80;
    error               : Boolean;
    errorfile           : Text;
    feof                : Packed Array [1..2] of Boolean;
    forwards_scan       : Boolean;
    frec                : Packed Array [1..2] of Stringtype;
    i                   : Integer;
    instring            : Stringtype;
    key                 : Packed Array [1..2] of Integer;
    lastw               : Packed Array [1..2] of Integer;
    lb_space            : Stringtype;
    master              : Text;
    maxmatch            : Integer;
    maxwords            : Integer;
    name                : Packed Array [1..2] of Char;
    null                : Stringtype;
    nowords             : Packed Array [1..2] of Boolean;
    outstring           : Stringtype;
    outvar              : Stringtype;
    overwrite           : Char;
    pickups             : Integer;
    rb_space            : Stringtype;
    rec                 : Packed Array [1..2] of Stringtype;
    s                   : Stringptr;
    save1               : Fsaverec;
    save2               : Fsaverec;
    seq                 : Packed Array [1..2] of String7;
    slash               : Stringtype;
    space               : Stringtype;
    spaces              : Stringtype;
    sptr                : Stringptr;
    start               : Packed Array [1..2] of String7;
    startpoints         : Text;
    startrec            : Startr;
    temp                : Stringtype;
    tempfile            : Text;
    tmp                 : Integer;
    variants            : Text;
    varkey              : Integer;
    varname             : String80;
    varsave             : Fvarsaver;
    want_error          : Boolean;
    want_errorc         : Char;
    word                : Packed Array [1..2,0..50] of Stringtype;
    wordseq             : Packed Array [1..2,0..50] of Stringtype;
    wptr                : Packed Array [1..2] of Integer;
    which               : Integer;

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

PROCEDURE Dagetts(VAR x : Fsaverec; i : Daskey);
Begin
    Seek(x,i);
    Read(x,instring)
End;

PROCEDURE Daputts(VAR y : Fsaverec; j : Daskey);
Begin
    Seek(y,j);
    Write(y,outstring)
End;

PROCEDURE Dagettv(VAR x : Fvarsaver; i : Davkey);
Begin
    Seek(x,i);
    Read(x,instring)
End;

PROCEDURE Daputtv(VAR y : Fvarsaver; j : Davkey);
Begin
    Seek(y,j);
    Write(y,outstring)
End;

PROCEDURE Daopens(VAR f : Fsaverec; filname : Packed9);
Begin
    Assign(f,filname);
    Rewrite(f);
    Close(f);
    Reset(f)
End;

PROCEDURE Daopenv(VAR f : Fvarsaver; filname : Packed9);
Begin
    Assign(f,filname);
    Rewrite(f);
    Close(f);
    Reset(f)
End;

PROCEDURE Readit(VAR ft : Text; VAR st : Stringtype; w : Integer);
VAR
    c                   : Char; 
    i                   : Integer;

Begin
    i := 0;
    If not eof(ft) then    
    Begin   
        While not eoln(ft) and not eof(ft) do
        Begin 
            i := i + 1;
            Read(ft,c);
            st.char[i] := c
        End;
        st.lenth := i;
        If not eof(ft) then
            Readln(ft)      { read over EOLN }
    End
    Else    
    Begin  
        feof[w] := true;
        eoff[w] := true;
        eofeither := true
    End
End;

PROCEDURE Readstart(VAR fr : Text; VAR r : Startr);
VAR 
    charc               : Char;
    y                   : Integer;

Begin
    For y := 1 to seqmax do
        If not eof(fr) then 
        Begin 
            Read(fr,charc);
            r.mstpt[y] := charc
        End;
    For y := 1 to seqmax do
        If not eof(fr) then
        Begin 
            Read(fr,charc);
            r.compt[y] := charc
        End;
    If not eof(fr) then 
        Readln(fr); { read over EOLN char }
    eofstart := eof(fr)
End;

PROCEDURE Assine(VAR v : Stringtype; p : Stringptr);
Begin 
    v := p^
End;

FUNCTION Conkat(a1, a2 : Stringtype) : Stringptr;
VAR 
    c2                  : Stringtype;
    i                   : Integer;
    lng1                : Integer;
    lng2                : Integer;

Begin
    lng1 := a1.lenth;
    lng2 := a2.lenth;
    If lng1 + lng2 <= maxstrg then 
    Begin
        sptr^.char := a1.char;
        c2.char := a2.char;
        For i := 1 to lng2 do
            sptr^.char[lng1 + i] := c2.char[i];
        sptr^.lenth := lng1 + lng2
    End
    Else 
        sptr^.lenth := 0;
    Conkat := sptr
End;

FUNCTION Substr(b : Stringtype; x1, x2 : Integer) : Stringptr;
    { If x2=0 get substring to the end of string b. }
VAR 
    i                   : Integer; 
    l                   : Integer;
Begin
    If x2 = 0 then    
    Begin
        l := b.lenth;
        If l > x1 then 
        Begin
            For i := 1 to l - x1 + 1 do
                sptr^.char[i] := b.char[x1 + i - 1];
            sptr^.lenth := l - x1 + 1
        End;
    End
    Else    
    Begin
        For i := 1 to x2 do
            sptr^.char[i] := b.char[x1 + i - 1];
        sptr^.lenth := x2
    End;
    Substr := sptr
End;

FUNCTION Reverse(c : Stringtype) : Stringptr;
VAR 
    i                   : Integer; 
    lng                 : Integer;

Begin   
    lng := c.lenth;
    For i := 1 to lng do
        sptr^.char[i] := c.char[lng - i + 1];
    sptr^.lenth := lng;
    Reverse := sptr
End;

FUNCTION Stringeq(r : Stringtype; s : String7) : Boolean;
VAR 
    equal               : Boolean;
    i                   : Integer;

Begin 
    equal := true;
    For i := 1 to seqmax do
        equal := (r.char[i] = s[i]) and equal;
    stringeq := equal
End;

FUNCTION Get_st_pt : Boolean;
Begin
    If not eofstart then 
    Begin
        While (((seq[1] > startrec.mstpt) or (seq[2] > startrec.compt))
                         and not eofstart) do
            Readstart(startpoints,startrec);
        If (seq[1] <= startrec.mstpt) and (seq[2] <= startrec.compt) then
        Begin
            start[1]  := startrec.mstpt;
            start[2]  := startrec.compt;
            Get_st_pt := true;
            Writeln('Master start = ',start[1],' Compare start = ',start[2])
        End
        Else 
        Begin
            Get_st_pt := false;
            error := true;
            If want_error then
                Writeln(errorfile,'** Past last starting point **');
            Writeln('** Past last starting point **')
        End
    End
    Else 
    Begin 
        Get_st_pt := false;
        error := true;
        If want_error then
            Writeln(errorfile,'** No starting point **');
        Writeln('** No starting point **')
    End
End;

PROCEDURE Read_file(which : Integer);
VAR 
    i                   : Integer;

PROCEDURE Assign_it;
Begin
    For i := 1 to seqmax do
        seq[which][i] := frec[which].char[i];
    Assine(temp,Substr(frec[which],9,0));
    If not forwards_scan then
        Assine(temp,Conkat(space,temp));
    Assine(rec[which],Conkat(temp,space));
    wptr[which] := 0
End;

Begin {Read_file}
    If eof(master) and (which = 1) then 
    Begin
        feof[1]   := true; 
        eoff[1]   := true; 
        eofeither := true;
        botheof   := eoff[1] and eoff[2];
        frec[1]   := endmas
    End;
    If eof(compare) and (which = 2) then 
    Begin
        feof[2]   := true;
        eoff[2]   := true;
        eofeither := true;
        botheof   := eoff[1] and eoff[2];
        frec[2]   := endcom
    End;
    If forwards_scan then 
    Begin
        frec[which] := spaces;
        If (which = 1) and not eoff[1] then 
        Begin 
            Readit(master,frec[which],which);
            Assign_it
        End
        Else 
            If (which = 2) and not eoff[2] then 
            Begin 
                Readit(compare,frec[which],which);
                Assign_it
            End
    End
    Else 
        If key[which] > 0 then 
        Begin 
            If which = 1 then 
            Begin
                Dagetts(save1,key[which]);
                brec[which] := instring
            End
            Else 
                If which = 2 then
                Begin
                    Dagetts(save2,key[which]);
                    brec[which] := instring
                End;
            If brec[which].lenth > 0 then
                For i := 1 to seqmax do
                    seq[which][i] := brec[which].char[i];
            Assine(temp,Substr(brec[which],9,0));
            Assine(temp,Reverse(temp));
            Assine(rec[which],Conkat(temp,space));
            key[which]  := key[which] - 1;
            wptr[which] := 0
        End
        Else 
        Begin 
            eoff[which] := true;
            eofeither   := true
        End
End;

PROCEDURE Set_up;
Begin 
    feof[1]   := false;
    feof[2]   := false;
    eoff[1]   := false;
    eoff[2]   := false;
    eofstart  := false;
    botheof   := false;
    eofeither := false;
    error     := false;
    maxwords  := 27;
    Write('Maxwords (<cr> for default = 27) : ');
    Readln(maxwords);
    maxmatch  := 2;
    Write('Maxmatch (<cr> for default = 2) : ');
    Readln(maxmatch);
    pickups   := 2;
    Write('Pickups (<cr> for default = 2) : ');
    Readln(pickups);
    Write('Delete temporary files (y/n)? (<cr> for default = YES) : ');
    Readln(delet);
    If ord(delet) = 26 then delet := 'y';
    If maxmatch < pickups then 
    Begin 
        Write('Maxmatch < Pickups ; Pickups = Maxmatch assumed');
        pickups := maxmatch
    End;
    New(sptr); 
    New(s);  { pointer initialisation for CONKAT,SUBSTR,REVERSE }
    forwards_scan := true;
    Read_file(1);
    Read_file(2);
    which := 1;
    readstart(startpoints,startrec);
    start[1] := startrec.mstpt;
    start[2] := startrec.compt;
    lastw[1] := 0;
    lastw[2] := 0
End;

PROCEDURE Output_line;
VAR 
    i                   : Integer;
    j                   : Integer;

Begin     
    If backwards_scan then 
    Begin 
        varkey := varkey + 1;
        outstring := outvar;
        daputtv(varsave,varkey) 
    End
    Else
    Begin 
        If outvar.lenth > 75 then
        Begin
            j := 75;
            While outvar.char[j] <> ' ' do
                j := j - 1;
            For i := 1 to j do
                If (i <> 9) or (outvar.char[9] <> ' ') then
                    Write(variants,outvar.char[i]);
            Writeln(variants);
            For i := j to outvar.lenth do
                outvar.char[i - j + 9] := outvar.char[i];
            outvar.lenth := outvar.lenth - j + 9
        End;
        For i := 1 to outvar.lenth do
            If (i <> 9) or (outvar.char[9] <> ' ') then
                Write(variants,outvar.char[i]);
        Writeln(variants)
    End
End;

PROCEDURE Do_one(which, ptr : Integer);
VAR 
    finish              : Boolean;
    i                   : Integer;
    j                   : Integer;
    s                   : Integer;

Begin 
    i := maxmatch - pickups + 1;
    j := ptr + pickups - 1;
    If j < i then 
        j := i;
    finish := false;
    While not finish do
    Begin 
        outvar := spaces;
        s := i;
        While (not finish) and (outvar.lenth + word[which,i].lenth < 67) do
        Begin 
            If pickups > 0 then 
            Begin 
                If i = maxmatch + 1 then 
                    If forwards_scan then
                        Assine(outvar,Conkat(outvar,lb_space))
                    Else 
                        Assine(outvar,Conkat(outvar,rb_space));
                If i = ptr then
                    If forwards_scan then 
                        Assine(outvar,Conkat(outvar,rb_space))
                    Else 
                        Assine(outvar,Conkat(outvar,lb_space))
            End;
            If i <> 1 then
                Assine(temp,Conkat(space,word[which,i]))
            Else
                Assine(temp,Conkat(spaces,word[which,i]));
            Assine(outvar,Conkat(outvar,temp));
            If i = j then 
                finish := true
            Else 
                i := i + 1
        End;
        If backwards_scan then 
        Begin
            temp.char[1] := name[which];
            temp.lenth := 1;
            Assine(temp,Conkat(temp,wordseq[which,i]));
            Assine(outvar,Reverse(outvar));
            Assine(outvar,Conkat(temp,outvar))
        End
        Else 
        Begin
            temp.char[1] := name[which];
            temp.lenth := 1;
            Assine(temp,Conkat(temp,wordseq[which,s]));
            Assine(outvar,Conkat(temp,outvar))
        End;
        Output_line
    End
End;

PROCEDURE Output_variant(masptr, comptr : Integer);
Begin 
    If forwards_scan then 
    Begin
        Do_one(1,masptr);
        Do_one(2,comptr)
    End
    Else 
    Begin
        Do_one(2,comptr);
        Do_one(1,masptr)
    End
End;

FUNCTION Get_word(which : Integer) : Stringptr;
VAR 
    another             : Boolean;
    c                   : Char;
    i                   : Integer;
    j                   : Integer;
    l                   : Integer; 
    r                   : Integer;
    tlng                : Integer;
    trec                : Stringtype;

Begin 
    trec := rec[which]; 
    tlng := trec.lenth;
    s^   := spaces;
    l    := wptr[which] + 1;
    While (trec.char[l] = ' ') and (l < maxstrg) and (l < tlng) do
        l := l + 1;
    r := l + 1;
    While (trec.char[r] <> ' ') and (r < maxstrg) and (r < tlng) do
        r := r + 1; {Assume that a word will never end on last char of array}
    If  r - l > 28 then     {as this would affect the next ASSIGN }
    Begin
        error := true;
        If want_error then
            Writeln(errorfile,'Overflow at',name[which]:10,seq[which]:10);
        Writeln('Overflow at',name[which]:10,seq[which]:10)
    End;
    wptr[which] := r;
    Assine(s^,Substr(trec,l,r-l));
    If wptr[which] >= tlng then
    Begin
        Read_file(which);
        If not eoff[which] then 
        Begin
            trec := rec[which];
            another := false;
            If forwards_scan then 
            Begin 
                c := s^.char[r - l];
                If (c = '-') or (c = '_') or (trec.char[1] = '_') then 
                    another := true
            End
            Else 
            Begin 
                c := trec.char[1];
                If (c = '_') or (c = '-') or (s^.char[r - l] = '_') then 
                    another := true
            End;
            If another then 
            Begin 
                l := wptr[which] + 1; 
                tlng := trec.lenth;
                While (trec.char[l] = ' ') and (l < maxstrg) and (l < tlng) do
                    l := l + 1;
                r := l + 1;
                While (trec.char[r] <> ' ') and (r < maxstrg) and (r < tlng) do
                    r := r + 1;
                If c = hy then
                    Assine(s^,Conkat(s^,slash));
                    If (s^.lenth + r - l) > 28 then 
                    Begin
                        error := true;
                        If want_error then
                            Writeln(errorfile,
                                    'Overflow at ',name[which],seq[which]);
                        Writeln('Overflow at ',name[which],seq[which])
                    End;
                    Assine(temp,Substr(trec,l,r - 1));
                    Assine(s^,Conkat(s^,temp));
                    wptr[which] := r;
                    If wptr[which] = rec[which].lenth then 
                        Read_file(which)
            End
        End
        Else 
            nowords[which] := true
    End;
    i := 1;
    While i < s^.lenth do
    Begin
        If s^.char[i] = ' ' then
        Begin
            For j := i to s^.lenth - 1 do
                s^.char[j] := s^.char[j + 1];
            s^.lenth := s^.lenth - 1
        End;
        i := i + 1
    End;
    If s^.char[s^.lenth] = ' ' then
        s^.lenth := s^.lenth - 1;
    If s^.lenth = 0 then
        s := get_word(which);
    For i := s^.lenth + 1 to maxstrg do
        s^.char[i] := ' ';
    Get_word := s
End;

PROCEDURE Final_variants;

PROCEDURE Dump_rest(which : Integer);
VAR 
    curseq              : Stringtype;
    end_it              : Boolean;
    i                   : Integer;
    j                   : Integer;

Begin   
    i := lastw[which];
    While Stringeq(wordseq[which,i],seq[which]) and (i > 1) do
        i := i - 1;
    lastw[which] := i;
    i := 1;
    While i <= lastw[which] do
    Begin 
        curseq := wordseq[which,i];
        temp.char[1] := name[which];
        temp.lenth := 1;
        outvar := spaces;
        Assine(temp,Conkat(temp,curseq));
        Assine(outvar,Conkat(outvar,temp));
        end_it := (i > lastw[which]);
        While (wordseq[which,i].char = curseq.char) and not end_it 
               and (outvar.lenth < 67) do
        Begin   
            Assine(temp,Conkat(word[which,i],space));
            Assine(outvar,Conkat(outvar,temp));
            If i <= lastw[which] then 
                i := i + 1
            Else 
                end_it := true
        End;
        Output_line
    End;
    Repeat 
        temp.char[1] := name[which];
        For j := 1 to seqmax do
            temp.char[j + 1] := seq[which][j];
        temp.lenth := seqmax + 1;
        Assine(outvar,Conkat(temp,rec[which]));
        Output_line;
        Read_file(which)
    Until feof[which]
End;

Begin   { of Final_variants }
    Dump_rest(1);
    Dump_rest(2)
End;

PROCEDURE Dump_backwards;

PROCEDURE Dump_one(which : Integer);
VAR 
    i                   : Integer;
    j                   : Integer;
    tmp                 : Stringtype;
    tryseq              : String7;

Begin   
    For i := 1 to key[which] do
    Begin 
        If which = 1 then 
        Begin 
            Dagetts(save1,i);
            brec[which] := instring
        End
        Else 
        Begin 
            Dagetts(save2,i);
            brec[which] := instring
        End;
        temp := null;
        temp.char[1] := name[which];
        temp.lenth := 1;
        Assine(outvar,Conkat(temp,brec[which]));
        Output_line
    End;
    key[which] := 0;
    tmp := null;
    tmp.char[1] := name[which];
    For j := 1 to seqmax do
        tmp.char[j + 1] := seq[which][j];
    tmp.lenth := 8;
    If wptr[which] = 0 then 
    Begin 
        Assine(temp,Reverse(rec[which]));
        Assine(outvar,Conkat(tmp,temp));
        Output_line
    End
    Else 
        If wptr[which] < rec[which].lenth then 
        Begin 
            Assine(temp,Substr(rec[which],wptr[which],0));
            Assine(temp,Reverse(temp));
            Assine(outvar,Conkat(tmp,temp));
            Output_line
        End;
    i := lastw[which];
    While i > 0 do
    Begin 
        For j := 1 to seqmax do
            tryseq[j] := wordseq[which,i].char[j];
        outvar := null;
        While (i > 0) and ((outvar.lenth + word[which,i].lenth) < 67)
                    and (Stringeq(wordseq[which,i],tryseq)) do
        Begin 
            Assine(temp,Reverse(word[which,i]));
            Assine(temp,Conkat(temp,space));
            Assine(outvar,Conkat(outvar,temp));
            i := i - 1
        End;
        tmp.char[1] := name[which];
        tmp.lenth   := 1;
        Assine(temp,Conkat(wordseq[which,i+1],outvar));
        Assine(outvar,Conkat(tmp,temp));
        Output_line
    End
End;

Begin   { of Dump_backwards }
    backwards_scan := false;
    forwards_scan := true;
    Dump_one(1);
    Dump_one(2);
    While varkey > 0 do
    Begin   
        Dagettv(varsave,varkey);
        outvar := instring;
        Output_line;
        varkey := varkey - 1
    End
End;

PROCEDURE Find_variants;
VAR 
    done                : Boolean;
    i                   : Integer;
    j                   : Integer;
    lastone             : Integer;
    okay                : Boolean;
    try                 : Integer;
    wh                  : Integer;

FUNCTION Extend(masptr, comptr : Integer) : Boolean;
VAR
    agrees              : Boolean;
    i                   : Integer;
Begin
    agrees := true;
    For i := 1 to maxmatch - 1 do
        If agrees then 
            agrees := (word[1,masptr+i].char=word[2,comptr+i].char);
    extend := agrees
End;

PROCEDURE Reset_table(masptr, comptr: Integer);
VAR 
    i                   : Integer;

Begin   
    For i := 1 to lastw[1] - masptr + 1 do
    Begin   
        wordseq[1,i] := wordseq[1,i + masptr - 1];
        word[1,i] := word[1,i + masptr - 1]
    End;
    lastw[1] := lastw[1] - masptr + 1;
    For i := 1 to lastw[2] - comptr + 1 do
    Begin   
        wordseq[2,i] := wordseq[2,i + comptr - 1];
        word[2,i] := word[2,i + comptr - 1]
    End;
    lastw[2] := lastw[2] - comptr + 1;
    For wh := 1 to 2 do
         While (lastw[wh] < maxmatch + 1) and not eoff[wh] do
         Begin   
             lastw[wh] := lastw[wh] + 1;
             For j := 1 to seqmax do
                 wordseq[wh,lastw[wh]].char[j] := seq[wh][j];
             Assine(word[wh,lastw[wh]],Get_word(wh))
        End
End;

PROCEDURE End_of_scan;
Begin   
    If forwards_scan then 
    Begin  
        If eofeither then 
            Final_variants;
    End { ELSE all is well }
    Else 
        Dump_backwards
End;

Begin { of Find_variants }
    nowords[1] := false;
    nowords[2] := false;
    For i := 1 to maxmatch do
    Begin 
        word[1,i] := null;
        word[2,i] := null;
        For j := 1 to seqmax do
        Begin   
            wordseq[1,i].char[j] := seq[1][j];
            wordseq[2,i].char[j] := seq[2][j]
        End;
        wordseq[1,i].lenth := seqmax;
        wordseq[2,i].lenth := seqmax
    End;
    lastw[1] := maxmatch + 1;
    lastw[2] := maxmatch + 1;
    For j := 1 to seqmax do
    Begin 
        wordseq[1,maxmatch + 1].char[j] := seq[1][j];
        wordseq[2,maxmatch + 1].char[j] := seq[2][j]
    End;
    Assine(word[1,maxmatch+1],Get_word(1));
    Assine(word[2,maxmatch+1],Get_word(2));
    okay := true;
    While okay do
    Begin 
        While ((word[1,maxmatch + 1].char = word[2,maxmatch + 1].char) 
                 and not nowords[which]) do
        Begin
            For i := 1 to lastw[1] - 1 do
            Begin
                word[1,i] := word[1,i + 1];
                wordseq[1,i] := wordseq[1,i + 1]
            End;
            For i := 1 to lastw[2] - 1 do
            Begin
                word[2,i] := word[2,i + 1];
                wordseq[2,i] := wordseq[2,i + 1]
            End;
            lastw[1] := lastw[1] - 1;
            lastw[2] := lastw[2] - 1;
            For i := 1 to 2 do
                If lastw[i] < maxmatch + 1 then
                Begin
                    lastw[i] := lastw[i] + 1;
                    For j := 1 to seqmax do
                        wordseq[i,lastw[i]].char[j] := seq[i][j];
                    wordseq[i,lastw[i]].lenth := seqmax;
                    Assine(word[i,lastw[i]],Get_word(i))
                End
        End;
        If eofeither then 
             okay := false
        Else
        Begin
            For try := 1 to 2 do
            Begin
                i := lastw[try] + 1;
                While (i <= maxwords) and not eoff[try] do
                Begin
                    For j := 1 to seqmax do
                        wordseq[try,i].char[j] := seq[try][j];
                    wordseq[try,i].lenth := seqmax;
                    Assine(word[try,i],Get_word(try));
                    i := i + 1
                End;
                lastw[try] := i - 1
            End;
            lastone := maxmatch + 2;
            done := false;
            While (lastone <= lastw[1]) and (lastone <= lastw[2] - maxmatch +1)
                                and (lastone <= maxwords) and not done do
            Begin
                try := maxmatch + 1;
                While (try <= lastone) and not done do
                Begin
                    If word[1,try].char = word[2,lastone].char then 
                        If Extend(try,lastone) then 
                        Begin
                            Output_variant(try,lastone);
                            Reset_table(try,lastone);
                            done := true
                        End;
                        If try < lastone then 
                            If word[2,try].char = word[1,lastone].char then 
                                If Extend(lastone,try) then 
                                Begin
                                    Output_variant(lastone,try);
                                    Reset_table(lastone,try);
                                    done := true
                                End;
                        If not done then
                            try:=try+1
                End;
                If not done then
                    lastone:=lastone+1
            End;
            If not done then
                okay := false
        End { of IF eofeither }
    End;       { of WHILE okay DO }
    End_of_scan
End; { OF Find_variants }

PROCEDURE Forwards;
VAR 
    i                   : Integer;

Begin 
    forwards_scan  := true;
    backwards_scan := false;
    For i := 1 to seqmax do
        seq[1][i] := frec[1].char[i];
    Assine(temp,Substr(frec[1],9,0));
    Assine(rec[1],Conkat(temp,space));
    For i := 1 to seqmax do
        seq[2][i] := frec[2].char[i];
    Assine(temp,Substr(frec[2],9,0));
    Assine(rec[2],Conkat(temp,space));
    wptr[1]   := 0; 
    wptr[2]   := 0;
    eoff[1]   := false;
    eoff[2]   := false;
    eofeither := false;
    If not botheof then 
        Find_variants
End;

PROCEDURE Backwards;

PROCEDURE Drain_table(which : Integer);
VAR 
    currseq             : String7;
    end_it              : Boolean;
    found               : Boolean;
    i                   : Integer;
    j                   : Integer;

Begin 
    i := 1; 
    found  := false; 
    end_it := false;
    While not found and (i <= lastw[which]) do
        If Stringeq(wordseq[which,i],seq[which]) then 
            found := true
        Else 
            i := i + 1;
    lastw[which] := i - 1;
    i := 1;
    While (i <= lastw[which]) and not end_it do
    Begin 
        brec[which] := wordseq[which,i];
        Assine(brec[which],Conkat(brec[which],space));
        For j := 1 to seqmax do
            currseq[j] := wordseq[which,i].char[j];
        While Stringeq(wordseq[which,i],currseq) and (i <= lastw[which])
                        and not end_it do
        Begin 
            If i < lastw[which] then
                Assine(temp,Conkat(word[which,i],space))
            Else
                temp := word[which,i];
            Assine(brec[which],Conkat(brec[which],temp));
            If i = maxwords then 
                end_it := true
            Else 
                i := i + 1
        End;
        key[which] := key[which] + 1;
        If which = 1 then 
        Begin 
            outstring := brec[which];
            Daputts(save1,key[which])
        End
        Else 
        Begin  
            outstring := brec[which];
            Daputts(save2,key[which])
        End
    End
End;

PROCEDURE Save_file(which : Integer);
Begin 
    While (seq[which] <> start[which]) and not(eof(master) or eof(compare)) do
    Begin 
        key[which] := key[which] + 1;
        If which = 1 then 
        Begin 
            outstring := frec[which];
            Daputts(save1,key[which])
        End
        Else 
        Begin 
            outstring := frec[which];
            Daputts(save2,key[which])
        End;
        Read_file(which)
    End
End;

Begin { of Backwards }
    key[1] := 0;
    key[2] := 0;
    varkey := 0;
    Drain_table(1);
    Save_file(1);
    Drain_table(2);
    Save_file(2);
    backwards_scan := true;
    forwards_scan := false;
    eoff[1]   := false;
    eoff[2]   := false;
    eofeither := false;
    If (key[1] > 0) and (key[2] > 0) then 
    Begin 
        Read_file(1);
        Read_file(2);
        Find_variants
    End
End;

Begin { main program }
    ClrScr;
    lb_space.char[1] := ' '; 
    lb_space.char[2] := '(';
    lb_space.lenth   := 2;
    rb_space.char[1] := ' ';
    rb_space.char[2] := ')'; 
    rb_space.lenth   := 2;
    For i := 1 to maxstrg do
        spaces.char[i] := ' ';
    spaces.lenth  := 0;
    space.char[1] := ' ';
    space.lenth := 1;
    slash.char[1] := '/';
    slash.lenth := 1;
    null.lenth  := 0;
    endmas := null; 
    endcom := null;
    For i := 1 to seqmax do
    Begin 
        endmas.char[i] := '9';
        endcom.char[i] := '9'
    End;
    endmas.char[8] := 'M';
    endcom.char[8] := 'C';
    For i := 9 to 20 do
    Begin 
        endmas.char[i] := '*';
        endcom.char[i] := '*'
    End;
    endmas.lenth := 20;
    endcom.lenth := 20;
    outvar.lenth := 0;
    temp.lenth   := 0;
    name[1]      := 'M';
    name[2]      := 'C';
    Daopens(save1,'save1.tmp');
    Daopens(save2,'save2.tmp');
    Daopenv(varsave,'varsa.tmp');
    Repeat
        Write('Filename for output file : ');
        Readln(varname);
        Add_ext(varname,'var');
        Assign(variants,varname);
        {$i-}
        Reset(variants);
        {$i+}
        tmp := ioresult;
        overwrite := 'n';
        If tmp = 0 then
        Begin
          Write('File already on disk.  Do you want to write over it (y/n)? ');
          Readln(overwrite)
        End
    Until (tmp = 1) or (overwrite = 'y') or (overwrite = 'Y');
    Write('Do you want an error file created? ');
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
        Until (tmp = 1) or (overwrite = 'y') or (overwrite = 'Y');
        Rewrite(errorfile)
    End;
    Assign(master,'outmst.tmp');
    Assign(compare,'outcom.tmp');
    Assign(startpoints,'sortpt.tmp');
    Reset(master);
    Reset(compare);
    Rewrite(variants);
    Reset(startpoints);
    Set_up;         { set up records from files etc }
    While not botheof do
        If Get_st_pt then 
        Begin   
            Backwards;   { process files }
            Forwards
        End
        Else 
            Final_variants;
    Close(master);
    Close(compare);
    Close(variants);
    Writeln('  ***  End of collation  ***  ');
    If want_error then
        Close(errorfile);
    If error then
    Begin
        Writeln('Hit any key to continue.');
        Read(kbd,overwrite)
    End;
    If (delet = 'y') or (delet = 'Y') then
        Halt(1)
End.

