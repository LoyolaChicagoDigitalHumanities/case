PROGRAM print_conflt;
USES Crt, Printer;

TYPE
    String3  = String[3];
    String80 = String[80];

VAR
    c                           : Char;
    flag                        : Boolean;
    infile                      : Text;
    lastch                      : Char;
    line                        : String80;
    linelen                     : Integer;
    lineno                      : Integer;
    printseq                    : Boolean;
    tempname                    : String80;
    tmp                         : Integer;

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

PROCEDURE newline;
Begin
    Assignlst (lst,'|/usr/bin/lpr -m');
    Writeln(lst);
    linelen := 0;
    lastch := ' ';
    lineno := lineno + 1;
    If lineno > 58 then
    Begin
        Write(lst,chr(12));
        lineno := 0
    End
End;

PROCEDURE outline(l:String80;ch:Char);
VAR
    i : Integer;
    j : Integer;
Begin
    If printseq then
    Begin
        Newline;
        For i := 1 to 7 do
            If (i = 2) and (l[2] = '+') then
                Write(lst,' ')
            Else
                Write(lst,l[i]);
        Write(lst,ch);
        For i := 8 to 10 do
            Write(lst,l[i]);
        Write(lst,' ');
        linelen := 12
    End
    Else 
        If lastch <> ' ' then
            Write(lst,' ');
    If linelen + length(l) - 10 < 80 then
        For i := 11 to length(l) do
        Begin
            linelen := linelen + 1;
            lastch := l[i];
            Write(lst,l[i])
        End
    Else
    Begin
        i := 80 - linelen;
        While l[i] <> ' ' do
            i := i - 1;
        If i < 10 then
            i := 10
        Else
            For j := 11 to i do
                Write(lst,l[j]);
        Newline;
        For j := 1 to 12 do
            Write(lst,' ');
        linelen := 12;
        If i + 1 < length(l) then
            For j := i + 1 to length(l) do
            Begin
                linelen := linelen + 1;
                lastch := l[j];
                Write(lst,l[j])
            End
    End;
    printseq := false;
    For i := 1 to length(l) do
        If l[i] = ']' then
            printseq := true
End;

Begin
    ClrScr;
    lineno := 0;
    linelen := 0;
    lastch := ' ';
    printseq := true;
    flag := false;
    Repeat
        Write('Name of conflated file to be printed: ');
        Readln(tempname);
        Add_ext(tempname,'cfl');
        Assign(infile,tempname);
        {$i-}
        Reset(infile);
        {$i+}
        tmp := ioresult;
        If tmp = 1 then
            Writeln('File not on disk.')
    Until tmp = 0;
    Reset(infile);
    While not eof (infile) do
    Begin
        Readln(infile,line);
        c := line[3];
        If c = ' ' then 
            outline(line,' ') 
        Else
            If c = 'C' then
            Begin
                line[3] := ' ';
                outline(line,' ')
            End
            Else
                If line[2] = '*' then
                Begin
                    If not flag then
                        Newline;
                    flag := true;
                    outline(line,'.')
                End
                Else
                Begin
                    flag := false;
                    Newline;
                    outline(line,'.')
                End
    End;
    Write(lst,chr(12));
    Close(infile)
End.

