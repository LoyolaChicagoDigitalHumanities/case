PROGRAM strip_vars;
USES Crt;

{   Takes a file with pickup words and outputs the variant part only
    with the sigla attached.
    UNSW at ADFA Comp. Centre Aug 1986 by a gaggle of programmers 
    Translated into Turbo by Boyd Nation, Computing Center, MSU. }

CONST
    maxwid      = 65;
    blanks20    = '                    ';
    blk_msg_len = 9;

TYPE
    States   = (skipping1,variant,skipping2,sigla,finished);
    Charset  = Set of Char;
    Char20   = Packed Array [1..20] of Char;
    Char132  = Packed Array [1..132] of Char;
    String3  = String[3];
    String80 = String[80];

VAR
    blk_msg                     : Char20;   { Replace blank lines with this }
    buf                         : Char;
    ch                          : Char;     { Latest input character }
    conf_file                   : Boolean;  { True if a conflation file }
    entrytype                   : Char;     { Manuscript or Compare }
    errname                     : String80;
    errorfile                   : Text;
    errors                      : Boolean;
    filetype                    : Char;
    inpfile                     : Text;
    labwid                      : Integer;  { Width of the 'label' field }
    lineno                      : Integer;  { Line number in file }
    outfile                     : Text;
    outlab                      : Char20;   { Output label field }
    outline                     : Char132;  { Output text part }
    outpos                      : Integer;  { Position on output line }
    overwrite                   : Char;
    startentry                  : Boolean;  { Expect the label field 
                                              to indicate a new record }
    state                       : States;   { What part of the text 
                                              is being scanned }
    tempname                    : String80;
    tmp                         : Integer;
    want_error                  : Boolean;
    want_errorc                 : Char;

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

PROCEDURE process_label; forward;
{ So initialise can be first }

PROCEDURE backup;
{ Backs up the output to stop output of last 3 characters. Needed as outch is
  called from getch. Should be called higher up so we have more discretion on
  when to outch. }
Begin
    outpos := outpos - 3;
    If outpos < 0 then
        outpos := 0
End;

PROCEDURE initialise;
Begin
    lineno := 1;
    outpos := 0;
    errors := false;
    Write('Type of file (''V'' for variants, ''C'' for conflation) : ');
    Readln(filetype);
    conf_file := (filetype = 'C') or (filetype = 'c');
    Repeat
        Write('Filename for input file : ');
        Readln(tempname);
        If conf_file then
            Add_ext(tempname,'cfl')
        Else
            Add_ext(tempname,'var');
        Assign(inpfile,tempname);
        {$i-}
        Reset(inpfile);
        {$i+}
        tmp := ioresult;
        If tmp = 1 then
            Writeln('File not on disk.')
    Until tmp = 0;
    Repeat
        Write('Filename for output file : ');
        Readln(tempname);
        If conf_file then
            Add_ext(tempname,'cfl')
        Else
            Add_ext(tempname,'var');
        Assign(outfile,tempname);
        {$i-}
        Reset(outfile);
        {$i+}
        tmp := ioresult;
        overwrite := 'n';
        If tmp = 0 then
        Begin
          Write('File already on disk.  Do you want to write over it (y/n)? ');
          Readln(overwrite)
        End
    Until (tmp = 1) or (overwrite = 'y') or (overwrite = 'Y');
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
        Until (tmp = 1) or (overwrite = 'y') or (overwrite = 'Y');
        Rewrite(errorfile)
    End;
    Reset(inpfile);
    Read(inpfile,buf);
    Rewrite(outfile);
    startentry := true;
    labwid := 8;
    blk_msg := '{omit}              ';
    entrytype := ' ';
    Process_label
End;

PROCEDURE error(msg : Char20);
Begin
    errors := true;
    If want_error then
        Writeln(errorfile,'Line ', lineno:1,' ',msg);
    Writeln('Line ', lineno:1,' ',msg)
End;

PROCEDURE outch(c : Char);
{ Write a character into the text part of output, break on a word boundary }
VAR
    i : Integer;
    j : Integer;
Begin
    outpos := outpos + 1;
    outline[outpos] := c;
    If outpos > maxwid then
    Begin
        i := outpos;
        While (outline[i] <> ' ') and (i > 1) do
            i := i - 1;
        If i = 1 then
            Error('Line with no blanks ');
        If conf_file then
            Write(outfile,'  ');
        For j := 1 to labwid do
            Write(outfile,outlab[j]);
        Write(outfile,'  ');
        For j := 1 to i do
            Write(outfile,outline[j]);
        Writeln(outfile);
        For j := i + 1 to outpos do
            outline [j - i] := outline[j];
        outlab := blanks20;
        outpos := outpos - i
    End
End;

PROCEDURE purgeout;
{ Write out all output after to finish up one complete entry }
VAR
    nonblank : Boolean;
    i        : Integer;
