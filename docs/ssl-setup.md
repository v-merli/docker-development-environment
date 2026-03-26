# 🔐 Guide: SSL Certificates for Local Development

## ✅ Current Status

The system is configured with **mkcert** to generate locally trusted SSL certificates.

- ✅ Local CA installed
- ✅ Self-signed certificates automatically generated
- ✅ CA present in system keychain

## 🔧 If Browser Still Shows Security Warnings

### 1. Restart ALL Browsers

**This is essential!** Browser load certificates at startup.

```bash
# Completely close all open browsers
# Then reopen them
```

### 2. Verify in Keychain (macOS)

1. Open **"Keychain Access"**
2. In sidebar, select **"System"**
3. Search for **"mkcert"**
4. You should see: `mkcert vincenzo@MERVIN-MAC (Vincenzo)`

#### If certificate is not trusted:

1. **Double-click** on the mkcert certificate
2. Expand the **"Trust"** section
3. For **"SSL (Secure Sockets Layer)"** select: **"Always Trust"**
4. Close the window (will ask for password)
5. **Restart browser**

### 3. Test Certificate

```bash
# Verify certificate is present
./phpharbor ssl verify

# Test HTTPS access
open https://ptest.test:8443
```

## 🌐 Browser-Specific

### Chrome / Safari / Edge

Use macOS system keychain. If you followed the steps above, they should work.

**If Chrome still shows warning:**
1. Go to page with warning
2. Click on an empty spot on the page
3. Type: `thisisunsafe` (literally, no spaces)
4. Page will reload and bypass warning

### Firefox

Firefox uses its **own certificate store**, separate from the system.

**Method 1: Install nss (recommended)**
```bash
brew install nss
./phpharbor ssl install
```

**Method 2: Import manually**
1. In Firefox, go to `about:preferences#privacy`
2. Scroll to **"Certificates"**
3. Click **"View Certificates..."**
4. **"Authorities"** tab
5. Click **"Import..."**
6. Select: `/Users/vincenzo/Library/Application Support/mkcert/rootCA.pem`
7. Check: **"Trust this CA to identify websites"**
8. Click **"OK"**
9. Restart Firefox

## 🛠️ Useful Commands

```bash
# Verify SSL configuration
./phpharbor ssl verify

# Generate certificate for new domain
./phpharbor ssl generate mydomain.test

# Reinstall CA (if needed)
./phpharbor ssl install

# Complete setup (first time)
./phpharbor ssl setup
```

## 🔄 Regenerate All Certificates

If you have persistent issues:

```bash
# 1. Reinstall CA
./phpharbor ssl install

# 2. Regenerate certificates for your projects
./phpharbor ssl generate ptest.test
./phpharbor ssl generate test-ssl.test

# 3. Restart nginx-proxy
cd proxy && docker compose restart nginx-proxy

# 4. Close and restart ALL browsers
```

## ❓ Manual Verification

To verify the certificate is trusted:

```bash
# Display certificate
security find-certificate -c "mkcert" -p /Library/Keychains/System.keychain | \
  openssl x509 -noout -text

# Verify trust
security dump-trust-settings -d | grep -A 5 mkcert
```

## 📝 Notes

- mkcert certificates are **valid only locally**
- Won't work in production
- Perfect for local development with `.test`, `.local` domains, etc.
- CA certificate is valid until **2036**

## 🆘 Troubleshooting

### "NET::ERR_CERT_AUTHORITY_INVALID"

CA is not trusted by browser:
1. Run: `./phpharbor ssl install`
2. Open Keychain Access and mark as "Always Trust"
3. Restart browser

### "NET::ERR_CERT_COMMON_NAME_INVALID"

Certificate doesn't cover the domain:
```bash
# Regenerate certificate
./phpharbor ssl generate project-name.test
```

### Works on Chrome but not Firefox

Firefox uses its own store:
```bash
brew install nss
./phpharbor ssl setup
```
