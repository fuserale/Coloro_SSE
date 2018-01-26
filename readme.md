Progetto di Software per Sistemi Embedded

Studente: Fuser Alessandro VR405372

Docente: Tiziano Villa

Argomento: Colorazione Grafi tramite espresso e SAT

Istruzioni sui programmi scritti:

I programmi sono stati scritti usando il linguaggio bash di Linux e sono:
	- color_espresso.sh --> usa la versione euristica di espresso
	- color_espresso_exact.sh --> usa la versione esatta di espresso
	- color_minisat.sh --> usa il solutore MINISAT
	- 2color_minisat.sh --> usa il solutore MINISAT e ricerca dei colori binaria
	- color_dpll.sh --> usa il solutore DPLL e ricerca dei colori con clique
	

La cartella File contiene tutti i grafi nel formato DIMACS usati per il progetto

La cartella Documenti contiene la relazione del progetto e il file delle tempistiche

La cartella DPLL-SAT contiene il codice e l'eseguibile per DPLL

La cartella satcol-master contiene il codice per la traduzione da grafo a cnf (c++)
#################################################################
Esempio di lancio di programma espresso da terminale:

	bash ./color_espresso.sh [-m File/myciel3.col]

Se l'opzione -m non viene usata, è richiesto d mettere il nome del file in input
NB: mettere sempre "File/" prima del nome del file

Il programma genera 
	- il file input_file_myciel3.pla (input per espresso), 
	- output_file_myciel3.pla (output minimizzato di espresso),
	- espresso_color_myciel3.dat (assegnazione dei colori)

A video viene segnalato invece il tempo totale di esecuzione
##################################################################
Esempio di lancio di programma minisat da terminale:

	bash ./color_minisat.sh [-m File/myciel3.col]
	
	oppure
	
	bash ./2color_minisat.sh [-m File/myciel3.col]
	

Se l'opzione -m non viene usata, è richiesto d mettere il nome del file in input
NB: mettere sempre "File/" prima del nome del file

Il programma genera:
	- il file maxclique.myciel3.txt (massima dimensione della clique, tramite l'eseguibile cl)
	- il file myciel3.cnf (traduzione del grafo in CNF)
	- il file control.myciel.3.txt (assegnazione variabili per CNF)
##################################################################

All'interno di ogni programma viene, all'inizio, impostato un timer, per cui è necessario settare un massimo del tempo di esecuzione possibile
