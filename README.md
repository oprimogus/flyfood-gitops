# Flyfood GitOps

Este repositório contém a configuração GitOps do projeto **Flyfood**, utilizando o **ArgoCD** para gerenciamento e sincronização de aplicações Kubernetes.

## 📁 Estrutura do repositório

```bash
flyfood-gitops/
├── apps-applicationset.yaml               # ApplicationSet do ArgoCD p/ apps
├── charts-applicationset.yaml             # ApplicationSet do ArgoCD p/ charts
├── selead-secrets-applicationset.yaml     # ApplicationSet do ArgoCD p/ secrets
├── charts/
│   └── postgresql-ha/               # Helm chart para PostgreSQL HA
├── k8s/
│   ├── apps/                        # Deployments das aplicações
│   │   └── flyfood-api/
│   │       └── deployment.yaml
│   ├── charts/
│   │   └── sealed-secrets/
│   │       └── values.yaml         # Configuração do Sealed Secrets
│   └── secrets/                    # Secrets criptografados (Sealed Secrets)
│       └── meu-secret-secret.yaml
├── LICENSE
├── Makefile
├── README.md
```

## 🚀 Como usar

### 1. Instale o ArgoCD

Certifique-se de que o ArgoCD está instalado e configurado no seu cluster Kubernetes.

### 2. Aplique o ApplicationSet

O arquivo `apps-applicationset.yaml` define múltiplas aplicações com base no conteúdo dos diretórios `k8s/apps` e `k8s/secrets`.

```bash
kubectl apply -f apps-applicationset.yaml
```

### 3. Gerencie secrets com Sealed Secrets

Utilize o `Makefile` para criar secrets de forma prática. Exemplo:

```bash
make secret NAME=meu-secret VARS="CHAVE1=valor1 CHAVE2=valor2"
```

Isso irá:

- Criar um `Secret` temporário com os valores fornecidos.
- Criptografá-lo usando `kubeseal`.
- Salvar o resultado em `k8s/secrets/<nome-do-secret>-secret.yaml`.

Certifique-se de ter os binários `kubectl` e `kubeseal` instalados e corretamente configurados.

### Parâmetros:

- `NAME`: nome base do secret.
- `VARS`: lista de chaves e valores no formato `CHAVE=VALOR`.

## ✅ Requisitos

- Kubernetes cluster
- ArgoCD
- `kubeseal` (CLI do Sealed Secrets)
- `kubectl`
- `make`

## 📜 Licença

Este projeto está licenciado sob a [MIT License](./LICENSE).
