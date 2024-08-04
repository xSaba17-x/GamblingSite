#!/bin/bash
cd ..
#Il codice fiscale del richiedente deve essere passato come argomento
if [ $# -eq 1 ]; then
    codice_fiscale=$1
else
    echo "Inserire solo il codice fiscale"
    exit 1
fi

#sudo chmod -R +777 "../MDS/"
cd ./bin
#Dato che il MDS è una CA root conosce già tutte le informazioni necessarie per poter rilasciare il green pass. (Per implementare questa
#funzionalità è stato inserito un file codice_fiscale.txt con tutte le informazioni del richiedente)




Create_GP(){
    #echo "$(grep "Nome:" "../MDS/$1.txt" | cut -d ':' -f2 | ./openssl dgst -sha256 | sed 's/SHA2-256(stdin)= /Nome:/')" > ../MDS/GP_$1.txt
    cp "../MDS/$1.txt" "../MDS/GP_$1.txt"

    value=$(grep "Nome:" "../MDS/$1.txt" | cut -d ':' -f2)
    hash_value=$(echo -n $value | openssl dgst -sha256 | awk '{print $2}')
    sed -i "1s/$value/$hash_value/g" "../MDS/GP_$1.txt"
    

    value=$(grep "Cognome:" "../MDS/$1.txt" | cut -d ':' -f2)
    hash_value=$(echo -n $value | openssl dgst -sha256 | awk '{print $2}')
    sed -i "2s/$value/$hash_value/g" "../MDS/GP_$1.txt"

    value=$(grep "Comune Di Nascita:" "../MDS/$1.txt" | cut -d ':' -f2)
    hash_value=$(echo -n $value | openssl dgst -sha256 | awk '{print $2}')
    sed -i "3s/$value/$hash_value/g" "../MDS/GP_$1.txt"
    
    value=$(grep "Data di Nascita:" "../MDS/$1.txt" | cut -d ':' -f2)
    hash_value=$(echo -n "$value" | openssl dgst -sha256 | awk '{print $2}')
    sed -i "4s/$value/$hash_value/g" "../MDS/GP_$1.txt"

    value=$(grep "Sesso:" "../MDS/$1.txt" | cut -d ':' -f2)
    hash_value=$(echo -n $value | openssl dgst -sha256 | awk '{print $2}')
    sed -i "5s/$value/$hash_value/g" "../MDS/GP_$1.txt"

    value=$(grep "Codice Fiscale:" "../MDS/$1.txt" | cut -d ':' -f2)
    hash_value=$(echo -n $value | openssl dgst -sha256 | awk '{print $2}')
    sed -i "6s/$value/$hash_value/g" "../MDS/GP_$1.txt"

    value=$(grep "Data Ultima Vaccinazione:" "../MDS/$1.txt" | cut -d ':' -f2)
    hash_value=$(echo -n $value | openssl dgst -sha256 | awk '{print $2}')
    sed -i "7s/$value/$hash_value/g" "../MDS/GP_$1.txt"
   
    value=$(grep "Data Ultima Positivita:" "../MDS/$1.txt" | cut -d ':' -f2)
    hash_value=$(echo -n $value | openssl dgst -sha256 | awk '{print $2}')
    sed -i "8s/$value/$hash_value/g" "../MDS/GP_$1.txt"
    
    value=$(grep "Data di Scadenza:" "../MDS/$1.txt" | cut -d ':' -f2)
    hash_value=$(echo -n $value | openssl dgst -sha256 | awk '{print $2}')
    sed -i "9s/$value/$hash_value/g" "../MDS/GP_$1.txt"

    value=$(grep "Numero di Dosi:" "../MDS/$1.txt" | cut -d ':' -f2)
    hash_value=$(echo -n $value | openssl dgst -sha256 | awk '{print $2}')
    sed -i "10s/$value/$hash_value/g" "../MDS/GP_$1.txt"

    value=$(grep "Marca Vaccino:" "../MDS/$1.txt" | cut -d ':' -f2)
    hash_value=$(echo -n $value | openssl dgst -sha256 | awk '{print $2}')
    sed -i "11s/$value/$hash_value/g" "../MDS/GP_$1.txt"

    value=$(grep "Produttore Vaccino:" "../MDS/$1.txt" | cut -d ':' -f2)
    hash_value=$(echo -n $value | openssl dgst -sha256 | awk '{print $2}')
    sed -i "12s/$value/$hash_value/g" "../MDS/GP_$1.txt"

    value=$(grep "Codice della Dose:" "../MDS/$1.txt" | cut -d ':' -f2)
    hash_value=$(echo -n $value | openssl dgst -sha256 | awk '{print $2}')
    sed -i "13s/$value/$hash_value/g" "../MDS/GP_$1.txt"

    value=$(grep "Ente Responsabile:" "../MDS/$1.txt" | cut -d ':' -f2)
    hash_value=$(echo -n $name | openssl dgst -sha256 | awk '{print $2}')
    sed -i "14s/$value/$hash_value/g" "../MDS/GP_$1.txt"
    echo "" >> "../MDS/GP_$1.txt"
}


Create_GP $1


MarkleTree(){
    nodes=$(wc -l < "../MDS/GP_$1.txt")
    tot_nodes=$nodes
    line=1
    iter=0
    
    cp "../MDS/GP_$1.txt" "../MDS/temp$iter.txt"
    cp "../MDS/GP_$1.txt" "../MDS/auxiliary_GP.txt"

    nodes=$(wc -l < "../MDS/temp$iter.txt")
    #costruisco il mekrle tree
    while [ $nodes -gt 1 ]; do
        
        while [ ! $nodes -le 0 ]; do
            firstValue=$(head -n $line "../MDS/temp$iter.txt" | tail -n 1 | cut -d ':' -f2)
            line=$(( $line+1 ))
            secondValue=$(head -n $line "../MDS/temp$iter.txt" | tail -n 1 | cut -d ':' -f2)
            line=$(( $line+1 ))
            nodes=$(( $nodes-2 ))

            value=$(echo -n "$firstValue$secondValue" | ./openssl dgst -sha256 | sed 's/SHA2-256(stdin)= //')
            iter=$(($iter+1))
            echo ":$value" >> "../MDS/temp$iter.txt"
            iter=$(($iter-1))
        done
        iter=$(($iter+1))
        nodes=$(wc -l < "../MDS/temp$iter.txt")       
        temp=$(echo "($nodes + $tot_nodes -1) / $nodes " | bc) #eventualmente approssimo il risultato della divisione per eccesso
        cont=1
        line=1
        # Aggrego le informazioni nel certificato ausiliario in base a come vengono unite le varie foglie nei vari livelli del merkletree
        if [ ! $nodes -eq 1 ]; then
            for ((i=1; i<=$tot_nodes; i++)); do
                hash=$(head -n $line "../MDS/temp$iter.txt" | tail -n 1 | cut -d ':' -f2)
                if [ $cont -eq $temp ]; then
                    line=$(( $line + 1))
                    cont=0
                fi
                cont=$(( $cont +1 ))
                sed -i "$i s/$/ - $hash/" "../MDS/auxiliary_GP.txt"
            done
        else #l'ultimo risultato sarebbe la root e la inserisco nel GP 2.0
            hash=$(head -n $line "../MDS/temp$iter.txt" | tail -n 1 | cut -d ':' -f2)
            echo "root:$hash" >> "../MDS/GP_$1.txt"
        fi
        if [ ! $(( $nodes % 2 )) -eq 0 ] && [ ! $nodes -eq 1 ]; then
            echo ":NULL" >> "../MDS/temp$iter.txt"
            tot_nodes=$(( $tot_nodes + 1))
        fi
        rm "../MDS/temp$(( $iter - 1)).txt"
        line=1
    done

    rm "../MDS/temp$(( $iter )).txt"
}

MarkleTree $1


#Per simulare l'invio del green pass dal MDS al player sposto i vari file tra le cartelle.
#Ricordo che prima di inviare il certificato la MDS deve firmarlo usano la sua chiave segreta.

release_GP(){

   sudo ./openssl dgst -sign "../MDS/private_key.pem" -out "../MDS/GP_$1.bin" "../MDS/GP_$1.txt"
   #sudo ./openssl dgst -verify "../MDS/public_key.pem" -signature "../MDS/GP_$1.bin" "../MDS/GP_$1.txt"  
   sudo ./openssl dgst -sign "../MDS/private_key.pem" -out "../MDS/auxiliary_GP.bin" "../MDS/auxiliary_GP.txt"
   mv "../MDS/auxiliary_GP.bin" "../player_$1"
   mv "../MDS/auxiliary_GP.txt" "../player_$1"
   mv "../MDS/GP_$1.bin" "../player_$1"
   mv "../MDS/GP_$1.txt" "../player_$1"
   cp "../MDS/$1.txt" "../player_$1"
   
}

if [ ! -f "../player_$1/GP_$1.bin" ]; then
    release_GP $1
fi


