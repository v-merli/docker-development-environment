# PHPHarbor Go Native - Roadmap Completo

> Documentazione tecnica per un eventuale porting completo da Bash a Go nativo

**Status:** 📋 PIANIFICAZIONE FUTURA  
**Priorità:** BASSA (non necessario per release iniziale)  
**Quando considerarlo:** Se performance/manutenibilità diventano problemi

---

## 🎯 Obiettivi del Porting Nativo

### Perché Considerarlo (un giorno)?

**Vantaggi:**
- ⚡ Performance: Go è più veloce di Bash
- 🧪 Testing: Unit test su logica business
- 🔧 Manutenibilità: Type safety, IDE support
- 🌍 Cross-platform: Windows supporto nativo
- 📦 Single binary: Zero dipendenze esterne (anche bash)
- 🔄 Streaming real-time: Output progressivo durante operazioni lunghe

**Svantaggi:**
- ⏱️ Tempo sviluppo: ~4-6 mesi
- 🐛 Bug risk: Riscrivere codice testato
- 📚 Complessità: Più codice da mantenere
- 🔄 Duplicazione: Mantenere bash e Go in parallelo durante transizione

---

## 🏗️ Architettura Target

### Struttura Package

```
cli-go/
├── main.go                    # Entry point
├── tui.go                     # TUI interface
├── cmd/                       # Cobra commands
│   ├── root.go
│   ├── create.go
│   ├── list.go
│   ├── start.go
│   └── ...
├── internal/                  # Business logic (non esportabile)
│   ├── docker/
│   │   ├── client.go         # Docker SDK wrapper
│   │   ├── compose.go        # docker-compose operations
│   │   └── images.go         # Image management
│   ├── project/
│   │   ├── manager.go        # Project CRUD
│   │   ├── scanner.go        # Scan projects/ directory
│   │   ├── templates.go      # Project templates
│   │   └── types.go          # Project types (Laravel, WP, etc.)
│   ├── config/
│   │   ├── loader.go         # Load .env, docker-compose.yml
│   │   ├── generator.go      # Generate configs
│   │   └── validator.go      # Validate configurations
│   ├── network/
│   │   ├── proxy.go          # Nginx proxy management
│   │   └── dns.go            # dnsmasq integration
│   ├── ssl/
│   │   ├── ca.go             # Certificate Authority
│   │   ├── cert.go           # Certificate generation
│   │   └── trust.go          # System trust store
│   └── system/
│       ├── stats.go          # Disk usage, containers info
│       └── cleanup.go        # System cleanup
├── pkg/                      # Librerie riusabili (esportabili)
│   ├── ui/
│   │   ├── wizard.go         # Generic wizard framework
│   │   ├── table.go          # Table rendering
│   │   └── progress.go       # Progress bars
│   └── template/
│       └── renderer.go       # Template rendering utilities
└── testdata/                 # Test fixtures
```

---

## 📦 Dipendenze Go Necessarie

### Docker Integration

```go
// Docker SDK - API ufficiale Docker
github.com/docker/docker/client
github.com/docker/docker/api/types
github.com/docker/docker/api/types/container
github.com/docker/docker/api/types/network
github.com/docker/go-connections/nat

// Docker Compose (v2) - API programmatica
github.com/compose-spec/compose-go
```

### Configuration & Templates

```go
// YAML parsing
gopkg.in/yaml.v3

// Configuration management
github.com/spf13/viper

// Template rendering (stdlib enhancement)
text/template
html/template  // Per nginx configs con caratteri speciali
```

### SSL/TLS

```go
// Certificate generation (stdlib)
crypto/x509
crypto/x509/pkix
crypto/rsa
crypto/ecdsa
crypto/rand
encoding/pem

// System CA store integration
// macOS: security add-trusted-cert
// Linux: update-ca-certificates
```

### Network & HTTP

```go
// HTTP client per download
net/http

// DNS resolution
net
```

### File System

```go
// File operations (stdlib)
os
io/ioutil
path/filepath

// File watching (per auto-reload)
github.com/fsnotify/fsnotify
```

