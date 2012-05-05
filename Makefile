PASCAL=fpc

EXES=collate conflate editcanc isocanc menu precol preiso printcfl printvar prntcanc sortvar strip stripvar

all: $(EXES)

clean: 
	rm -f $(EXES) *.o *~

collate: collate
	$(PASCAL) collate.pas

conflate: conflate.pas
	$(PASCAL) conflate.pas

editcanc: editcanc.pas
	$(PASCAL) editcanc.pas

isocanc: isocanc.pas
	$(PASCAL) isocanc

menu: menu.pas
	$(PASCAL) menu.pas

precol: precol.pas
	$(PASCAL) precol.pas

preiso: preiso.pas
	$(PASCAL) preiso.pas

printcfl: printcfl.pas
	$(PASCAL) printcfl.pas

printvar: printvar.pas
	$(PASCAL) printvar.pas

prntcanc: prntcanc.pas
	$(PASCAL) prntcanc.pas

sortvar: sortvar.pas
	$(PASCAL) sortvar.pas

strip: strip.pas
	$(PASCAL) strip.pas

stripvar: stripvar.pas
	$(PASCAL) stripvar.pas

