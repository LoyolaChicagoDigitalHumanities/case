PROGRAM Strip;
USES Crt;

TYPE
    String80    = String[80];
    String3     = String[3];
VAR
    cchr            : Char;
    compare         : Text;
    errname         : String80;
    error           : Boolean;
    errorfile       : Text;
    i               : Integer;
    illegal         : Set of Char;
    line            : String[255];
    lineno          : Integer;
    master          : Text;
    outcom          : Text;
    outmst          : Text;
    overwrite       : Char;
    temp            : Integer;
    tempcomp        : String80;
    tempmast        : String80;
    want_error      : Boolean;
    want_errorc     : Char;

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

PROCEDURE Initialize;
Begin
    Repeat
        Write('Master file name: ');
        Readln(tempmast);
        Add_ext(tempmast,'tex');
        Assign(master,tempmast);
        {$I-}
        Reset(master);
        {$I+}
        temp := ioresult;
        If temp = 1 then
            Writeln('File not on disk')
    Until temp = 0;
    Repeat
        Write('Comparison file name: ');
        Readln(tempcomp);
        Add_ext(tempcomp,'tex');
        Assign(compare,tempcomp);
        {$I-}
        Reset(compare);
        {I+}
        temp := ioresult;
        If temp = 1 then
            Writeln('File not on disk')
    Until temp = 0;
    Write('Do you want an error file created (y/n)? ');
    Readln(want_errorc);
    want_error := not((want_errorc = 'n') or (want_errorc = 'N'));
    If want_error then
    Begin
        overwrite := 'n';
        Repeat
            Write('Filename for error file : ');
            Readln(errname);
            Add_ext(errname,'err');
            Assign(errorfile,errname);
            {$i-}
            Reset(errorfile);
            {$i+}
            temp := ioresult;
            Writeln('IOResult ', temp);
            If temp = 0 then
            Begin
                Write('File already on disk.  Do you want to write over it? ');
                Readln(overwrite)
            End
        Until (temp <> 0) or (overwrite = 'y') or (overwrite = 'Y');
        Rewrite(errorfile)
    End;
    Reset(master);
    Reset(compare);
    Assign(outmst,'master.tmp');
    Assign(outcom,'compare.tmp');
    Rewrite(outmst);
    Rewrite(outcom);
    error   := false;
    lineno  := 0;
    illegal := [];
    For i := 1 to 9 do
        illegal := illegal + [chr(i)];
    illegal := illegal + [chr(11), chr(12)];
    For i := 14 to 31 do
        illegal := illegal + [chr(i)];
    {
    For i := 128 to 255 do
        illegal := illegal + [chr(i)]
    }
End;

PROCEDURE Strip_controls;
VAR
    i           : Integer;
    j           : Integer;
Begin
    For i := 1 to length(line) do
        If line[i] in illegal then
        Begin
            error := true;
            If want_error then
            Begin
                Write(errorfile,'Line ',lineno,' of ');
                If cchr = '@' then
                    Write(errorfile,'master')
                Else
                    Write(errorfile,'compare');
                Writeln(errorfile,' - Illegal character')
            End;
            Write('Line ',lineno,' of ');
            If cchr = '@' then
                Write('master')
            Else
                Write('compare');
            Writeln(' - Illegal character');
            line[i] := cchr
        End
End;

FUNCTION empty_line : Boolean;
VAR
    flag        : Boolean;
    i           : Integer;
Begin
    flag := true;
    If length(line) > 0 then
        For i := 1 to length(line) do
            If line[i] <> ' ' then
                flag := false;
    empty_line := flag
End;

Begin  { main program }
    Initialize;
    cchr := '@';
    While not eof(master) do
    Begin
        Readln(master,line);
        lineno := lineno + 1;
        Strip_controls;
        If not empty_line then
            Writeln(outmst,line)
        Else
        Begin
            error := true;
            If want_error then
                Writeln(errorfile,'Line ',lineno,' of master - Blank line');
            Writeln('Line ',lineno,' of master - Blank line');
            Writeln(outmst,'***  Empty line  ***')
        End
    End;
    cchr := '#';
    lineno := 0;
    While not eof(compare) do
    Begin
        Readln(compare,line);
        lineno := lineno + 1;
        Strip_controls;
        If not empty_line then
            Writeln(outcom,line)
        Else
        Begin
            error := true;
            If want_error then
                Writeln(errorfile,'Line ',lineno,' of compare - Blank line');
            Writeln('Line ',lineno,' of compare - Blank line');
            Writeln(outcom,'***  Empty line  ***')
        End
    End;
    Close(master);
    Close(compare);
    Close(outmst);
    Close(outcom);
    If want_error then
        Close(errorfile);
    If error then
    Begin
        Writeln('Hit any key to continue.');
        cchr := ReadKey()
    End
End.