### Testing

```go
// Test framework
testing

// Mocking
github.com/stretchr/testify/mock
github.com/stretchr/testify/assert

// Docker test containers
github.com/testcontainers/testcontainers-go
```

---

## 🔧 Implementazione Componenti Chiave

### 1. Docker Client Wrapper

**File:** `internal/docker/client.go`

```go
package docker

import (
    "context"
    "github.com/docker/docker/client"
)

type Client struct {
    cli *client.Client
    ctx context.Context
}

func NewClient() (*Client, error) {
    cli, err := client.NewClientWithOpts(client.FromEnv)
    if err != nil {
        return nil, err
    }
    
    return &Client{
        cli: cli,
        ctx: context.Background(),
    }, nil
}

func (c *Client) ListContainers(projectName string) ([]Container, error) {
    // Implementa filtro per label com.docker.compose.project
}

func (c *Client) StartProject(projectPath string) error {
    // Equivalente a: docker-compose up -d
}

func (c *Client) StopProject(projectName string) error {
    // Equivalente a: docker-compose down
}

func (c *Client) StreamLogs(containerID string, follow bool) (<-chan string, error) {
    // Stream logs in real-time
}
```

**Vantaggi:**
- Controllo fine-grained su containers
- No dipendenza da docker-compose binary
- Streaming logs real-time nel TUI
- Error handling migliore

**Complessità:** ALTA (gestire networks, volumes, health checks)

---

### 2. Project Manager

**File:** `internal/project/manager.go`

```go
package project

import (
    "os"
    "path/filepath"
)

type Manager struct {
    projectsDir string
}

type Project struct {
    Name        string
    Type        string // laravel, wordpress, php, html
    PHPVersion  string
    Domain      string
    Status      string // running, stopped
    Path        string
    Config      *Config
}

func (m *Manager) List() ([]Project, error) {
    // Scan projects/ directory
    // Parse docker-compose.yml + .env
    // Check container status via Docker API
}

func (m *Manager) Create(opts CreateOptions) error {
    // 1. Create directory structure
    // 2. Generate docker-compose.yml from template
    // 3. Generate .env
    // 4. Generate nginx.conf
    // 5. Initialize project (composer install, wp-cli, etc.)
    // 6. Generate SSL cert
}

func (m *Manager) Start(name string) error {
    // docker-compose up -d via Docker API
}

func (m *Manager) Stop(name string) error {
    // docker-compose down via Docker API
}
```

**Vantaggi:**
- Validazione type-safe
- Testing facile
- Logica business separata da UI

**Complessità:** MEDIA

---

### 3. Template Generator

**File:** `internal/project/templates.go`

```go
package project

import (
    "text/template"
    "embed"
)

//go:embed templates/*
var templatesFS embed.FS

type TemplateData struct {
    ProjectName string
    PHPVersion  string
    ProjectType string
    Domain      string
    HTTPPort    int
    HTTPSPort   int
    MySQLPort   int
    RedisPort   int
}

func GenerateDockerCompose(data TemplateData) (string, error) {
    tmpl, err := template.ParseFS(templatesFS, "templates/docker-compose.yml.tmpl")
    if err != nil {
        return "", err
    }
    
    var buf bytes.Buffer
    err = tmpl.Execute(&buf, data)
    return buf.String(), err
}

// templates/docker-compose.yml.tmpl
/*
version: '3.8'
services:
  {{ .ProjectName }}:
    image: phpharbor/php:{{ .PHPVersion }}
    container_name: {{ .ProjectName }}
    ...
*/
```

**Vantaggi:**
- Templates embedded nel binary
- Type-safe template data
- Facile testare output

**Complessità:** BASSA

---

### 4. SSL Certificate Manager

**File:** `internal/ssl/cert.go`

