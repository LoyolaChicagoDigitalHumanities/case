PROGRAM punct_print;
USES Crt, Printer;

{   Prints out a file with punctation only variants marked }

TYPE
    Char132   = Packed Array [1..132] of Char;
    String132 = Record
                    c   : Char132;
                    len : Integer;
                End;
    String3   = String[3];
    String80  = String[80];

VAR
    curr                        : String132;
    inpfile                     : Text;
    line                        : String132;
    lineno                      : Integer;
    newrec                      : Boolean;
    punct                       : Set of Char;
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

PROCEDURE read_file;
VAR
    i : Integer;
Begin
    curr := line;
    i := 0;
    If Not Eof(inpfile) Then
    Begin
        While Not Eoln(inpfile) Do
        Begin
            i := i + 1;
            Read (inpfile,line.c[i]);
            If line.c[i] <> ' ' Then
                line.len := i
        End;
        Readln(inpfile)
    End
    Else
    Begin
        line.c[1] := ' ';
        line.len := 0
    End
End;

PROCEDURE initialise;
Begin
    lineno := 0;
    punct := ['.',',','-','(',')',':',';','_','"','`','''','!','?','/'];
    Repeat
        Write('Name of variants file to be printed: ');
        Readln(tempname);
        Add_ext(tempname,'var');
        Assign(inpfile,tempname);
        {$i-}
        Reset(inpfile);
        {$i+}
        tmp := ioresult;
        If tmp = 1 then
            Writeln('File not on disk.')
    Until tmp = 0;
    Reset(inpfile);
    read_file;
    read_file
End;

PROCEDURE process;
VAR
    current    : String132;
    p          : Char;
    s          : String132;

PROCEDURE outrec(str : string132);
VAR
    i : Integer;
Begin
    Write(lst,str.c[1],' ');
    For i := 3 to 5 Do
        Write(lst,str.c[i]);
    Write(lst,'.');
    For i := 6 to 8 Do
        Write(lst,str.c[i]);
    Write(lst,'  ');
    For i := 9 to str.len Do
        Write(lst,str.c[i]);
    Newline
End;

FUNCTION punct_only : Boolean;
VAR
    i    : Integer;
    same : Boolean;
    t    : String132;

PROCEDURE depunct;
VAR
    i   : Integer;
    off : Integer;
Begin
    off := 0;
    For i := 12 to current.len Do
        If current.c[i] In punct Then
            off := off + 1
        Else
            current.c[i - off] := current.c[i];
    current.len := current.len - off
End;

Begin {punct_only}
    current := s;
    depunct;
    t := current;
    current := curr;
    depunct;
    same := True;
    i := 13;
    While same And (current.c[i] <> ']') And (i<current.len) Do
    Begin
        same := same And (current.c[i]=t.c[i]);
        i := i + 1
    End;
    punct_only := same
End;

PROCEDURE copy_over(ch:Char);
Begin
    While curr.c[1]=ch Do
    Begin
        Write(lst,'  ');
        newrec := false;
        outrec(curr);
        read_file
    End;
    If curr.c[1]='M' Then
    Begin
         Newline;
         newrec := true
    End
End;

Begin {process}
    Write(lst,'  ');
    outrec(curr);
    If line.c[1] = 'C' Then
    Begin
        s := curr;
        read_file;
        If (line.c[1]='M') Or Eof(inpfile) Then
        Begin
            If punct_only Then
                p := '#' 
            Else
                p := ' ';
            Write(lst,p,' ');
            outrec(curr);
            Newline;
            read_file
        End
        Else
        Begin
            Write(lst,'  ');
            outrec(curr);
            read_file;
            copy_over('C')
        End
    End
    Else
    Begin
        read_file;
        copy_over('M');
        copy_over('C')
    End
End;

PROCEDURE fudge;
Begin
     If newrec Then
         process
End;

Begin
    initialise;
    While not eof(inpfile) do
        process;
    fudge;
    Write(lst,chr(12));
    Close(inpfile)
End.

