# Enteksis Code Challenge

Enteksis hizmet landing page'i, hizmet talep API'si ve Docker tabanlı PostgreSQL ortamı.

## Repolar

- Client: <https://github.com/Fairdose/enteksis_client>
- Backend: <https://github.com/Fairdose/enteksis_backend>

Bu umbrella repo iki projeyi Git submodule olarak takip eder. Klonlarken:

```sh
git clone --recurse-submodules https://github.com/Fairdose/enteksis_code_challenge.git
```

## Çalıştırma

Her iki alt projedeki `run.sh` aynı Compose ortamını yönetir:

```sh
./enteksis_client/run.sh
# veya
./enteksis_backend/run.sh
```

- Client: `http://localhost:5173`
- API: `http://localhost:8080`
- PostgreSQL: `localhost:5432`

Windows üzerinde scripti Git Bash veya WSL ile çalıştırın.
