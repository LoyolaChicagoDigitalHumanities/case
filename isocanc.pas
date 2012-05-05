PROGRAM isolate_cancels;
USES Crt;

CONST
    max_word_len = 32;
    max_word_arr = 33;  {max_word_len + 1}
    max_words = 200;
    blank7 = '       ';
    blankw =  '                                 ';

TYPE
    Char2     = Packed Array [1..2] of Char;
    Char7     = Packed Array [1..7] of Char;
    Charw     = Packed Array [1..max_word_arr] of Char;
    Char100   = Packed Array [1..100] of Char;
    Stringish = Record
                    word   : charw;
                    length : 0..max_word_arr
                End;
    String3   = String[3];
    String80  = String[80];

VAR
    brack_set                   : Set of Char;
    bufch                       : Char;
    curr                        : Stringish;
    curr_seq                    : Char7;
    dummy                       : Char;
    errname                     : String80;
    error                       : Boolean;
    errorfile                   : Text;
    inpfile                     : Text;
    nesting                     : Packed Array [1..6] of Char2;
    non_nesting                 : Packed Array [1..4,false..true] of Char2;
    non_paired                  : Packed Array [1..1] of Char2;
    nul                         : Char;
    outfile                     : Text;
    out_seq                     : Char7;
    overwrite                   : Char;
    prev                        : Stringish;
    prev_seq                    : Char7;
    tempname                    : String80;
    tmp                         : Integer;
    want_error                  : Boolean;
    want_errorc                 : Char;
    words                       : Packed Array [1..max_words] of Stringish;

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

PROCEDURE get(Var ch:Char);
Begin
    ch := bufch;
    Read(inpfile,bufch)
End;

PROCEDURE getln;
Begin
    Readln(inpfile);
    Read(inpfile,bufch)
End;

PROCEDURE skipblanks;
VAR
    temp     : Char;
Begin
    While not eoln(inpfile) and not eof(inpfile) and (bufch = ' ') do
        Get(temp)
End;

PROCEDURE newline;
VAR
    i : Integer;
Begin
    While eoln(inpfile) and not eof(inpfile) do
    Begin
        Getln;
        skipblanks
    End;
    If not eof(inpfile) then
    Begin
        For i := 1 to 7 do
            If not eof(inpfile) then
                Get(curr_seq[i]);
        skipblanks
    End
End;

PROCEDURE get_word;
VAR
    i : Integer;
Begin           { Get word }
    skipblanks;
    If eoln(inpfile) and not eof(inpfile) then
    Begin
        newline;
        skipblanks
    End;
    i := 1;
    prev := curr;
    prev_seq := curr_seq;
    curr.word := blankw;
    If not eof(inpfile) then
        While (bufch <> ' ') and not eof(inpfile) and not eoln(inpfile) do
        Begin
            If (i <= max_word_len) then
                If not eof(inpfile) then
                    Get(curr.word[i])
            Else
                If not eof(inpfile) then
                    Get(dummy);
            i := i + 1;
            If i = max_word_len + 1 then
            Begin
                If want_error then
                    Writeln(errorfile,'Word too long - truncated',curr.word);
                Writeln('Word too long - truncated',curr.word);
                error := true
            End
        End;
        If eoln(inpfile) and (i < max_word_len) then
        Begin
            curr.word[i] := bufch;
            i := i + 1
        End;
        If i > max_word_len then
            curr.length := max_word_len
        Else
            curr.length := i - 1
End;

PROCEDURE initialise;
VAR
    i : Integer;
Begin
    non_paired[1] := '@ ';
    non_nesting[1,false] := '||';    non_nesting[1,true] := '||';
    non_nesting[2,false] := '+-';    non_nesting[2,true] := '-+';
    non_nesting[3,false] := '| ';    non_nesting[3,true] := '| ';
    non_nesting[4,false] := '<<';    non_nesting[4,true] := '>>';
    nesting[1] := '//';
    nesting[2] := '/ ';
    nesting[3] := '[ ';
    nesting[4] :='\\';
    nesting[5] :='\ ';
    nesting[6] :='] ';
    brack_set := [non_paired[1][1]];
    For i := 1 to 3 do
        brack_set := brack_set + [nesting[i][1]];
    For i := 1 to 4 do
        brack_set := brack_set + [non_nesting[i,false][1]];
    nul := chr(0);
    curr.word := blankw;
    curr.length := 1;
    curr_seq := blank7;
    error := false;
    Assign(inpfile,'outmst.tmp');
    Repeat
        Write('Filename for output file : ');
        Readln(tempname);
        Add_ext(tempname,'iso');
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
    Read(inpfile,bufch);
    Rewrite(outfile);
    newline
End;

FUNCTION index(w : Stringish; c : Char) : Integer;
VAR
    i : Integer;
Begin
    i := 1;
    While (w.word[i] <> c) and (i < w.length) do
        i := i + 1;
    If w.word[i] = c then
        index := i
    Else
        index := 0
End;

FUNCTION two_index(w : Stringish; c2 : char2) : Integer;
VAR
    i : Integer;
