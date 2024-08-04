#!/bin/bash
cd "ScriptPrimaFase"

sudo chmod +777 richiesta.sh inizializzazione.sh registrazione.sh accesso.sh ../gioco.sh

if [ ! -f "../MDS/$1.txt" ]; then
    echo "Il Ministero della Salute non ha informazioni sul tuo conto. Effettua il vaccino prima di richiedere un Green Pass 2.0."
    exit 1
fi

./inizializzazione.sh $1

if [ ! -f "../player_$1/GP_$1.txt" ] && [ ! -f "./player_$1/GP_$1.bin" ] && [ ! -f "../player_$1/auxiliary_GP.txt" ] && [ ! -f "../player_$1/auxiliary_GP.bin" ]; then
    ./richiesta.sh $1
    echo "Richiesta effettuata. Hai ricevuto il tuo Green Pass 2.0."

fi

./registrazione.sh $1

./accesso.sh $1




