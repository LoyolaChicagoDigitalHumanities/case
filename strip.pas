PROGRAM Strip;
USES Crt, getopts;


TYPE
    String80    = String[80];
    String3     = String[3];

VAR
    cchr            : Char;
    compare         : Text;
    compareopt      : String80;
    erroropt      : String80;
    errname         : String80;
    error           : Boolean;
    errorfile       : Text;
    i               : Integer;
    illegal         : Set of Char;
    line            : String[255];
    lineno          : Integer;
    master          : Text;
    masteropt       : String80;
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

PROCEDURE ParseCommandLine;
var
    c               : char;
    optionindex     : Longint;
    theopts         : array[1..3] of TOption;

begin
  masteropt := '';
  compareopt := '';
  erroropt := '';
  with theopts[1] do 
   begin
    name:='master';
    has_arg:=1;
    flag:=nil;
    value:='m';
  end;
  with theopts[2] do 
   begin
    name:='compare';
    has_arg:=1;
    flag:=nil;
    value:='c';
  end;
  with theopts[3] do 
   begin
    name:='errors';
    has_arg:=1;
    flag:=nil;
    value:='e';
  end;
  c:=#0;
  repeat
    c:=getlongopts('m:c:e:012',@theopts[1],optionindex);
    case c of
      '1','2','3','4','5','6','7','8','9' :
        begin
        writeln ('Got optind : ',c)
        end;
      #0 : begin
           write ('Long option : ',theopts[optionindex].name);
           if theopts[optionindex].has_arg>0 then 
             writeln (' With value  : ',optarg)
           else
             writeln
           end; 
      'a' : writeln ('Option a.');
      'b' : writeln ('Option b.');
      'c' : Begin
                compareopt := optarg;
            End;
      'm' : Begin
                masteropt := optarg;
            End;
      'e' : Begin
                erroropt := optarg;
            End;
      'd' : writeln ('Option d : ', optarg);
      '?',':' : writeln ('Error with opt : ',optopt); 
   end; { case }
 until c=endofoptions;
 if optind<=paramcount then
    begin
    write ('Non options : '); 
    while optind<=paramcount do 
      begin
      write (paramstr(optind),' ');
      inc(optind)
      end;
    writeln
    end
end;

PROCEDURE Initialize;
Begin
    If masteropt = '' then
    Begin
        Writeln('--master filename missing');
        Halt(1);
    End;

    If compareopt = '' then
    Begin
        Writeln('--compare filename missing');
        Halt(1);
    End;

    tempmast := masteropt;
    Assign(master,tempmast);
    {$I-}
    Reset(master);
    {$I+}
    temp := ioresult;
    If temp = 1 then
       Begin
       Writeln('File not on disk');
       Halt(1)
    End;

    tempcomp := compareopt;
    Assign(compare,tempcomp);
    {$I-}
    Reset(compare);
    {I+}
    temp := ioresult;
    If temp = 1 then
    Begin
       Writeln('File not on disk');
       Halt(2);           
    End;

    want_error := erroropt <> '';

    If want_error then
    Begin
       errname := erroropt;
       Assign(errorfile,errname);
       {$i-}
       Reset(errorfile);
       {$i+}
       temp := ioresult;
       If temp = 0 then
          Begin
             Writeln('File ',erroropt,' already on disk. Please delete it first.');
             Halt(3)
          End;
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
    ParseCommandLine;
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
