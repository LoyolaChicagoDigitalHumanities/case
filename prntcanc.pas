PROGRAM print_cancel;
USES Crt, Printer;

CONST
    impossible_seq = 'xxxxxxx';

TYPE
    Char7    = Packed Array [1..7] of Char;
    Char130  = Packed Array [1..130] of Char;
    String3  = String[3];
    String80 = String[80];

VAR
    dummy                       : Char;
    infile                      : Text;
    line7                       : Char7;
    lineno                      : Integer;
    previous_seq                : Char7;
    rest_of_line                : Char130;
    rlen                        : Integer;
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
    lineno := lineno + 1;
    If lineno > 58 then
    Begin
        Write(lst,chr(12));
        lineno := 0
    End
End;

PROCEDURE initialise;
Begin
    Repeat
        Write('Name of file to be printed: ');
        Readln(tempname);
        Add_ext(tempname,'iso');
        Assign(infile,tempname);
        {$i-}
        Reset(infile);
        {$i+}
        tmp := ioresult;
        If tmp = 1 then
            Writeln('File not on disk.')
    Until tmp = 0;
    Reset(infile);
    lineno := 0;
    previous_seq := impossible_seq
End;

PROCEDURE getline;
VAR
    i : Integer;
Begin
    For i := 1 to 7 Do
        Read(infile,line7[i]);
    i := 0; 
    Read(infile,dummy);
    While not eoln(infile) do
    Begin
        i := i + 1;
        Read(infile,rest_of_line[i])
    End;
    Readln(infile);
    rlen := i
End;

PROCEDURE process_line;
VAR
    i         : Integer;
Begin
    getline;
    If previous_seq <> line7 then
    Begin
        Newline;
        previous_seq := line7
    End;
    Write(lst,previous_seq,' ');
    For i := 1 to rlen do
        Write(lst,rest_of_line[i]);
    Newline
End;

Begin
    ClrScr;
    initialise;
    While not eof(infile) do
        process_line;
    Write(lst,chr(12));
    Close(infile)
End.

