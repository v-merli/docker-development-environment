[-] Controllare phpharbor stats disk --cleanup l'operazione di cleanup l'avevamo già aggiunta in phpharbor cleanup. Mi sembra che si sia creata una ridondanza e più comandi fanno la stessa operazione
[-] Ridisegnare completamente stats: includere sia RAM/CPU che controllare progetto per progetto
[-] Ridisegnare sistema convert. Oltre convert creare "add-service queue/scheduler" e "remove-service queue/scheduler"
[-] Eseguire test totale
[X] Test switch tipo progetto (php/wordpress/laravel) e controllo container aggiuntivi
[X] Test shared/dedicated per queue/scheduler
[X] Spostare i volumes database nella cartella di phpharbor e poi controllare che al remove la cartella viene effettivametne pulita (sia per shared che per dedicated)
[X] Tradurre documentazione e script stats, scritto interamente in italiano
[X] Valutare effettivo consumo di risorse (RAM, DISCO, CPU)
[X] Aggiungere MariaDB come scelta possibile per il database (sia shared che dedicated)