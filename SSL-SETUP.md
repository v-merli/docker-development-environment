# 🔐 Guida: Certificati SSL per Sviluppo Locale

## ✅ Stato Attuale

Il sistema è configurato con **mkcert** per generare certificati SSL fidati localmente.

- ✅ CA locale installata
- ✅ Certificati auto-firmati generati automaticamente
- ✅ CA presente nel keychain di sistema

## 🔧 Se il Browser Mostra Ancora Avvisi di Sicurezza

### 1. Riavvia TUTTI i Browser

**È fondamentale!** I browser caricano i certificati all'avvio.

```bash
# Chiudi completamente tutti i browser aperti
# Poi riaprili
```

### 2. Verifica nel Keychain (macOS)

1. Apri **"Accesso Portachiavi"** (Keychain Access)
2. Nella barra laterale, seleziona **"Sistema"** (System)
3. Cerca **"mkcert"**
4. Dovresti vedere: `mkcert vincenzo@MERVIN-MAC (Vincenzo)`

#### Se il certificato non è fidato:

1. Fai **doppio clic** sul certificato mkcert
2. Espandi la sezione **"Fidati"** (Trust)
3. Per **"SSL (Secure Sockets Layer)"** seleziona: **"Fidati sempre"**
4. Chiudi la finestra (ti chiederà la password)
5. **Riavvia il browser**

### 3. Test Certificato

```bash
# Verifica che il certificato sia presente
./docker-dev ssl verify

# Testa l'accesso HTTPS
open https://ptest.test:8443
```

## 🌐 Browser-Specific

### Chrome / Safari / Edge

Usano il keychain di sistema macOS. Se hai seguito i passi sopra, dovrebbero funzionare.

**Se Chrome mostra ancora l'avviso:**
1. Vai alla pagina con l'avviso
2. Clicca su un punto vuoto della pagina
3. Digita: `thisisunsafe` (letteralmente, senza spazi)
4. La pagina si ricaricherà e bypasser l'avviso

### Firefox

Firefox usa il **proprio archivio certificati**, separato dal sistema.

**Metodo 1: Installa nss (raccomandato)**
```bash
brew install nss
./docker-dev ssl install
```

**Metodo 2: Importa manualmente**
1. In Firefox, vai a `about:preferences#privacy`
2. Scorri fino a **"Certificati"**
3. Clicca **"Visualizza certificati..."**
4. Tab **"Autorità"**
5. Clicca **"Importa..."**
6. Seleziona: `/Users/vincenzo/Library/Application Support/mkcert/rootCA.pem`
7. Spunta: **"Considera attendibile questa CA per identificare i siti web"**
8. Clicca **"OK"**
9. Riavvia Firefox

## 🛠️ Comandi Utili

```bash
# Verifica configurazione SSL
./docker-dev ssl verify

# Genera certificato per nuovo dominio
./docker-dev ssl generate miodominio.test

# Reinstalla CA (se necessario)
./docker-dev ssl install

# Setup completo (prima volta)
./docker-dev ssl setup
```

## 🔄 Rigenerare Tutti i Certificati

Se hai problemi persistenti:

```bash
# 1. Reinstalla la CA
./docker-dev ssl install

# 2. Rigenera i certificati per i tuoi progetti
./docker-dev ssl generate ptest.test
./docker-dev ssl generate test-ssl.test

# 3. Riavvia nginx-proxy
cd proxy && docker compose restart nginx-proxy

# 4. Chiudi e riavvia TUTTI i browser
```

## ❓ Verifica Manuale

Per verificare che il certificato sia fidato:

```bash
# Visualizza il certificato
security find-certificate -c "mkcert" -p /Library/Keychains/System.keychain | \
  openssl x509 -noout -text

# Verifica la fiducia
security dump-trust-settings -d | grep -A 5 mkcert
```

## 📝 Note

- I certificati mkcert sono **validi solo localmente**
- Non funzioneranno in produzione
- Sono perfetti per sviluppo locale con domini `.test`, `.local`, etc.
- Il certificato CA è valido fino al **2036**

## 🆘 Troubleshooting

### "NET::ERR_CERT_AUTHORITY_INVALID"

La CA non è fidata dal browser:
1. Esegui: `./docker-dev ssl install`
2. Apri Keychain Access e marca come "Fidati sempre"
3. Riavvia il browser

### "NET::ERR_CERT_COMMON_NAME_INVALID"

Il certificato non copre il dominio:
```bash
# Rigenera il certificato
./docker-dev ssl generate nome-progetto.test
```

### Funziona su Chrome ma non su Firefox

Firefox usa il proprio archivio:
```bash
brew install nss
./docker-dev ssl setup
```
