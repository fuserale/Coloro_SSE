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
         echo "${ALFABETO[$i]} assegno colore $colore"
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
  input_file=$Par2
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
  output_sat=output_sat.${temp}.sat
  output_dpll=output_dpll.${temp}
  maxclique=maxclique.${temp}.txt
  control=control.${temp}.txt
  cnf=${temp}.cnf
 

rm -f $input_file
rm -f $output_sat
rm -f $output_dpll
rm -f $cnf

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
  echo "File di input: $input_file creato .."
  ################################################################
	echo " > Fase 2 .."
	echo " > Scelta numero colori .. "
else
	echo "Salto fase di lettura.." 
	echo "Fase di decodifica del file $input_file .."
        [ ! -f $input_file ] && echo "file non trovato .."
        Nodi=$(grep '.i ' $input_file | sed -e 's/.*[.i] //' -e 's/\r//g')
        input_file=$(echo $input_file | sed -e 's/output/input/')
        temp=$(echo $input_file | sed -e 's/output_file.//' -e 's/.pla//')
        output_sat=output_sat.${temp}.dat
fi 

IFS=',' read -r -a ALFABETO <<< "$(echo {A..Z}{1..1000} | sed 's/ /,/g')"
NColori=$(grep '.type ' $input_file | sed -e 's/.*[.p] //' -e 's/\r//g')
EndRow=$(($(grep -c '' $input_file) - 1 ))
StartRow=$(( $EndRow - $(grep -n '.type ' $input_file | sed -e 's/:.*//' -e 's/\r//g') ))

################################################################
#trovo la clique più grande per capire il numero minimo di colori
./cl -x $read_file > $maxclique
NColori=$(head -c 8 $maxclique | sed 's/[^0-9]//g')
################################################################
START=$(date +%s.%N)

#flash per il ciclo di prova dei colori
finish=0
zero=1
#################################################################à
while [ $finish -le $zero ]; do
    echo "N. colori: $NColori"

    ./satcol $NColori $read_file > $cnf


    echo "File $cnf per il DPLL generato con $NColori-Colori."
    ##################################################################
    echo "Verifica colorabilità con DPLL"
    ./DPLL-SAT/dpll < $cnf > $control
    ##################################################################
    #controllo se la formula è stata soddisfatta con il numero di colori scelto, altrimenti aumento di uno e ricontrollo
    if grep -R "Formula" $control; then
        echo "formula not satisfable with $NColori colori"
        NColori=$(( NColori + 1 ))
        rm -f $control
        rm -f $cnf
        #control=control.${temp}.txt
    else 
        echo "formula satisfable with $NColori colori"
        finish=2
    fi
done
#############################################################à
END=$(date +%s.%N)
DIFF=$(echo "$END - $START" | bc)
echo "Total time of execution $DIFF"
# kill timeout monitor when terminating:
kill "$Timeout_monitor_pid"
exit
