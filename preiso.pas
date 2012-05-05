PROGRAM Preisolate;
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
    String3   = String[3];
    String80  = String[80];

VAR
    c           : Char;
    error       : Boolean;
    fg          : Text;
    lineno      : Integer;
    master      : Text;
    spaces      : Textarray;
    temp        : Integer;
    tempmast    : String80;

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

PROCEDURE Paginate(VAR f : Text; g : String10);
     { PAGINATE inserts a page sequence number composed of the page and line
numbers at the start of each line in the output file. }
VAR 
    ch          : Char;
    emptyline   : Boolean;
    i           : Integer;
    lastchar    : Integer;
    linenum     : Integer;
    pagenum     : Integer;
    rec         : Textarray;
    seqnum      : Integer;
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
        emptyline := false;
        Readtext(rec,emptyline,lastchar);
        lineno := lineno + 1;
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
                    linenum := linenum + 1
                Else 
                    If not (((rec[1] = '{') and ((rec[2] = 'c') or
                             (rec[2] = 'r'))) or (rec[1] = '*')) then
 { ignore centred text,titles and comments - line starts with c,r or *. }
                    Begin 
                        linenum := linenum + 1;
                        If (rec[1] = ' ') and (rec[2] = ' ') and 
                           (rec[3] = ' ') then
                        Begin 
                            rec[3] := '~';
                            start := 3
                        End
                        Else 
                            start := 1;
                        seqnum := pagenum * 1000 + linenum;
                        Write(fg,ch:1,seqnum:6,' ':1);
                        For i := start to lastchar do
                            Write(fg,rec[i]:1);
                        Writeln(fg)
                    End
        End
        Else
        Begin
            error := true;
            Writeln('Line ',lineno,' - Blank line')
        End
    End;
    Close(fg);
    Close(f)
End;

Begin  { main program }
    error  := false;
    lineno := 0;
    Repeat
        Write('File name for input: ');
        Readln(tempmast);
        Add_ext(tempmast,'ms');
        Assign(master,tempmast);
        {$I-}
        Reset(master);
        {$I+}
        temp := ioresult;
        If temp = 1 then
            Writeln('File not on disk')
    Until temp = 0;
    Paginate(master,'outmst.tmp');
    If error then
    Begin
        Writeln('Press any key to continue.');
        c := ReadKey()
    End
End.