```go
package ssl

import (
    "crypto/rand"
    "crypto/rsa"
    "crypto/x509"
    "crypto/x509/pkix"
    "encoding/pem"
    "math/big"
    "time"
)

type CertManager struct {
    caDir string
}

func (cm *CertManager) GenerateCA() error {
    // Generate CA private key
    caKey, err := rsa.GenerateKey(rand.Reader, 2048)
    
    // Generate CA certificate
    ca := &x509.Certificate{
        SerialNumber: big.NewInt(2024),
        Subject: pkix.Name{
            Organization: []string{"PHPHarbor Development CA"},
        },
        NotBefore:             time.Now(),
        NotAfter:              time.Now().AddDate(10, 0, 0),
        IsCA:                  true,
        KeyUsage:              x509.KeyUsageCertSign | x509.KeyUsageDigitalSignature,
        BasicConstraintsValid: true,
    }
    
    // Self-sign CA cert
    caBytes, err := x509.CreateCertificate(rand.Reader, ca, ca, &caKey.PublicKey, caKey)
    
    // Save to disk
}

func (cm *CertManager) GenerateProjectCert(domain string) error {
    // Load CA
    // Generate project key
    // Create certificate signed by CA
    // Save cert + key
}

func (cm *CertManager) TrustCA() error {
    // macOS: security add-trusted-cert -d -r trustRoot -k ~/Library/Keychains/login.keychain ca.crt
    // Linux: cp ca.crt /usr/local/share/ca-certificates/ && update-ca-certificates
    // Windows: certutil -addstore -f "ROOT" ca.crt
}
```

**Vantaggi:**
- No dipendenza da OpenSSL
- Controllo completo su certificati
- Cross-platform

**Complessità:** MEDIA-ALTA (trust store varia per OS)

---

### 5. System Stats

**File:** `internal/system/stats.go`

```go
package system

import (
    "github.com/docker/docker/client"
)

type Stats struct {
    TotalContainers int
    RunningContainers int
    TotalImages int
    TotalVolumes int
    DiskUsage DiskUsage
}

type DiskUsage struct {
    Images     int64
    Containers int64
    Volumes    int64
    BuildCache int64
    Total      int64
}

func GetStats(cli *client.Client) (*Stats, error) {
    // docker system df via API
    diskUsage, err := cli.DiskUsage(ctx)
    
    // docker ps -a
    containers, err := cli.ContainerList(ctx, types.ContainerListOptions{All: true})
    
    // docker images
    images, err := cli.ImageList(ctx, types.ImageListOptions{})
    
    // Aggregate data
}

func Cleanup(cli *client.Client, pruneOptions PruneOptions) error {
    // docker system prune
    // docker volume prune
    // docker image prune
}
```

**Vantaggi:**
- Dati precisi in tempo reale
- No parsing output testuale
- Progress tracking

**Complessità:** BASSA-MEDIA

---

## 🧪 Testing Strategy

### Unit Tests

```go
// internal/project/manager_test.go
func TestManager_List(t *testing.T) {
    // Setup test directory
    tmpDir := t.TempDir()
    
    // Create mock projects
    createMockProject(tmpDir, "test-project")
    
    // Test
    mgr := NewManager(tmpDir)
    projects, err := mgr.List()
    
    assert.NoError(t, err)
    assert.Len(t, projects, 1)
    assert.Equal(t, "test-project", projects[0].Name)
}
```

### Integration Tests

```go
// integration_test.go
func TestDockerIntegration(t *testing.T) {
    if testing.Short() {
        t.Skip("skipping integration test")
    }
    
    // Use testcontainers-go
    ctx := context.Background()
    
    // Start test MySQL container
    mysqlC, err := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
        ContainerRequest: testcontainers.ContainerRequest{
            Image: "mysql:8.0",
            // ...
        },
    })
    
    // Test project creation with real Docker
}
```

### E2E Tests (TUI)

```go
// Bubble Tea testing
func TestTUI_ProjectList(t *testing.T) {
    m := newTUIModel()
    
    // Simulate key presses
    m, _ = m.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune("/list")})
    m, _ = m.Update(tea.KeyMsg{Type: tea.KeyEnter})
    
    // Assert view contains expected content
    output := m.View()
    assert.Contains(t, output, "Available Projects")
}
```

