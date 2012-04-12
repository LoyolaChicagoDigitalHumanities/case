PROGRAM Precollate;
USES Crt;
    { Written by Michele Cottrell, ADFA, Computer Centre, Canberra, 1985 }
    { Translated slowly into Turbo by Boyd Nation, Mississippi State
      University Computing Center, 1986 }
    { This program takes each of the original files and produces files
    which have a page and line number prepended to each line.
       A hash key is calculated for each line. These are compared between
    the two files to determine matching lines. Each pair of matching lines
    is then sorted to be used by COLLATE. }

CONST 
    maxline = 132;
    maxchar = 23;
    maxseq  = 7;

TYPE 
    Textarray = Packed Array [1..maxline] of Char;
    String7   = Packed Array [1..maxseq] of Char;
    String23  = Packed Array [1..maxchar] of Char;
    String10  = Packed Array [1..10] of Char;

VAR 
    compare     : Text;
    fg          : Text;
    fp          : Text;
    fq          : Text;
    fs          : Text;
    fx          : Text;
    fy          : Text;
    master      : Text;
    newfile     : Text;
    oldfile     : Text;
    spaces      : Textarray;
    temp        : Integer;
    tempcomp    : String[80];
    tempmast    : String[80];

PROCEDURE Sort(VAR oldfile, newfile : Text);

TYPE
    Rectype = Packed Array [1..79] of Char;

VAR
    i           : Integer;
    instring    : String[79];
    lines       : Integer;
    outstring   : Rectype;
    temp        : File of Rectype;

PROCEDURE Quick(a, b : Integer);

VAR
    down        : Integer;
    up          : Integer;
    final       : Integer;
    key1        : Rectype;
    key2        : Rectype;

Begin
    If a < b then
    Begin
        down  := a;
        up    := b;
        final := a;
        Seek(temp,a);
        Read(temp,key1);
        Seek(temp,b);
        Read(temp,key2);
        While down <> up do
        Begin
            While (down < up) and (key1 < key2) do
            Begin
                up := up - 1;
                Seek(temp,up);
                Read(temp,key2)
            End;
            If (key1 >= key2) and (down <> up) then
            Begin
                final := up;
                Seek(temp,down);
                Write(temp,key2);
                down := down + 1;
                Seek(temp,down);
                Read(temp,key2)
            End;
            While (down < up) and (key1 > key2) do
            Begin
                down := down + 1;
                Seek(temp,down);
                Read(temp,key2)
            End;
            If (key1 <= key2) and (down <> up) then
            Begin
                final := down;
                Seek(temp,up);
                Write(temp,key2);
                up := up - 1;
                Seek(temp,up);
                Read(temp,key2)
            End
        End;
        Seek(temp,final);
        Write(temp,key1);
        Quick(a,final - 1);
        Quick(final + 1,b)
    End
End;

Begin
    lines := 0;
    Assign(temp,'temp.tmp');
    Reset(oldfile);
    Rewrite(temp);
    While not eof(oldfile) do
    Begin
        Readln(oldfile,instring);
        lines := lines + 1;
        For i := 1 to 79 do
            If i > length(instring) then
                outstring[i] := ' '
            Else
                outstring[i] := instring[i];
            Write(temp,outstring)
    End;
    Close(temp);
    Close(oldfile);
    Reset(temp);
    Quick(0,lines - 1);
    Close(temp);
    Reset(temp);
    Rewrite(newfile);
    For i := 1 to lines do
    Begin
        Read(temp,outstring);
        instring := outstring;
        Writeln(newfile,instring)
    End;
    Close(newfile)
End;

PROCEDURE Paginate(VAR f : Text; g : String10);
     { PAGINATE inserts a page sequence number composed of the page and line
numbers at the start of each line in the output file. }
VAR 
    ch          : Char;
    emptyline   : Boolean;
    i           : Integer;
    ignore      : Set of Char;
    lastchar    : Integer;
    linenum     : Integer;
    pagenum     : Integer;
    rec         : Textarray;
    seqnum      : Real;
    start       : Integer;

PROCEDURE Readtext(VAR x : Textarray;VAR notext : Boolean;VAR lstch : Integer);
     {Reads in text from file F into array X. Sets notext if line is empty.}
VAR 
    endline     : Boolean;
    i           : Integer;