Begin
    If outpos > 0 then
    Begin
        For i := 1 to outpos do
            If outline[i] <> ' ' then
                nonblank := true;
        If nonblank then 
        Begin
            If conf_file then 
                Write(outfile,'  ');
            For i := 1 to labwid do
                Write(outfile,outlab[i]);
            Write(outfile,'  ');
            For i := 1 to outpos do
                Write(outfile,outline[i]);
            Writeln(outfile)
        End;
        outlab := blanks20;
        outpos := 0
    End
End;

PROCEDURE getch;
{ Get next character from the text (not label) field }
Begin
    If (state in [variant, sigla]) then
        Outch(buf);
    If eof(inpfile) then
        state := finished 
    Else
        If eoln(inpfile) then
        Begin
            ch := buf;
            Readln(inpfile);
            Read(inpfile,buf);
            If not eof(inpfile) then
            Begin
                lineno := lineno + 1;
                Process_label
            End
        End
        Else
        Begin
            ch := buf;
            Read(inpfile,buf)
        End
End;

PROCEDURE process_label;
{ Read in a label field }

FUNCTION getblanks : Integer;
{ Skip leading blanks. + symbol is insignificant }
VAR
    t : Integer;
Begin
    t := 0;
    While (buf in [' ','+']) and (t < labwid) and (not eof(inpfile)) do
    Begin 
        ch := buf;
        Read(inpfile,buf);
        t := t + 1
    End;
    getblanks := t
End;

PROCEDURE check (chset : Charset);
Begin
    If not (buf in chset) then
        Error('Badly formed line   ')
End;

PROCEDURE dolab(keep : Boolean);
{ Set up the label field for output by making the input label cute }
VAR
    i : Integer;
Begin
    If keep then
        outlab := blanks20;
    For i := 1 to labwid do
    Begin
        If keep then
            outlab[i] := buf;
        Read(inpfile,buf); 
    End
End;

PROCEDURE conf_lab;
{ Handle a conflation label field }
VAR
    t : Integer;
Begin
    t := getblanks;
    If t < labwid then
        If startentry then
        Begin
            Check(['C', 'M']);
            Purgeout;
            entrytype := buf;
            Dolab(true);
            startentry := false;
            state := skipping1
        End 
        Else
            Error('Incomplete entry    ');
    t := getblanks
End;

PROCEDURE var_lab;
{ Handle a variants label field }
Begin
    If startentry then
    Begin
        Check(['M','C']);
        Purgeout;
        If buf = entrytype then
            Dolab(false) 
        Else
        Begin
            entrytype := buf;
            startentry := false;
            Dolab(true)
        End
    End
    Else
        If buf <> entrytype then
            Error('Incomplete entry    ')
        Else
            Dolab(false)
End;

Begin           { process label }
    If not eof(inpfile) then
        If conf_file then
            Conf_lab 
        Else
            Var_lab
End;

PROCEDURE strip;

PROCEDURE find(c : Char; trailsp : Boolean);
TYPE
    finitestate = (needsp1,needbrack,needsp2,done);
VAR
    fstate : finitestate;
Begin
    fstate := needsp1;
    While fstate <> done do
    Begin
        Case fstate Of
            needsp1   : If buf = ' ' then
                            fstate := needbrack;
            needbrack : If buf = c then
                            If trailsp then
                                fstate := needsp2 
                            Else
                                fstate := done
                        Else
                            If buf <> ' ' then
                                fstate := needsp1;
            needsp2   : If buf = ' ' then
                            fstate := done
                        Else 
                            fstate := needsp1
        End;
        If state = finished then
            fstate := done 
        Else
            Getch
    End
End;

PROCEDURE out_sq;
{ Write out the start of the sigla }
VAR
    i : Integer;
Begin
    startentry := true;
    For i := 1 to 4 Do
        Outch(' ');
    Outch(']');
    While state = sigla do
        Getch;
    Purgeout
End;

PROCEDURE finishv;
{ Finish a variants entry. It does not have a terminating [ }
VAR
    ty : Char;
Begin
    startentry := true;
    ty := entrytype;
    While (ty = entrytype) And (state <> finished) Do
        Getch;
    Purgeout
End;

Begin                    { strip }
    state := skipping1;
    Find('(',true);
    If buf = ')' Then
    Begin
        Error('Empty variant       ');
        For outpos := 1 to blk_msg_len do
            outline[outpos] := blk_msg[outpos];
        outpos := blk_msg_len;
        Getch
    End
    Else
    Begin
        state := variant;
        find(')',true);
        Backup
    End;
    state := skipping2;
    If conf_file then
    Begin
        Find(']', false);
        state := sigla;
        out_sq
    End
    Else
        Finishv
End;

Begin
    Initialise;
    While not eof(inpfile) do
        Strip;
    Close(inpfile);
    Close(outfile);
    If want_error then
        Close(errorfile);
    If errors then
    Begin
        Writeln('Press any key to continue.');
        buf := ReadKey()
    End
End.