---

## 📊 Migration Strategy (Se un giorno si fa)

### Step 1: Parallel Implementation (Mese 1-2)

- Implementare componenti core in Go
- Mantenere bash funzionante
- Feature flag per switch tra bash/Go

```go
if config.UseNativeGo {
    return goImplementation.List()
} else {
    return bashWrapper.List()
}
```

### Step 2: Testing Parallelo (Mese 3)

- Eseguire entrambe implementazioni
- Comparare output
- Fix differenze

### Step 3: Gradual Rollout (Mese 4)

- Default Go, fallback bash
- Beta tester
- Feedback loop

### Step 4: Deprecation (Mese 5-6)

- Rimuovere bash wrapper
- Cleanup codice legacy
- Release v2.0.0

---

## 🎯 Priority Matrix

| Componente | Complessità | Beneficio | Priorità |
|------------|-------------|-----------|----------|
| Project List | BASSA | ALTO | 🔴 P0 |
| Project Start/Stop | MEDIA | ALTO | 🔴 P0 |
| Stats & Info | BASSA | MEDIO | 🟡 P1 |
| Create Project | ALTA | ALTO | 🔴 P0 |
| SSL Generation | MEDIA-ALTA | BASSO | 🟢 P2 |
| Setup & Init | MEDIA | BASSO | 🟢 P2 |
| Dev Tools (shell) | BASSA | MEDIO | 🟡 P1 |
| Docker Logs Stream | MEDIA | MEDIO | 🟡 P1 |
| Reset/Cleanup | BASSA | BASSO | 🟢 P3 |

---

## 💡 Alternative: Hybrid Approach

**Idea:** Tenere bash per operazioni complesse, Go per UI/orchestrazione

```go
// Hybrid: Go per business logic, bash per Docker operations
func (m *Manager) Start(name string) error {
    // Validazione in Go
    project, err := m.GetProject(name)
    if err != nil {
        return err
    }
    
    // Esecuzione in bash (riusando script esistenti)
    cmd := exec.Command("bash", "../../phpharbor", "start", name)
    return cmd.Run()
}
```

**Pro:**
- Riusa codice testato
- Focus su UX invece di reimplementare
- Menor risk

**Contro:**
- Dipendenza bash rimane
- Meno controllo

---

## 🔍 Metriche di Successo (Se si fa porting)

- ✅ **Performance:** Comandi ≥ 2x più veloci
- ✅ **Test Coverage:** ≥ 80%
- ✅ **Binary Size:** ≤ 20 MB
- ✅ **Zero Regressions:** Tutte le feature esistenti funzionanti
- ✅ **Windows Support:** Funziona senza WSL

---

## 📚 Risorse & Riferimenti

### Docker SDK

- [Docker Engine API](https://docs.docker.com/engine/api/sdk/)
- [Docker SDK for Go](https://pkg.go.dev/github.com/docker/docker)
- [Compose Spec](https://github.com/compose-spec/compose-go)

### SSL in Go

- [crypto/x509 Package](https://pkg.go.dev/crypto/x509)
- [Certificate Management in Go](https://github.com/cloudflare/cfssl)

### Testing

- [Testcontainers Go](https://golang.testcontainers.org/)
- [Testify](https://github.com/stretchr/testify)

---

## ⚖️ Decisione Finale

**Per la release iniziale (TUI wrapper):**
- ❌ NO Go nativo
- ✅ Bash wrapper
- 🎯 Focus su UX del TUI

**Per il futuro:**
- 📋 Questo documento come riferimento
- 🔄 Rivalutare se emergono problemi di performance/manutenibilità
- 🎯 Approccio incrementale se deciso

---

**Versione:** 1.0  
**Data:** 3 Aprile 2026  
**Status:** 📋 Pianificazione futura (non prioritaria)  
**Tempo Stimato (se fatto):** 4-6 mesi  
**Beneficio Stimato:** MEDIO (nice-to-have, non critical)