Begin
    x := spaces;
    i := 0; 
    endline := false; 
    lstch := 1;
    While not endline do
        If not eoln(f) then 
        Begin 
            i := i+1;
            Read(f,x[i])
        End
        Else 
        Begin 
            endline := true;
            lstch := i;
            While x[lstch] = ' ' do
                lstch := lstch-1;
            If i = 0 then 
                notext := true
        End;
    If not eof(f) then 
        Readln(f)
End;

FUNCTION Xnumb(r : Textarray; y : Integer) : Integer;
     { Extracts an integer from array r starting at position y. }
VAR 
    finish      : Boolean;
    x           : Integer; 

Begin 
    x := 0; 
    finish := false;
    While not finish do
        If (r[y] >= '0') and (r[y] <= '9') then 
        Begin 
            x := x * 10 + (ord(r[y]) - ord('0'));
            y := y + 1
        End
        Else 
            finish := true;
    Xnumb := x
End;

Begin {Main program of PAGINATE}
    For i := 1 to maxline do
        spaces[i] := ' ';
    ignore := [' ','"',chr(39),chr(96)];
    linenum := 0;
    pagenum := 0;
    start := 0;
    emptyline := false;
    ch := 'S';
    Assign(fg,g);
    Reset(f);
    Rewrite(fg);
    While not eof(f) do
    Begin 
        Readtext(rec,emptyline,lastchar);
        If not emptyline then 
        Begin 
            If rec[1] = '.' then 
            Begin 
                If (rec[2] = 'p') or (rec[2] = 'P') then
     {Locate .p entries to extract page number }
                Begin
                    If rec[3] = '-' then 
                    Begin 
                        pagenum := Xnumb(rec,4);
                        ch := '-'
                    End
                    Else 
                    Begin 
                        pagenum := Xnumb(rec,3);
                        ch := 'S'
                    End;
                    linenum := 0
                End
            End
            Else 
                If rec[1] = ':' then 
                    linenum := linenum+1
                Else 
                    If not (((rec[1] = '{') and ((rec[2] = 'c') or
                             (rec[2] = 'r'))) or (rec[1] = '*')) then
 { ignore centred text,titles and comments - line starts with {c,{r or *. }
                    Begin 
                        linenum := linenum + 1;
                        If (rec[1] = ' ') and (rec[2] = ' ') and 
                           (rec[3] = ' ') then
                        Begin 
                            start := 3;
                            While rec[start + 1] in ignore do
                                start := start + 1;
                            rec[start] := '~'
                        End
                        Else
                            start := 1;
                        seqnum := pagenum;
                        seqnum := seqnum * 1000;
                        seqnum := seqnum + linenum;
                        Write(fg,ch:1,seqnum:6:0,' ':1);
                        For i := start to lastchar do
                            Write(fg,rec[i]:1);
                        Writeln(fg)
                    End
        End
    End;
    Close(fg);
    Close(f)
End;

PROCEDURE Prescan(x, y : String10);
    { Reads each line of file y, calculates a hash key and prints to file y
    the line number, a string of characters and the hash value. }
VAR 
    a           : Real;
    ch          : Char;
    charray     : String23;
    firstch     : Char;
    h           : Integer;    
    i           : Integer;   
    j           : Integer;    
    k           : Integer;
    linend      : Boolean;
    n           : Integer;     {i=word count,k=letters/word,n=array index }

Begin    {prescan}
    Assign(fx,x);
    Assign(fy,y);
    Reset(fx);
    Rewrite(fy);
    While not eof(fx) do
    Begin 
        Read(fx,firstch,a);
        i := 0;
        k := 0;
        h := 0;
        n := 0;
        linend := false;
        Read(fx,ch);
        Read(fx,ch);
        If ch = '~' then
        Begin
            While (n < maxchar) and not linend do
            Begin 
                i := i + 1;
                While (ch = ' ') and not eoln(fx) do     { read over spaces }
                    Read(fx,ch);
                While (ch <> ' ') and not linend do
                Begin 
                    k := k + 1;
                    If n < maxchar then 
                    Begin 
                        n := n + 1;     { increment index into array }
                        charray[n] := ch   {put char into array }
                    End;
                    If not eoln(fx) and (i <= 4) then 
                        Read(fx,ch)
                    Else 
                        linend := true
                End;
                If i <= 4 then 
                Begin 
                    h := h + i * k;    { calculate hash for this word }
                    While h >= 100 do
                        h := h - 100;
                    k := 0
                End
            End;
            If (i < 4) then 
                For j := i + 1 to 4 do
                Begin
                    h := h + j * i;
                    While h >= 100 do
                        h := h - 100
                End;
            Readln(fx);
            Write(fy,h:2,' ':1);
            If i >= 4 then 
                n := n - 1;
            For j := 1 to n do
                Write(fy,charray[j]:1);
            If n < maxchar then 
                For j := n + 1 to maxchar do
                     Write(fy,' ':1);
            Writeln(fy,firstch:1,a:6:0)
        End
        Else
            Readln(fx);
     End;
     Close(fx);
     Close(fy)
End;

PROCEDURE Match(p, q, s : String10);
   { Match reads the paragraph lines from both PRESCANs and creates a file of
matching start points for collation }
VAR 
    cchars      : String23;
    ckey        : Integer;
    cseq        : String7;
    ignore      : Set of Char;
    mchars      : String23;
    mkey        : Integer;
    mseq        : String7; 

PROCEDURE Readmst;
VAR 
    i           : Integer;
    j           : Integer;
Begin
    For i := 1 to maxseq do
        mseq[i] := ' ';
    If not eof(fp) then
    Begin
        Read(fp,mkey);
        Read(fp,mchars[1]);
        For i := 1 to maxchar do
            Read(fp,mchars[i]);
        For i := 1 to maxchar do
            If mchars[i] in ignore then
            Begin
                For j := i to maxchar - 1 do
                    mchars[j] := mchars[j + 1];
                mchars[maxchar] := ' '
            End;
        For i := 1 to maxseq do
            Read(fp,mseq[i]);
        Readln(fp)
    End
End;

PROCEDURE Readcom;
VAR 
    i           : Integer;
    j           : Integer;
Begin 
    For i := 1 to maxseq do
        cseq[i] := ' ';
    If not eof(fq) then 
    Begin 
        Read(fq,ckey);
        Read(fq,cchars[1]);
        For i := 1 to maxchar do
            Read(fq,cchars[i]);
        For i := 1 to maxchar do
            If cchars[i] in ignore then
            Begin
                For j := i to maxchar - 1 do
                    cchars[j] := cchars[j + 1];
                cchars[maxchar] := ' '
            End;
        For i := 1 to maxseq do
            Read(fq,cseq[i]);
        Readln(fq)
    End
End;

Begin { main program of MATCH }
    ignore := [' ','"',chr(39),chr(96)];
    Assign(fp,p);
    Assign(fq,q);
    Assign(fs,s); 
    Reset(fp);
    Reset(fq);
    Rewrite(fs);
    Readmst;
    Readcom;
    While not (eof(fp) or eof(fq)) do
    Begin 
        If mkey > ckey then 
            Readcom
        Else 
           If mkey < ckey then 
               Readmst
           Else 
               If mchars > cchars then 
                   Readcom
               Else 
                   If mchars < cchars then 
                       Readmst
                   Else 
                   Begin 
                       Writeln(fs,mseq,cseq);
                       Readmst;
                       Readcom
                   End
    End;
    If mchars = cchars then
        Writeln(fs,mseq,cseq);
    Close(fp);
    Close(fq);
    Close(fs)
End;

Begin  { main program }
    ClrScr;
    Assign(master,'master.tmp');
    Assign(compare,'compare.tmp');
    Paginate(master,'outmst.tmp');
    Writeln('Master file paginated.');
    Paginate(compare,'outcom.tmp');
    Writeln('Comparison file paginated.');
    Prescan('outmst.tmp','mstscn.tmp');
    Writeln('Master file scanned.');
    Assign(oldfile,'mstscn.tmp');
    Assign(newfile,'mprscn.tmp');
    Sort(oldfile,newfile);
    Writeln('Master file sorted.');
    Prescan('outcom.tmp','comscn.tmp');
    Writeln('Comparison file scanned.');
    Assign(oldfile,'comscn.tmp');
    Assign(newfile,'cprscn.tmp');
    Sort(oldfile,newfile);
    Writeln('Comparison file sorted.');
    Match('mprscn.tmp','cprscn.tmp','mtchpt.tmp');
    Writeln('Matchpoints found.');
    Assign(oldfile,'mtchpt.tmp');
    Assign(newfile,'sortpt.tmp');
    Sort(oldfile,newfile);
    Writeln('Matchpoints sorted.')
End.

