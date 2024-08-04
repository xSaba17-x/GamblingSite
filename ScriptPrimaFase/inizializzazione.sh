#!/bin/bash
cd ..
if [ $# -eq 1 ]; then
    codice_fiscale=$1
else
    echo "Inserire solo il codice fiscale"
    exit 1
fi

dir="player_$codice_fiscale"
if [ ! -d $dir ]; then
    mkdir $dir
fi

if [ ! -d "Server" ]; then
    mkdir Server
fi

if [ ! -f "blockchain.txt" ]; then
    touch "blockchain.txt"
fi

cd ./bin

#Sia i player (client compreso) che il MDS devono avere la propria chiave pubblica e privata. Come specificato usiamo le curve ellittiche

#genero le chiavi per il player



if [ -f "../player_$1/public_key.pem" ] && [ -f "../player_$1/private_key.pem" ]; then
    echo "il player $codice_fiscale ha già la sua PK e SK."
else
    sudo ./openssl ecparam -name prime256v1 -out ../player_$1/prime256v1.pem 
    sudo ./openssl genpkey -paramfile ../player_$1/prime256v1.pem -out ../player_$1/private_key.pem #genero la chiave privata 
    sudo ./openssl pkey -in ../player_$1/private_key.pem -pubout -out ../player_$1/public_key.pem #genero la chiave pubblica  
   
fi

#Se è la prima volta che viene effettuata una richiesta anche il MDS genera le sue chiavi

if [ -f "../MDS/public_key.pem" ] && [ -f "../MDS/private_key.pem" ]; then
    echo "il MDS ha già le sue chiavi"
else
    sudo ./openssl ecparam -name prime256v1 -out "../MDS/prime256v1.pem" 
    sudo ./openssl genpkey -paramfile "../MDS/prime256v1.pem" -out "../MDS/private_key.pem" #genero la chiave privata 
    sudo ./openssl pkey -in "../MDS/private_key.pem" -pubout -out "../MDS/public_key.pem" #genero la chiave pubblica
fi

if [ -f "../Server/public_key.pem" ] && [ -f "../Server/private_key.pem" ]; then
    echo "il Server ha già la sua PK e SK."
else
    sudo ./openssl ecparam -name prime256v1 -out ../Server/prime256v1.pem 
    sudo ./openssl genpkey -paramfile ../Server/prime256v1.pem -out ../Server/private_key.pem #genero la chiave privata 
    sudo ./openssl pkey -in ../Server/private_key.pem -pubout -out ../Server/public_key.pem #genero la chiave pubblica  
   
fi
