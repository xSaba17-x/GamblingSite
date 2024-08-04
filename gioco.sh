#!/bin/bash


###################################################################################
#############################  FASE INIZIALE  #####################################
###################################################################################


#Controllo che da shell venga passato almeno un player per poter giocare
if [ $# -eq 0 ]; then

    echo "Devi inserire dei giocatori!"
    exit 1

fi

# Percorso del Server
main_folder="./Server"

lista_utenti=()
cd "./bin"
./openssl pkeyutl -decrypt -inkey ../rsakey.pem -in "../Server/Database.enc" -out "../Server/Database.txt"
#Controllo che i giocatori effettivamente esistano
for name in "$@"; do

    # Cerca il file con il codice fiscale specificato
    if grep -q "$name" "../Server/Database.txt"; then

        lista_utenti+=($name)

    else

        echo "Non è stata trovato il giocatore: $name"
        exit 1

    fi

done

rm "../Server/Database.txt"


######################################################################################
##############################  FASE DI GIOCO  #######################################
######################################################################################




#Aggiungo il Server come giocatore
lista_utenti+=("Server")



#Ogni giocatore, incluso il Server, crea il proprio contributo
for item in "${lista_utenti[@]}"; do

    if [ $item != "Server" ]; then

        dd if=/dev/urandom bs=1 count=10 status=none > ../player_$item/Contributo_player_$item.bin
        

    else
        dd if=/dev/urandom bs=1 count=10 status=none > ../Server/Contributo_$item.bin
        

    fi

done



#Ogni giocatore, compreso il Server, hasha il proprio contributo e salva l'istante di tempo in cui lo crea
for item in "${lista_utenti[@]}"; do

    if [ $item != "Server" ]; then

        ./openssl dgst -sha256 -binary -out ../player_$item/Contributo_player_sha_$item.bin ../player_$item/Contributo_player_$item.bin
        date +%s > ../player_$item/timestamp_$item.txt

    else

        ./openssl dgst -sha256 -binary -out ../Server/Contributo_sha_$item.bin ../Server/Contributo_$item.bin
        date +%s > ../$item/timestamp_$item.txt
    
    fi

done

#Do i permessi a tutti i file nelle rispettive cartelle per evitare problemi di "Permission denied" durante la lettura
for user in "${lista_utenti[@]}"; do
    if [ $user != "Server" ]; then
        sudo chmod -R 777 "../player_$user"
    else
        sudo chmod -R 777 "../$user"
    fi
done

#Ogni giocatore, compreso il Server, applica la firma digitale sul proprio contributo hashato insieme al timestamp e lo invia al server
for item in "${lista_utenti[@]}"; do

    if [ $item == "Server" ]; then

        ./openssl dgst -sign "../Server/private_key.pem" -out "../Server/signature_$item.bin" -binary <(cat ../$item/Contributo_sha_$item.bin ../$item/timestamp_$item.txt)
        chmod +777 "../Server/signature_$item.bin"

    else 

        ./openssl dgst -sign "../player_$item/private_key.pem" -out "../player_$item/signature_player_$item.bin" -binary <(cat ../player_$item/Contributo_player_sha_$item.bin ../player_$item/timestamp_$item.txt)
        chmod +777 "../player_$item/signature_player_$item.bin"
        cp "../player_$item/signature_player_$item.bin" "../Server"
    
    fi

done



#Arrivati a questo punto solo il Server invia tutti i contributi a tutti i giocatori
for item in "${lista_utenti[@]}"; do

    if  [ $item != "Server" ]; then

        for player in "${lista_utenti[@]}"; do

            if [ $player != "Server" ] && [ $player != "$item" ]; then

                cp "../Server/signature_player_$item.bin" "../player_$player"
            
            fi
        done

    fi

done

for item in "${lista_utenti[@]}"; do

    if [ $item != "Server" ]; then
        cp "../Server/signature_Server.bin" "../player_$item"
    fi

done


#####################################################################################################
#####################################  FASE DI CONVALIDA  ###########################################
#####################################################################################################


#Il seguente ciclo fa si che ogni player invii il proprio contributo al server e viceversa il
#server invia il proprio contributo a tutti i player
for item in "${lista_utenti[@]}"; do

    if [ $item != "Server" ]; then
        ./openssl dgst -sign "../player_$item/private_key.pem" -out "../Server/signature_contributo_player_$item.bin" "../player_$item/Contributo_player_$item.bin"

        #Il giocatore "item" invia al server il suo contributo con la sua pk
        cp "../player_$item/public_key.pem" "../Server/public_key_$item.pem"
        cp "../player_$item/Contributo_player_$item.bin" "../Server"
        cp "../player_$item/Contributo_player_sha_$item.bin" "../Server"
        cp "../player_$item/timestamp_$item.txt" "../Server"
        
        ./openssl dgst -sign "../Server/private_key.pem" -out "../player_$item/signature_contributo_Server.bin" "../Server/Contributo_Server.bin"
        #Il server invia al player "item" il suo contributo con la sua pk
        cp "../Server/public_key.pem" "../player_$item/public_key_Server.pem"
        cp "../Server/Contributo_Server.bin" "../player_$item"
        cp "../Server/Contributo_sha_Server.bin" "../player_$item"
        cp "../Server/timestamp_Server.txt" "../player_$item"

    fi

done



#Ora che il server ha tutti i contributi, deve inviarli a tutti i giocatori, ovviamente escludendo
#il suo contributo che ha già inviato e il contributo che ha creato il player stesso
for item in "${lista_utenti[@]}"; do

    for player in "${lista_utenti[@]}"; do


        if [ $item != $player ] && [ $player != "Server" ] && [ $item != "Server" ]; then
            ./openssl dgst -sign "../player_$player/private_key.pem" -out "../player_$item/signature_contributo_player_$player.bin" "../player_$player/Contributo_player_$player.bin"
            cp "../Server/public_key_$player.pem" "../player_$item"
            cp "../Server/Contributo_player_$player.bin" "../player_$item"
            cp "../Server/Contributo_player_sha_$player.bin" "../player_$item"
            cp "../Server/timestamp_$player.txt" "../player_$item"

        fi
        
    done

done

#Adesso verifico le firme di tutti i contributi in chiaro che sono stati inviati precedentemete

for item in "${lista_utenti[@]}"; do
    for player in "${lista_utenti[@]}"; do
        if [ $player != $item ]; then
            if [ $item != 'Server' ]; then
                if [ $player != 'Server' ]; then
                    ./openssl dgst -verify "../player_$player/public_key.pem" -signature "../player_$item/signature_contributo_player_$player.bin" "../player_$item/Contributo_player_$player.bin"
                else
                    ./openssl dgst -verify "../$player/public_key.pem" -signature "../player_$item/signature_contributo_$player.bin" "../player_$item/Contributo_$player.bin"

                fi
            else
                ./openssl dgst -verify "../player_$player/public_key.pem" -signature "../$item/signature_contributo_player_$player.bin" "../$item/Contributo_player_$player.bin"

            fi
        fi
    done
done


#Ogni giocatore, compreso il Server, verifica tramite la firma che il contributo appartenga al player
#effettivo e successivamente ottiene il contributo iniziale del player stesso per calcolare il risultato
for item in "${lista_utenti[@]}"; do

    for player in "${lista_utenti[@]}"; do

        if [ $player != $item ]; then
            
            if [ $item != "Server" ]; then
                
                if [ $player != "Server" ]; then
                    ./openssl dgst -sha256 -verify ../player_$player/public_key_$item.pem -signature ../player_$player/signature_player_$item.bin <(cat ../player_$player/Contributo_player_sha_$item.bin ../player_$player/timestamp_$item.txt)
                else
                    ./openssl dgst -sha256 -verify ../$player/public_key_$item.pem -signature ../$player/signature_player_$item.bin <(cat ../$player/Contributo_player_sha_$item.bin ../$player/timestamp_$item.txt)
                fi

                if [ $? -ne 0 ]; then

                    echo "Sono il player $item e durante la verifica della FIRMA del player $player qualcosa non è andato a buon fine!"
                    exit 1

                fi

                if [ $player != "Server" ]; then
                    ./openssl dgst -sha256 -binary -out ../player_$player/Verifica_Contributo_player_sha_$item.bin ../player_$player/Contributo_player_$item.bin
                    cmp ../player_$player/Verifica_Contributo_player_sha_$item.bin ../player_$player/Contributo_player_sha_$item.bin
                else
                    ./openssl dgst -sha256 -binary -out ../$player/Verifica_Contributo_sha_$item.bin ../$player/Contributo_player_$item.bin
                    cmp ../$player/Verifica_Contributo_sha_$item.bin ../$player/Contributo_player_sha_$item.bin
                fi
                
                if [ $? -ne 0 ]; then

                    echo "Sono il player $item e durante la verifica del CONTRIBUTO del player $player qualcosa non è andato a buon fine!"
                    exit 1

                fi
                

            else
                
                ./openssl dgst -sha256 -verify ../player_$player/public_key_Server.pem -signature ../player_$player/signature_Server.bin <(cat ../player_$player/Contributo_sha_Server.bin ../player_$player/timestamp_Server.txt)
                if [ $? -ne 0 ]; then

                    echo "Sono il player $item e durante la verifica della FIRMA del player $player qualcosa non è andato a buon fine!"
                    exit 1

                fi

                ./openssl dgst -sha256 -binary -out ../player_$player/Verifica_Contributo_sha_Server.bin ../player_$player/Contributo_Server.bin
                cmp ../player_$player/Verifica_Contributo_sha_Server.bin ../player_$player/Contributo_sha_Server.bin

                if [ $? -ne 0 ]; then

                    echo "Sono il player $item e durante la verifica del CONTRIBUTO del player $player qualcosa non è andato a buon fine!"
                    exit 1

                fi
            
            fi

        fi

    done

done




#Ogni giocatore calcola il risultato finale
for item in "${lista_utenti[@]}"; do

    if [  $item != "Server"  ]; then

        file1="../player_$item/Contributo_player_$item.bin"
        xxd -p "$file1" > hex1.txt
        primo=$(cat "./hex1.txt") 

    else

        file1="../$item/Contributo_$item.bin"
        xxd -p "$file1" > hex1.txt
        primo=$(cat "./hex1.txt") 

    fi

    for player in "${lista_utenti[@]}"; do

        if [ $item != $player ]; then
            
            if [ $item != "Server" ]; then

                if [ $player != "Server" ]; then
                    file2="../player_$item/Contributo_player_$player.bin"
                else
                    file2="../player_$item/Contributo_$player.bin"
                fi

                xxd -p "$file2" > hex2.txt 
                secondo=$(cat "./hex2.txt") 
                primo=$(python3 -c "print(hex(int('$primo', 16) ^ int('$secondo', 16))[2:])")
            
            else

                file2="../$item/Contributo_player_$player.bin"
                xxd -p "$file2" > hex2.txt
                secondo=$(cat "./hex2.txt") 
                primo=$(python3 -c "print(hex(int('$primo', 16) ^ int('$secondo', 16))[2:])")           

            fi
        fi

    done

    echo "Sono $item e il risultato è: $primo"

done



file_da_mantenere=("public_key.pem" "private_key.pem" "prime256v1.pem" "Database.enc")

for item in "${lista_utenti[@]}"; do
    file_da_mantenere+=("$item.txt")
    if [ $item != "Server" ]; then
    cd "../player_$item"
        for file in *; do
        # Verifica se il file è presente nell'elenco dei file da mantenere
            if [[ ! " ${file_da_mantenere[@]} " =~ " ${file} " ]]; then
                # Elimina il file
                    rm "$file"
            fi
        done
    else
        cd "../$item"
        for file in *; do
        # Verifica se il file è presente nell'elenco dei file da mantenere
            if [[ ! " ${file_da_mantenere[@]} " =~ " ${file} " ]]; then
                # Elimina il file
                    rm "$file"
            fi
        done
    fi
done