#!/usr/bin/bash

################################################
#timeout in caso di esecuzioni troppo lunghe
Timeout=1800 # 30 minutes
function timeout_monitor() {
   sleep "$Timeout"
   kill "$1"
}
# start the timeout monitor in 
# background and pass the PID:
timeout_monitor "$$" &
Timeout_monitor_pid=$!
################################################
Param=$(echo "$#")
fase=1
[ $Param -ge 1 ] && Par1=$1
[ $Param -ge 2 ] && Par2=$2

set -a Vedge
set -a Vtemp


#inizio definizione funzioni
function assegna_colori(){
	IFS=',' read -r -a prova <<< "$1"
    
    for (( i=0; i<${#prova[@]}; i++ )); do 
      if [ "${prova[$i]}"  == "-" ]; then
        touch $espresso_color
         echo "${ALFABETO[$i]} assegno colore $colore" >> $espresso_color
         awk -v indx="$(( $i + 1 ))" 'BEGIN { FS = ","; OFS=FS }; { $indx="0"; print}' ${file_temp} > ${file_temp1}
         cp $file_temp1 ${file_temp}
      fi 
    done
    colore=$(( $colore + 1 ))  
    rm -f ${file_temp1}
}

genera_nodi(){
  echo "Nodi del grafo generati: "
  while [[ $i -le $1 ]]; do 
   echo -n "$i "
   (( i = i + 1 ))
   j=1
      while [[ $j -le $1 ]]; do
	Medge[$i, $j]=0
        (( j = j + 1 ))
      done
  done

  echo
  genera_OnSet
}

genera_OnSet(){
  i=1
  while [[ $i -le $Nodi ]]; do
   j=1 
    while [[ $j -le $Nodi ]]; do
      [ $i -eq $j ] && echo -n "-" >> $input_file || echo -n "0" >> $input_file
      (( j = j + 1 ))
    done
   echo " 1" >> $input_file
   (( i = i + 1 ))
  done   
}

add_Offset(){
  i=1
  while [[ $i -le $Nodi ]]; do
   if [ $1 -eq $i ] || [ $2 -eq $i ]; then
     echo -n "1" >> $input_file
   else
     echo -n "-" >> $input_file
   fi 
   (( i = i + 1 ))
  done
  echo " 0" >> $input_file
}

#fine funzioni

#lettura linea di comando
if [ $Param -eq 2 ] && [ "$Par1" == "-f" ]; then
  fase=2
  out_file=$Par2
fi

#inizio
echo "###########################################################"
echo "#    Individuare il numero minimo per colorare un grafo   #"
echo "###########################################################"



if [ $fase -eq 1 ]; then
	echo " > Fase 1 .."
	echo " > Inserire il nome del file da leggere "
  #lettura linea di comando
  if [ $Param -eq 2 ] && [ "$Par1" == "-m" ]; then
    read_file=$Par2
  else
    #esempio di nome file da scrivere: File/1-FullIns_3.col
    read read_file
  fi

  filename=$(basename "$read_file")
  extension="${filename##*.}"
  filename="${filename%.*}"

  #definizione dei vari file usati
  temp=$filename
  input_file=input_file.${temp}.pla
  file_temp=temp.${temp}.dat
  file_temp1=temp1.${temp}.dat
  out_file=output_file.${temp}.pla
  output_sat=output_sat.${temp}.dat
  espresso_color=espresso_color.${temp}.dat

  #############################################################
	#Lettura grafo e scrittura in formato PLA
	while IFS=' ' read -r p1 p2 p3 p4
	do
    if [ $p1 = "p" ]
      then echo "Numero Nodi $p3 : Numero collegamenti $p4"
      Nodi=$p3
      #echo "Numero Nodi $Nodi"
      touch $input_file
        echo -e ".i $Nodi\n.o 1\n.type fr" > $input_file
      genera_nodi $Nodi
    fi
    if [ $p1 = "e" ]; 
      then #echo "Arco tra Nodo $p2 : Nodo $p3"
      add_Offset $p2 $p3
      #read $p2 $p3
    fi
	done < $read_file

	echo ".end" >> $input_file
  echo "File di input per espresso: $input_file creato .."
  #############################################################
	echo " > Minimizzazione mediante espresso .."
  START=$(date +%s.%N)
	./espresso $input_file > $out_file
  echo "File di output generato da espresso: $out_file .."
  ############################################################
	echo " > Fase 2 .."
	echo " > Decodifica output .. "
else
	echo "Salto fase di lettura.." 
	echo "Fase di decodifica del file $out_file .."
        [ ! -f $out_file ] && echo "file non trovato .."
        Nodi=$(grep '.i ' $out_file | sed -e 's/.*[.i] //' -e 's/\r//g')
        input_file=$(echo $out_file | sed -e 's/output/input/')
        temp=$(echo $out_file | sed -e 's/output_file.//' -e 's/.pla//')
        output_sat=output_sat.${temp}.dat
fi 

IFS=',' read -r -a ALFABETO <<< "$(echo {A..Z}{1..1000} | sed 's/ /,/g')"
NColori=$(grep '.p ' $out_file | sed -e 's/.*[.p] //' -e 's/\r//g')
EndRow=$(($(grep -c '' $out_file) - 1 ))
StartRow=$(( $EndRow - $(grep -n '.p ' $out_file | sed -e 's/:.*//' -e 's/\r//g') ))

#Il numero colori è pari, a questo punto, al numero di vertici rimasti dopo la minimizzazione
echo "N. colori: $NColori"

head -$EndRow $out_file | tail -$StartRow | cut -c 1-"$Nodi" > $file_temp1
sed 's/./&,/g' $file_temp1 | cut -c 1-$(( $Nodi + $Nodi - 1)) > $file_temp
rm -f ${file_temp1}

echo "file temporaneo: $file_temp"

colore=1
indrow=1
len=$(grep -c '' $file_temp)

rm -f $espresso_color

#colorazione dei vertici
while [ $indrow -le $len ]; do
   line=$(sed -n "${indrow}p" ${file_temp})
   assegna_colori $line 
   indrow=$(( indrow + 1 ))
done

echo "rimozione file temporaneo $file_temp"
rm -f $file_temp
END=$(date +%s.%N)
DIFF=$(echo "$END - $START" | bc)
echo "Total time of execution $DIFF"
# kill timeout monitor when terminating:
kill "$Timeout_monitor_pid"
exit
###################################################################################
# echo " > Fase 3 .."
# echo " >  Riscrittura dell'input in CNF per verificare la $NColori-Colorabilità "

# [ -f $output_sat ] && echo "Rimuovo file $output_sat già esistente .."
# touch $output_sat

# indrow=1

# #PLOGIC1 := Per tutti i vertici creo la possiblità che abbia un colore da 1:k (Ncolori)
# while [ $indrow -le $Nodi ]; do
#         indcol=1
#         echo -n "{" >> $output_sat
# 	while [ $indcol -le $NColori ]; do
#            if [ $indcol -lt $NColori ]; then
#                echo -n "${ALFABETO[$(($indrow - 1))]}$indcol, " >> $output_sat 
#            else 
#                echo -n "${ALFABETO[$(($indrow - 1))]}$indcol}" >> $output_sat
#            fi

# 	   indcol=$(( indcol + 1 ))
# 	done
#    indrow=$(( indrow + 1 ))
#    echo -n ", " >> $output_sat
# done

# #PLOGIC2 := Per tutti i vertici nego la possibilità che lo stesso vertice abbia più di un colore 
# indrow=1
# while [ $indrow -le $Nodi ]; do
#         indcol=1
# 	while [ $indcol -le $NColori ]; do
#                 indz=$((indcol+1))
# 		while [ $indz -le $NColori ]; do
# 		   echo -n "{-${ALFABETO[$(($indrow - 1))]}$indcol, -${ALFABETO[$(($indrow - 1))]}$indz}, " >> $output_sat 

# 		   indz=$(( indz + 1 ))
# 		done
# 	   indcol=$(( indcol + 1 ))
# 	done
#    indrow=$(( indrow + 1 ))
# done

# #PLOGIC3 := In funzione degli archi mi assicuro che i vertici toccati da due archi non abbiano mai lo stesso colore  
# awk '{ if ($2 == 0 ) print $1 }' $input_file > $file_temp

# indrow=0
# while read line; do {
#     trovato=0   
#     indcol=1
#     while [ $indcol -le $Nodi ]; do
# 	estrai=$(echo $line | cut -c $indcol-$indcol )

# 	if [ "$estrai" != "-" ]; then
#           if [ $trovato -eq 0 ]; then
#  	    VAR_A="${ALFABETO[$(($indcol - 1))]}" 
#             trovato=1
#           else
#  	    VAR_B="${ALFABETO[$(($indcol - 1))]}"  
#           fi
#         fi
#         indcol=$(( indcol + 1 ))
#      done

#      for (( i = 1; i <=${NColori}; i++ )); do
#         echo -n "{-$VAR_A$i, -$VAR_B$i}, " >> $output_sat
#      done
	          
# } done < $file_temp 

# rm -f $file_temp

# #rimuovo l'ultima virgola e l'ultimo spazio
# echo "Rimuovo l'ultimo carattere"
# sed 's/.\{2\}$//' $output_sat > $file_temp
# mv $file_temp $output_sat

# echo "File $output_sat per il DPLL generato con $NColori-Colori."
# exit
###################################################################