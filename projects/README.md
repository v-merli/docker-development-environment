# Projects Directory

Questa directory contiene tutti i progetti utente creati con `docker-dev`.

## 🚀 Crea il tuo primo progetto

```bash
# Torna alla root
cd ..

# Crea un nuovo progetto
./docker-dev create myapp --type laravel --php 8.3

# Oppure con configurazione fully-shared (risparmio RAM)
./docker-dev create myapp --fully-shared --php 8.3
```

## 📁 Struttura (esempio)

Dopo aver creato progetti, questa directory conterrà:

```
projects/
├── myshop/                    # Progetto e-commerce
│   ├── docker-compose.yml
│   ├── .env
│   └── app/                   # Codice Laravel
├── blog/                      # Blog WordPress
│   ├── docker-compose.yml
│   ├── .env
│   └── app/                   # Codice WordPress
└── api/                       # API REST
    ├── docker-compose.yml
    ├── .env
    └── app/                   # Codice PHP
```

## ℹ️ Note

- Questa directory è **ignorata da git** (vedi `.gitignore` nella root)
- Ogni progetto è isolato con i propri container
- I progetti possono condividere servizi (MySQL, Redis, PHP) per risparmiare RAM
- Usa `./docker-dev list` per vedere tutti i progetti

## 📚 Documentazione

- [CLI-README.md](../CLI-README.md) - Guida completa comandi
- [README.md](../README.md) - Documentazione generale
- [ARCHITECTURE.md](../ARCHITECTURE.md) - Architettura sistema