Begin
    i := 1;
    While ((w.word[i]<>c2[1]) or (w.word[i+1]<>c2[2])) and (i < w.length-1) do
        i := i + 1;
    If (w.word[i] = c2[1]) and (w.word[i+1] = c2[2]) then 
        two_index := i
    Else
        two_index := 0    
End;

FUNCTION word_has_lbrack : Boolean;
VAR
    i   : Integer;
    has : Boolean;
Begin
    has := false;
    For i := 1 to curr.length do
        has := has or (curr.word[i] in brack_set);
    word_has_lbrack := has
End;

PROCEDURE scan_text;
VAR
    all_zero            : Boolean;
    i                   : Integer;
    in_non_nesting      : Packed Array [1..4] of Boolean;
    j                   : Integer;
    nesting_count       : Packed Array [1..3] of Integer;
    not_done            : Boolean;
    nwords              : Integer;

PROCEDURE dump_table;
VAR
    i     : Integer;
    j     : Integer;
    pos   : Integer;
Begin
    Write(outfile,out_seq,' ');
    pos := 8;
    For i := 1 to nwords do
    Begin
        pos := pos + words[i].length + 1;
        If pos > 80 then
        Begin
            pos := words[i].length + 8 + 1;
            Writeln(outfile);
            Write(outfile,out_seq,' ')
        End;
        For j := 1 to words[i].length do
            Write(outfile,words[i].word[j]);
        Write(outfile,' ')
    End;
    Writeln(outfile)
End;

PROCEDURE remove_non_paired;
Begin
    j := index (curr, non_paired[1][1]);
    While j > 0 do
    Begin
        curr.word[j] := nul;
        j := index (curr, non_paired[1][1])
    End
End;

PROCEDURE remov_non_nesting;
VAR
    i   : Integer;
    j   : Integer;
Begin
    For i := 1 to 4 do
    Begin
        If non_nesting[i,in_non_nesting[i]][2] = ' ' then
            j := index(curr,non_nesting[i,in_non_nesting[i]][1])
        Else
            j := two_index(curr,non_nesting[i,in_non_nesting[i]]);
        While j > 0 do
        Begin
            curr.word[j] := nul;
            If non_nesting[i,in_non_nesting[i]][2] <> ' ' then 
                curr.word[j + 1] := nul;
            in_non_nesting[i] := not in_non_nesting[i];
            If non_nesting[i,in_non_nesting[i]][2] = ' ' then
                j := index(curr,non_nesting[i,in_non_nesting[i]][1])
            Else
                j := two_index (curr, non_nesting[i,in_non_nesting[i]])
        End
    End
End;

PROCEDURE remove_nesting;
VAR
    i   : Integer;
    j   : Integer;
Begin
    For i := 1 to 6 do
    Begin
        If nesting[i][2] = ' ' then
            j := index(curr,nesting[i][1])
        Else
            j := two_index (curr, nesting[i]);
        While j > 0 do
        Begin
            curr.word[j] := nul;
            If nesting[i][2] <> ' ' then
                curr.word[j + 1] := nul;
            If i > 3 Then
                nesting_count[i - 3] := nesting_count[i - 3] - 1
            Else
                nesting_count[i] := nesting_count[i] + 1;
            If nesting [i][2] = ' ' then
                j := index(curr,nesting[i][1])
            Else
                j := two_index (curr, nesting[i])
        End
    End
End;

Begin           { scan text }
    words[1] := prev;
    nwords := 1;
    out_seq := prev_seq;
    For i := 1 to 3 do
        nesting_count[i] := 0;
    For i := 1 to 4 do
        in_non_nesting[i] := false;
    not_done := true;
    While ((nwords < max_words) and not_done) do
    Begin
        nwords := nwords + 1;
        words[nwords] := curr;
        curr.length := curr.length + 1;     { Could be too big }
        curr.word[curr.length] := ' ';
        remove_non_paired;
        remov_non_nesting;
        remove_nesting;
        all_zero := true;
        For i := 1 to 4 do
            all_zero := all_zero and not in_non_nesting[i];
        For i := 1 to 3 do
            all_zero := all_zero and (nesting_count[i] = 0);
        not_done := not all_zero;
        If all_zero then
        Begin
            get_word;
            If not word_has_lbrack then
            Begin
                nwords := nwords + 1;
                words[nwords] := curr;
                dump_table
            End
            Else 
                not_done := true
        End
        Else
            get_word
    End;
    If not_done then
    Begin
        dump_table;
        error := true;
        If want_error then
            Writeln(errorfile,'Maxwords exceeded at ', curr_seq);
        Writeln('Maxwords exceeded at ', curr_seq)
    End
    Else
        If (eof(inpfile)) and (nwords > 0) then
            dump_table
End;

Begin           {main program}
    initialise;
    While not eof(inpfile) do
    Begin
        If word_has_lbrack then
            scan_text;
        get_word
    End;
    Close(inpfile);
    Close(outfile);
    If want_error then
        Close(errorfile);
    If error then
    Begin
        Writeln('Press any key to continue.');
        bufch := ReadKey()
    End
End.

