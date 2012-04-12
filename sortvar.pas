PROGRAM sortvariants;

TYPE
    Linetype  = (mline,labeline,cline);
    Letterset = Set of  'A'..'Z';
    String3   = String[3];
    String80  = String[80];

VAR
    codechart                   : Packed Array ['A'..'Z'] of Integer;
    codecnt                     : Integer;
    codeset                     : Letterset;
    curtype                     : Linetype;
    f                           : Packed Array [1..8] of Text;
    i                           : Integer;
    linecode                    : Packed Array [1..8] of Char;
    linelength                  : Integer;
    numberoffiles               : Integer;
    overwrite                   : Char;
    prevtype                    : Linetype;
    startcol                    : Integer;
    state                       : Linetype;
    stopcol                     : Integer;
    tempname                    : String80;
    textline                    : Packed Array [1..80] of Char;
    tmp                         : Integer;
    variants                    : Text;

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

PROCEDURE initialize;
VAR
    alpha : Char;
Begin
    codeset := ['A','B','D','E','F','G','H','I',
                'J','K','L','N','O','P','Q','R',
                'T','U','V','W','X','Y','Z'];
    curtype := mline;
    For alpha := 'A' to 'Z' do
        codechart[alpha] := 9
End;

PROCEDURE openfiles;
VAR
    code        : Char;
    i           : Integer;
    filetype    : Char;

PROCEDURE getcode(var code:Char);
Begin
    Repeat
        Write('Enter code for file # ',i,' : ');
        Readln(code)
    Until code in codeset
End;

Begin
    Write('Type of file (''V'' for variants, ''C'' for conflation) : ');
    Readln(filetype);
    Repeat
        Write('Filename for input file : ');
        Readln(tempname);
        If (filetype = 'V') or (filetype = 'v') then
            Add_ext(tempname,'var')
        Else
            Add_ext(tempname,'cfl');
        Assign(variants,tempname);
        {$i-}
        Reset(variants);
        {$i+}
        tmp := ioresult;
        If tmp = 1 then
            Writeln('File not on disk.')
    Until tmp = 0;
    If (filetype = 'V') or (filetype = 'v') then
        startcol := 1
    Else
        startcol := 3;
    stopcol  := startcol + 7;
    Write('Enter number of output files : ');
    Readln(numberoffiles);
    For i := 1 to numberoffiles do
    Begin
        Repeat
            Write('Filename for output file # ',i,' : ');
            Readln(tempname);
            If (filetype = 'V') or (filetype = 'v') then
                Add_ext(tempname,'var')
            Else
                Add_ext(tempname,'cfl');
            Assign(f[i],tempname);
            {$i-}
            Reset(f[i]);
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
        getcode(code);
        codechart[code] := i;
        Rewrite(f[i])
    End
End;

PROCEDURE setstate;
Begin
    If (curtype = labeline) then 
        state := labeline
    Else 
        If (curtype = mline) and (prevtype = cline) then 
            state := mline
End;

PROCEDURE getline;
VAR
    letter      : Char;
Begin
    linelength := 0;
    While not eoln(variants) do
    Begin
        Read(variants,letter);
        linelength := linelength + 1;
        textline[linelength] := letter
    End;
    Readln(variants)
End;

PROCEDURE scancodes;
VAR
    colmptr    : Integer;
    i          : Integer;
Begin
    colmptr := startcol;
    If (curtype = labeline) then 
{    if current line type is a labeled line or an unlabled line
     immediately following a labeled line then...             }
    Begin
{    search label field for a valid label                     }
        While (colmptr <= stopcol) and not (textline[colmptr] in codeset) do
            colmptr := colmptr + 1;
        If (colmptr <= stopcol) then 
{    if a valid label was found in the search field then reset the
     code count and save any labels found in label field otherwise
     leave the previous count and labels as they were        }
         Begin
             codecnt := 0;
             For i := colmptr to stopcol do
             Begin
                 If textline[i] in codeset then 
                 Begin
                     codecnt := codecnt + 1;
                     linecode[codecnt] := textline[i]
                 End
             End
         End
     End
End;

PROCEDURE sendline;
VAR
    i       : Integer;
    j       : Integer;
Begin
    If (state = labeline) then
    Begin
        For i := 1 to codecnt do
        Begin
            For j := 1 to linelength do
                If (j = startcol) and (textline[j] in codeset) then
                    Write(f[codechart[linecode[i]]],'M')
                Else
                    Write(f[codechart[linecode[i]]],textline[j]);
            Writeln(f[codechart[linecode[i]]])
        End
    End
End;

PROCEDURE typeline;
VAR
    codefound   : Boolean;
    colmptr     : Integer;
Begin
    colmptr := startcol;
    codefound := false;
    While (not codefound) and (colmptr <= stopcol) do
    Begin
        If textline[colmptr] in codeset then 
        Begin
            curtype := labeline;
            codefound := true
        End
        Else 
            If (textline[colmptr] = 'M') then 
            Begin
                curtype := mline;
                codefound := true
            End
            Else 
                If (textline[colmptr] = 'C') then 
                Begin
                    curtype := cline;
                    codefound := true
                End;
        colmptr := colmptr + 1
    End;
    If (not codefound) then 
        curtype := prevtype
{   note that if a line following a label line has no designator
    (M,C,or a label) then the line is flagged as a label line.
    Hence the routine which scans the codes must take this into account }
End;

PROCEDURE processvariants;
Begin
    While not eof(variants) do
    Begin
        getline;
        prevtype := curtype;
        typeline;
        If (curtype = labeline) then 
            scancodes;
        setstate;
        sendline
    End
End;

Begin
    ClrScr;
    initialize;
    openfiles;
    processvariants;
    Close(variants);
    For i := 1 to numberoffiles do
        Close(f[i])
End.

