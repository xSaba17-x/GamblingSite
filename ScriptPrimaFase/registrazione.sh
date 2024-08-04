#!/bin/bash
cd ..
if [ ! -d "Server" ]; then
    mkdir "Server"
    chmod +777 "Server"
fi



if [ $# -eq 1 ]; then
    codice_fiscale=$1
else
    echo "Inserire solo il codice fiscale"
    exit 1
fi
cd "./bin"
sudo ./openssl dgst -sign "../player_$1/private_key.pem" -out "../player_$1/GP_sign_$1.bin" "../player_$1/GP_$1.txt"
sudo chmod 777 "../player_$1/GP_sign_$1.bin"
echo "Vuoi registrarti al sito? [S] [N]"
read response
if [ $response == "S" ] || [ $response == 's' ]; then
    cp "../player_$1/GP_$1.bin" "../Server"
    cp "../player_$1/GP_$1.txt" "../Server"
    cp "../player_$1/GP_sign_$1.bin" "../Server"
else
    echo "Arrivederci."
    exit 1
fi


#Come specificato la chiave del MDS è pubblica e qualsiasi utente può reperirla sul sito del MDS stesso.
#Controllo la firma sullo stesso file GP_$1.txt sia del MDS sia del player che lo ha inviato
./openssl dgst -verify "../MDS/public_key.pem" -signature "../Server/GP_$1.bin" "../Server/GP_$1.txt"
return1=$?
./openssl dgst -verify "../player_$1/public_key.pem" -signature "../Server/GP_sign_$1.bin" "../Server/GP_$1.txt"
return2=$?
if [ $return1 -eq 0 ] && [ $return2 -eq 0 ]; then
    echo "Il tuo GP è valido!"
else
    echo "Il tuo GP NON è valido!"
    exit 1
fi




echo "Vuoi inviarmi le tue informazioni, specificate dal garante della privacy, per registrarti al sito? [S] [N]"
read response
if [ $response == "S" ] || [ $response == 's' ]; then
#Dato che le informazioni necessarei all'autenticazione sono un sottoinsieme delle foglie del merkle tree, decido di passare, ove possibile,
#i path intermedi già calcolati, in modo da ridurre il carico computazionale del server per la ricostruzione della root.
    echo "$(grep "Nome:" "../player_$1/$1.txt")" >> ../player_$1/Informazioni_$1.txt
    echo "$(grep "Cognome:" "../player_$1/$1.txt")" >> ../player_$1/Informazioni_$1.txt
    echo "$(grep "Comune Di Nascita:" "../player_$1/auxiliary_GP.txt" | cut -d ':' -f2 | cut -d '-' -f1)" >> ../player_$1/Informazioni_$1.txt
    echo "$(grep "Data di Nascita:" "../player_$1/$1.txt")" >> ../player_$1/Informazioni_$1.txt
    echo "$(grep "Sesso:" "../player_$1/auxiliary_GP.txt" | cut -d ':' -f2 | cut -d '-' -f3 | sed 's/ //g')" >> ../player_$1/Informazioni_$1.txt
    echo "$(grep "Data di Scadenza:" "../player_$1/$1.txt")" >> ../player_$1/Informazioni_$1.txt
    echo "$(grep "Numero di Dosi:" "../player_$1/auxiliary_GP.txt" | cut -d ':' -f2 | cut -d '-' -f1)" >> ../player_$1/Informazioni_$1.txt
    echo "$(grep "Marca Vaccino:" "../player_$1/auxiliary_GP.txt" | cut -d ':' -f2 | cut -d '-' -f2 | sed 's/ //g')" >> ../player_$1/Informazioni_$1.txt
    echo "$(grep "Codice della Dose:" "../player_$1/auxiliary_GP.txt" | cut -d ':' -f2 | cut -d '-' -f3 | sed 's/ //g')" >> ../player_$1/Informazioni_$1.txt
    sudo ./openssl dgst -sign "../player_$1/private_key.pem" -out "../player_$1/Informazioni_$1.bin" "../player_$1/Informazioni_$1.txt"
    mv "../player_$1/Informazioni_$1.txt" "../Server"
    sudo mv "../player_$1/Informazioni_$1.bin" "../Server"
else
    echo "Arrivederci."
    exit 1
fi

#Controllo la firma del certificato contenente i path foglia-radice
./openssl dgst -verify "../player_$1/public_key.pem" -signature "../Server/Informazioni_$1.bin" "../Server/Informazioni_$1.txt"
return=$?
if [ $return -eq 0 ]; then
    echo "La firma del certificato ausiliario è stata verificata con successo"
else
    echo "La firma del certificato ausiliario NON è stata verificata con successo"
    rm "../Server/Informazioni_$1.txt"
    sudo rm "../Server/Informazioni_$1.bin"
    exit 1
fi

#Il server prepara le informazioni per calcolare il markle Tree
name=$(grep "Nome:" "../Server/Informazioni_$1.txt" | cut -d ':' -f2)
hased_name=$(echo -n $name | openssl dgst -sha256 | awk '{print $2}')
sed -i "s/$name/$hased_name/g" "../Server/Informazioni_$1.txt"

surname=$(grep "Cognome:" "../Server/Informazioni_$1.txt" | cut -d ':' -f2)
hased_surname=$(echo -n $surname | openssl dgst -sha256 | awk '{print $2}')
sed -i "s/$surname/$hased_surname/g" "../Server/Informazioni_$1.txt"

birth=$(grep "Data di Nascita:" "../Server/Informazioni_$1.txt" | cut -d ':' -f2)
hased_birth=$(echo -n $birth | openssl dgst -sha256 | awk '{print $2}')
sed -i "s/$birth/$hased_birth/g" "../Server/Informazioni_$1.txt"

deadline=$(grep "Data di Scadenza:" "../MDS/$1.txt" | cut -d ':' -f2)
hased_deadline=$(echo -n $deadline | openssl dgst -sha256 | awk '{print $2}')
sed -i "s/$deadline/$hased_deadline/g" "../Server/Informazioni_$1.txt"


#una volta che il server ha formattato i dati correttamente utilizza il suo codice per calcolarsi la root del merkle tree


rebuild_root(){
    #preparo le informazioni.
     
    info1=$(sed -n '1p' "../Server/Informazioni_$1.txt" | cut -d ':' -f2 | tr -d ' ')   
    info2=$(sed -n '2p' "../Server/Informazioni_$1.txt" | cut -d ':' -f2 | tr -d ' ')   
    info3=$(sed -n '3p' "../Server/Informazioni_$1.txt" | tr -d ' ')    
    info4=$(sed -n '4p' "../Server/Informazioni_$1.txt" | cut -d ':' -f2 | tr -d ' ')    
    info5=$(sed -n '5p' "../Server/Informazioni_$1.txt" | tr -d ' ')  
    info6=$(sed -n '6p' "../Server/Informazioni_$1.txt" | cut -d ':' -f2 | tr -d ' ')     
    info7=$(sed -n '7p' "../Server/Informazioni_$1.txt" | tr -d ' ')   
    info8=$(sed -n '8p' "../Server/Informazioni_$1.txt" | tr -d ' ')   
    info9=$(sed -n '9p' "../Server/Informazioni_$1.txt" | tr -d ' ')
    

    #ricostruisco il primo layer
    layer_1_1=$(echo -n "$info1$info2" | ./openssl dgst -sha256 | sed 's/SHA2-256(stdin)= //')
    layer_1_2=$(echo -n "$info3$info4" | ./openssl dgst -sha256 | sed 's/SHA2-256(stdin)= //')
    layer_1_3=$(echo -n "$info6$info7" | ./openssl dgst -sha256 | sed 's/SHA2-256(stdin)= //')

    #ricostruisco il secondo layer
    layer_2_1=$(echo -n "$layer_1_1$layer_1_2" | ./openssl dgst -sha256 | sed 's/SHA2-256(stdin)= //')
    layer_2_2=$(echo -n "$layer_1_3$info8" | ./openssl dgst -sha256 | sed 's/SHA2-256(stdin)= //')

    #ricostruisco il terzo layer
    layer_3_1=$(echo -n "$layer_2_1$info5" | ./openssl dgst -sha256 | sed 's/SHA2-256(stdin)= //')
    layer_3_2=$(echo -n "$layer_2_2$info9" | ./openssl dgst -sha256 | sed 's/SHA2-256(stdin)= //')

    #ricostruisco la root
    root=$(echo -n "$layer_3_1$layer_3_2" | ./openssl dgst -sha256 | sed 's/SHA2-256(stdin)= //')


}

rebuild_root $1
#adesso viene effettuata la procedura di verifica della root tree

value=$(grep "root:" "../Server/GP_$1.txt" | cut -d ':' -f2)
rm "../Server/GP_$1.txt"
rm "../Server/GP_$1.bin"
sudo rm "../Server/GP_sign_$1.bin"
if [ $root == $value ]; then
    echo "La root è stata verificata con successo. Benvenuto."
    pkey=$(cat "../player_$1/public_key.pem")
    extracted_key=$(echo "$pkey" | sed -n '/BEGIN PUBLIC KEY/,/END PUBLIC KEY/p' | sed '/BEGIN PUBLIC KEY/d; /END PUBLIC KEY/d')

    if [ -f "../Server/Database.enc" ]; then
        
        ./openssl pkeyutl -decrypt -inkey "../rsakey.pem" -in "../Server/Database.enc" -out "../Server/Database.txt"
        
        if grep -q "$extracted_key" "../Server/Database.txt"; then
            echo "Sei già registrato al sito!"
            rm "../Server/Informazioni_$1.txt"
            sudo rm "../Server/Informazioni_$1.bin"
            exit 1
        fi
    fi
    

    echo "----------------------------------------" >> "../Server/Database.txt"
    echo "pubkey:$extracted_key" >> "../Server/Database.txt"
    echo "CF:$1" >> "../Server/Database.txt"
    saldo=0
    echo "saldo:$saldo" >> "../Server/Database.txt"
    ban=0
    echo "ban:$ban" >> "../Server/Database.txt"
    ./openssl pkeyutl -encrypt -inkey "../rsapub.pem" -pubin -in "../Server/Database.txt" -out "../Server/Database.enc"
    rm "../Server/Informazioni_$1.txt"
    sudo rm "../Server/Informazioni_$1.bin"
    echo "Registrazione effettuata"
else
    echo "Non sono riuscito a verificare la root, riporva."
    rm "../Server/Informazioni_$1.txt"
    sudo rm "../Server/Informazioni_$1.bin"
    exit 1
fi