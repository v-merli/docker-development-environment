# Guida Test Xdebug con VS Code

## ✅ Configurazione Completata

- **Xdebug installato**: v3.5.1
- **Porta**: 9003
- **Host**: host.docker.internal
- **VS Code launch.json**: Configurato
- **Route di test**: /xdebug-test

---

## 🧪 Come Testare Xdebug

### Step 1: Installa l'estensione PHP Debug in VS Code
1. Apri VS Code
2. Vai su Extensions (Cmd+Shift+X)
3. Cerca "PHP Debug" di **Xdebug**
4. Installa l'estensione

### Step 2: Apri il progetto in VS Code
```bash
cd /Users/vincenzo/php-harbor/projects/my-spots-list/app
code .
```

### Step 3: Imposta i Breakpoint
1. Apri il file: `routes/xdebug-test.php`
2. Clicca sul margine sinistro delle righe 7 e 25 per mettere i breakpoint (pallino rosso)

### Step 4: Avvia il Debug Listener
1. In VS Code, vai su "Run and Debug" (Cmd+Shift+D)
2. Seleziona "Listen for Xdebug (PHPHarbor)" dal menu a tendina
3. Clicca sul pulsante verde "Start Debugging" (F5)
4. Dovresti vedere "Xdebug: Listening on port 9003" nella Debug Console

### Step 5: Fai una Richiesta con Xdebug Trigger
Nel browser, apri una di queste URL:

**Opzione A - Con query parameter:**
```
http://my-spots-list.test:8080/xdebug-test?XDEBUG_TRIGGER=1
```

**Opzione B - Con cookie (più comodo):**
1. Installa l'estensione "Xdebug helper" per Chrome/Firefox
2. Attivala cliccando sull'icona e selezionando "Debug"
3. Vai su: `http://my-spots-list.test:8080/xdebug-test`

### Step 6: Debug!
Quando la richiesta arriva al breakpoint:
- VS Code si fermerà sulla riga
- Potrai vedere le variabili nel pannello laterale
- Potrai fare "Step Over" (F10), "Step Into" (F11), "Continue" (F5)
- Nella Debug Console vedrai i valori delle variabili

---

## 🎯 Verifica che Funzioni

Se tutto funziona, vedrai:
1. VS Code si ferma sulla riga con il breakpoint
2. Il pannello "VARIABLES" mostra `$message`, `$data`, ecc.
3. Puoi ispezionare array e oggetti
4. La richiesta nel browser rimane in "loading" finché non premi "Continue"

---

## 🐛 Troubleshooting

### Il debug non parte?
1. Verifica che il listener sia attivo (icona verde nella barra di debug)
2. Controlla la Debug Console per errori
3. Verifica che la porta 9003 non sia usata: `lsof -i :9003`

### Breakpoint ignorati?
1. Verifica che il path mapping sia corretto in launch.json
2. Assicurati di usare `?XDEBUG_TRIGGER=1` o il cookie

### Altri problemi?
Controlla i log del container:
```bash
docker logs my-spots-list-app | grep -i xdebug
```

---

## 📚 Risorse Utili

- [VS Code PHP Debugging](https://code.visualstudio.com/docs/languages/php#_debugging)
- [Xdebug Documentation](https://xdebug.org/docs/step_debug)
- [Xdebug Helper Chrome](https://chrome.google.com/webstore/detail/xdebug-helper)
- [Xdebug Helper Firefox](https://addons.mozilla.org/en-US/firefox/addon/xdebug-helper-for-firefox/)

---

## 🎓 Tutorial: Debug di una Request Laravel

1. Metti un breakpoint in un Controller
2. Apri la route nel browser con `?XDEBUG_TRIGGER=1`
3. Segui passo-passo l'esecuzione
4. Ispeziona `$request`, modelli, query database, ecc.

**Buon debug!** 🐛🔍
