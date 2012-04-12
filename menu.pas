PROGRAM Menu;
USES Crt;
VAR
    choice      : Char;
    num_choice  : Integer;

Begin
  ClrScr;
  Writeln;
  Writeln;
  Writeln;
  Writeln('                    Computer Assisted Scholarly Editing');
  Writeln('                                Version 2.1');
  Writeln;
  Writeln('           1)  Collate two files.');
  Writeln('           2)  Print output of collation.');
  Writeln('           3)  Conflate multiple collation outputs.');
  Writeln('           4)  Print output of conflation.');
  Writeln('           5)  Sort a variable file.');
  Writeln('           6)  Strip a variable file.');
  Writeln('           7)  Produce fair copy from a diplomatic transcription.');
  Writeln('           8)  Produce list of MS alterations.');
  Writeln('           9)  Print list of MS alterations.');
  Writeln('           0)  Exit from CASE.');
  Writeln;
  Writeln;
  Writeln('                       Press key and wait for questions.');
  Repeat
    choice := ReadKey()
  Until choice in ['0'..'9'];
  num_choice := ord(choice) - 48;
  Halt(num_choice)
End.

