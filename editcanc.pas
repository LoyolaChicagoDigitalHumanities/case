PROGRAM edit_cancels;
USES Crt;
{   This program removes the editing notations from an input file. These
    notations are documented fully in the CASE Users Guide. The syntax of
    the file is described by the syntax flow diagrams included in the
    documentation.
    Programmed at UC, UNSW at ADFA by Charles Layton August 1986.
    Translated into Turbo Pascal by Boyd Nation, MSU Computing Center. }

TYPE
    Symbol   = (slashsy, slash2sy, backslashsy, back2slashsy, lmistaksy,
        rmistaksy, langlesy, ranglesy, lbracksy, rbracksy, textsy, oversy,
        barsy, bar2sy, atsy, eofsy);  { Possible input symbols }
    Symset   = Set of Symbol;
    Char4    = Packed Array [1..4] of Char;
    Char140  = Packed Array [1..140] of Char;
    String3  = String[3];
    String80 = String[80];

VAR
    bar_level            : Integer;  { Depth of | nesting }
    bchno                : Integer;  { No of chars in the current insert 
                                       (between Bars)}
    buf                  : Text;
    bufcnt               : Integer;  { Number of characters buffered }
    buffered             : Boolean;
    buffering            : Boolean;  { Currently buffering input text ? }
    cancels_level        : Integer;  { Depth of / nesting }
    ch                   : Char;     { Current character }
    chno                 : Integer;  { Character number this line }
    current_bars         : Set of Symbol;
    errname              : String80;
    error                : Boolean;
    errorfile            : Text;
    expected_slash       : Symbol;   { Which of openning / or // we expect }
    flag                 : Boolean;
    inpfile              : Text;
    inphold              : Char;
    keeping              : Boolean;  { Currently keeping input text ? }
    line                 : Char140;  { Output line }
    lineno               : Integer;  { Input line number }
    maxinsert            : Integer;
    outfile              : Text;
    over                 : Char4;    { CONST the word 'over' }
    over_sym             : Boolean;  { IFF we are checking for the 'over'
                                       symbol }
    overwrite            : Char;
    snamlen              : Array [slashsy..eofsy] of Integer;
                                     { Length of above }
    spec_set             : Set of Char;
    sym                  : Symbol;   { Current symbol }
    symnam               : Array [slashsy..eofsy] of Char4;
                                     { Printing representation }
    symstno              : Integer;  { Where the last symbol starts }
    tempname             : String80;
    tmp                  : Integer;
    want_error           : Boolean;
    want_errorc          : Char;

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

FUNCTION getsym : symbol; forward;
{So initialise can be first}

PROCEDURE initialise;
Begin
    spec_set := ['[',']','/','\','|','<','>','+','-','@'];
    over := 'over';
    over_sym := false;
    buffered := false;
    error    := false;
    symnam[slashsy]     := '/   ';  snamlen[slashsy] := 1;
    symnam[slash2sy]    := '//  ';  snamlen[slash2sy] := 2;
    symnam[backslashsy] := '\   ';  snamlen[backslashsy] := 1;
    symnam[back2slashsy]:= '\\  ';  snamlen[back2slashsy] := 2;
    symnam[lmistaksy]   := '+-  ';  snamlen[lmistaksy] := 2;
    symnam[rmistaksy]   := '-+  ';  snamlen[rmistaksy] := 2;
    symnam[langlesy]    := '<<  ';  snamlen[langlesy] := 2;
    symnam[ranglesy]    := '>>  ';  snamlen[ranglesy] := 2;
    symnam[lbracksy]    := '[   ';  snamlen[lbracksy] := 1;
    symnam[rbracksy]    := ']   ';  snamlen[rbracksy] := 1;
    symnam[textsy]      := 'text';  snamlen[textsy] := 4;
    symnam[oversy]      := 'over';  snamlen[oversy] := 4;
    symnam[barsy]       := '|   ';  snamlen[barsy] := 1;
    symnam[bar2sy]      := '||  ';  snamlen[bar2sy] := 2;
    symnam[atsy]        := '@   ';  snamlen[barsy] := 1;
    symnam[eofsy]       := 'eof ';  snamlen[eofsy] := 3;
    lineno := 1;                       { First line of input }
    chno := 0;                         { Before first ch on this line }
    bchno := 0;                        { Place the current symbol starts }
    bar_level := 0;                    { No nested bars yet }
    cancels_level := 0;                { Nor in a cancelation }
    keeping := true;                   { Start of keeping the text }
    current_bars := [];
    buffering := false;
    expected_slash := slashsy;         { Cancel brackets start as / then
                                         alternate with // }
    Repeat
        Write('Filename for input file : ');
        Readln(tempname);
        Add_ext(tempname,'ms');
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
        Add_ext(tempname,'tex');
        Assign(outfile,tempname);
        {$i-}
        Reset(outfile);
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
    maxinsert := 1000;
    Write('Maximum length of insertions (<cr> for default = 1000) : ');
    Readln(maxinsert);
    Assign(buf,'temp.tmp');
    Reset(inpfile);
    Read(inpfile,inphold);
    Rewrite(outfile);
    sym := getsym                     { Initialise for the first symbol }
End;

PROCEDURE unexpected(sy : symbol);
Begin
    error := true;
    If want_error then
    Begin
        Writeln(errorfile,'Expected ',symnam[sy]:snamlen[sy],', found ',
        symnam[sym]:snamlen[sym],' at line ',lineno,' character ',bchno);
        Close(errorfile)
    End;
    Writeln('Expected ',symnam[sy]:snamlen[sy],', found ',
        symnam[sym]:snamlen[sym],' at line ',lineno,' character ',bchno);
    Close(inpfile);
    Close(outfile);
    Writeln('Press any key to continue.');
    ch := ReadKey();
    If buffered then
        Halt(1)
    Else
        Halt
End;

PROCEDURE backup;
{ Don't copy the last symbol to the output file }
Begin
    If chno > symstno then
        chno := symstno
End;

PROCEDURE flush;
{ Advanced line count and output this line if anything was kept}
VAR
    i : Integer;
Begin
    If buffering then 
        Writeln(buf) 
    Else
        If chno > 0 then
        Begin
            For i := 1 to chno do 
                If line[i] <> chr(13) then
                    Write(outfile, line[i]);
            Writeln(outfile);
            chno := 0;
            bchno := 0
        End;
        lineno := lineno + 1
End;

PROCEDURE stbuf;
{ Start buffering. Needed as [<x> over <y>] cannot be resolved from
  [<x>] with one character/one symbol lookahead }
Begin
    If buffering then 
    Begin
        error := true;
        If want_error then
            Writeln(errorfile,'? Losing buffer at line ', lineno:1);
        Writeln('? Losing buffer at line ', lineno:1)
    End;
    Rewrite(buf);
    buffering := true;
    buffered := true;
    bufcnt := 0
End;

PROCEDURE endbuf(save : Boolean; discard_cnt : Integer);
{ Stop buffering and write buffer to output if necessary }
VAR
    bufch                  : Char;
Begin
    buffering := false;
    If save then
    Begin
        Reset(buf);
        If sym <> oversy then
        Begin
            chno := chno + 1;
            line[chno] := ' '
        End;
        While not eof(buf) do
        Begin
            While not eoln(buf) do
            Begin
                Read(buf,bufch);
                bufcnt := bufcnt - 1;
                If bufcnt > discard_cnt then
                Begin
                    chno := chno + 1;
                    line[chno] := bufch
                End
            End;
            If eoln(buf) and not eof(buf) then 
                Flush;
            Readln(buf)
        End
    End
End;

FUNCTION getsym : symbol;
{ Return the next symbol from Input after processing | and || symbols }
VAR
    open : Boolean;
    sym  : Symbol;

FUNCTION getsy : symbol;
{ Get next symbol from input. No processing }
VAR
    i : Integer;

PROCEDURE getch;
{ Get next character.
  Eoln advances line count and flushes any kept characters to output. }
Begin
    If inphold = chr(13) {eoln(inpfile)} then
    Begin
        Flush;
        Readln(inpfile);
        Read(inpfile,inphold);
        ch := ' '
    End
    Else
    Begin
        ch := inphold;
        Read(inpfile,inphold);
        bchno := bchno + 1;
        If keeping then
        Begin
            If buffering then
            Begin
                bufcnt := bufcnt + 1;
                Write(buf, ch)
            End
            Else
            Begin
                chno := chno + 1;
                line[chno] := ch
            End
        End
    End
End;

PROCEDURE doblanks;
{ Just skip over blanks }
Begin
    While (inphold = ' ') and not eof(inpfile) do 
        Getch
End;

FUNCTION doublesy(c : Char; sy, syfail : symbol) : symbol;
{ Handle two character symbols }
Begin
    If inphold = c then
    Begin
        doublesy := sy;
        Getch
    End
    Else
        doublesy := syfail
End;

Begin {getsy}
    Doblanks;
    symstno := chno;
    If not eof(inpfile) then
    Begin
        If not ((inphold in spec_set) or ((inphold = 'o') and over_sym)) then
        Begin
            Repeat 
                Getch 
            Until (inphold in spec_set + [' ']) or eof(inpfile);
            getsy := textsy
        End
        Else
            If inphold = 'o' then
            Begin
                i := 1;
                Repeat
                    Getch;
                    i := i + 1
                Until (i = 4) or (inphold <> over[i]) or eof(inpfile);
                If (i = 4) and (inphold = over[i]) and not eof(inpfile) then
                Begin
                    i := 5;
                    Getch
                End;
                If (i = 5) and (inphold in (spec_set + [' '])) then 
                    getsy := oversy 
                Else
                Begin
                    getsy := textsy;
                    While not (inphold in spec_set + [' ']) and not 
                          eof(inpfile) do 
                        Getch
                End
            End 
            Else
            Begin
                Getch;
                Case ch Of
                    '[' : getsy := lbracksy;
                    ']' : getsy := rbracksy;
                    '@' : getsy := atsy;
                    '/' : getsy := doublesy('/', slash2sy,slashsy);
                    '\' : getsy := doublesy('\',back2slashsy,backslashsy);
                    '+' : getsy := doublesy('-',lmistaksy,textsy);
                    '-' : getsy := doublesy('+',rmistaksy,textsy);
                    '|' : getsy := doublesy('|', bar2sy, barsy);
                    '<' : getsy := doublesy('<', langlesy, textsy);
                    '>' : getsy := doublesy('>', ranglesy, textsy)
                End
            End
    End
    Else
        getsy := eofsy
End;  {getsy}

Begin {getsym}
    sym := getsy;
    While sym in [barsy, bar2sy, atsy] do
    Begin
        open := not(sym in current_bars);
        If open then
        Begin
            current_bars := current_bars + [sym];
            bar_level := bar_level + 1;
            If bar_level = 1 then 
                bchno := 0;
            If bar_level > 3 then 
            Begin
                error := true;
                If want_error then
                    Writeln(errorfile,
                            'Insertion nesting exceeds 3 at line ', lineno:1);
                Writeln('Insertion nesting exceeds 3 at line ', lineno:1)
            End
        End
        Else
        Begin
            current_bars := current_bars - [sym];
            bar_level := bar_level - 1
        End;
        Backup;         { Back up over the bar }
        sym := getsy
    End;
    If (bchno > maxinsert) and (bar_level > 0 ) then
    Begin
        error := true;
        If want_error then
            Writeln(errorfile,'Terminating extended insert at line ', lineno:1);
        Writeln('Terminating extended insert at line ', lineno:1);
        bar_level := 0
    End;
    getsym := sym
End; {getsym}

PROCEDURE expect(sy : Symbol; back : Boolean);
{ Should be an SY on input. Complain if not, eat if so }
Begin
    If sym = sy then
    Begin
        If back then 
            Backup;
        sym := getsym
    End 
    Else 
        Unexpected(sy)
End;

PROCEDURE eat_text;
{ Consume until a non-text symbol is encountered }
Begin
    While sym = textsy do
        sym := getsym
End;

PROCEDURE eat_everything;
{ Consume until a non-text symbol is encountered }
Begin
    While not (sym in [oversy, rbracksy]) do
        sym := getsym
End;

PROCEDURE squares;
{ Handle [text] and [text over text] constructs }
Begin
    over_sym := true;
    Stbuf;
    Expect(lbracksy, true);
    Eat_everything;
    If sym = oversy then
    Begin
        Endbuf(true, 4);
        keeping := false;
        Expect(oversy,false);
        Eat_everything;
        keeping := cancels_level = 0
    End 
    Else 
        Endbuf(false, 0);
    Expect(rbracksy, true);
    over_sym := false
End;

PROCEDURE sq_text;
{ Plain text AND [] constructs }
Begin
    While sym in [lbracksy, textsy] do
        If sym = textsy then
            Eat_text
        Else
            Squares
End;

PROCEDURE cancels;

FUNCTION other(sy : symbol) : symbol;
Begin
    If sy = slashsy then 
        other := slash2sy 
    Else 
        other := slashsy
End;

Begin   { cancels }
    cancels_level := cancels_level + 1;
    keeping := false;
    Expect(expected_slash, true);
    expected_slash := other(expected_slash);
    While sym in [slashsy, slash2sy, textsy, lbracksy] do
        If sym in [slashsy, slash2sy] then
            Cancels 
        Else
            Sq_text;
    cancels_level := cancels_level - 1;
    keeping := cancels_level = 0;
    If expected_slash = slashsy then
        Expect(back2slashsy, true)
    Else
        Expect(backslashsy, true);
    expected_slash := other(expected_slash)
End;

PROCEDURE main_file;
{ Use a recursive descent algorithm to parse the file }
Begin {main file}
    While sym <> eofsy do
    Begin
        flag := false;
        Case sym Of
            slashsy,
            slash2sy  : Begin
                            Cancels;
                            flag := true
                        End;
            lmistaksy : Begin
                            Expect(lmistaksy,true);
                            Sq_text;
                            flag := true;
                            Expect(rmistaksy, true)
                        End;
            langlesy  : Begin
                            keeping := false;
                            Expect(langlesy,true);
                            Sq_text;
                            keeping := true;
                            flag := true;
                            Expect(ranglesy, false)
                        End;
            lbracksy  : Begin
                            Squares;
                            flag := true
                        End;
            textsy    : Begin
                            Eat_text;
                            flag := true
                        End;
        End;
        If not flag then
        Begin
            error := true;
            If want_error then
            Begin
                Writeln(errorfile,'Found ', symnam[sym]:snamlen[sym],
                        ' unexpectedly at line ', lineno:1,
                        ' character ', bchno:1);
                Close(errorfile)
            End;
            Writeln('Found ', symnam[sym]:snamlen[sym],
                    ' unexpectedly at line ', lineno:1,
                    ' character ', bchno:1);
            Close(inpfile);
            Close(outfile);
            Writeln('Press any key to continue.');
            ch := ReadKey();
            If buffered then
                Halt(1)
            Else
                Halt
        End
    End
End;        

Begin
    ClrScr;
    Initialise;
    Main_file;
    Close(inpfile);
    Close(outfile);
    If want_error then
        Close(errorfile);
    If error then
    Begin
        Writeln('Press any key to continue.');
        ch := ReadKey()
    End;
    If buffered then
        Halt(1)
End.

