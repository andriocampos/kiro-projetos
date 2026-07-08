# 📖 11 — Backend Remoto (S3 + DynamoDB)

## Por que Backend Remoto?

State local é aceitável apenas para estudo individual. Em qualquer outro cenário:

| Problema do State Local | Solução com Backend Remoto |
|------------------------|---------------------------|
| Sem lock — 2 pessoas aplicam ao mesmo tempo | DynamoDB faz locking |
| Sem backup — perdeu arquivo, perdeu controle | S3 com versioning |
| Sem compartilhamento — cada um tem o seu | State centralizado |
| Sem criptografia — secrets em plain text | S3 encryption at rest |

---

## Arquitetura

```
terraform apply
    │
    ├── 1. Adquire lock (DynamoDB)
    │       └── Se outro processo tem lock → ERRO, espera
    ├── 2. Lê state (S3)
    ├── 3. Compara state vs realidade (API calls)
    ├── 4. Aplica mudanças
    ├── 5. Grava novo state (S3)
    └── 6. Libera lock (DynamoDB)
```

---

## Setup Completo (Código Funcional)

### Passo 1: Criar infra do backend (bootstrap)

> ⚠️ Este é o único código Terraform que roda com state LOCAL.
> Depois de criado, todo o resto usa este backend.

Crie um diretório separado:

```
bootstrap/
├── main.tf
├── variables.tf
└── outputs.tf
```

**bootstrap/main.tf**
```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Bucket para armazenar o state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-terraform-state"

  # Impede deleção acidental
  lifecycle {
    prevent_destroy = true
  }
}

# Versionamento — permite recuperar state anterior
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Criptografia at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

# Bloquear acesso público
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Tabela DynamoDB para locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${var.project_name}-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

**bootstrap/variables.tf**
```hcl
variable "aws_region" {
  default = "us-east-1"
}

variable "project_name" {
  default = "estudo-terraform"
}
```

**bootstrap/outputs.tf**
```hcl
output "state_bucket_name" {
  value = aws_s3_bucket.terraform_state.id
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.terraform_locks.name
}
```

### Rodar o bootstrap:
```bash
cd bootstrap
terraform init
terraform apply
# Anote os outputs!
```

---

### Passo 2: Configurar backend nos projetos

Agora em qualquer projeto, adicione:

```hcl
terraform {
  backend "s3" {
    bucket         = "estudo-terraform-terraform-state"
    key            = "estudo-terraform/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "estudo-terraform-terraform-locks"
  }
}
```

### Migrar de local para remoto:
```bash
# Após adicionar o bloco backend:
terraform init -migrate-state
# Terraform pergunta se quer copiar o state local para o S3
# Responda "yes"
```

---

## Organização de Keys no S3

```
s3://empresa-terraform-state/
├── networking/
│   ├── dev/terraform.tfstate
│   ├── staging/terraform.tfstate
│   └── prod/terraform.tfstate
├── app/
│   ├── dev/terraform.tfstate
│   └── prod/terraform.tfstate
└── database/
    ├── dev/terraform.tfstate
    └── prod/terraform.tfstate
```

Regra: `<projeto>/<ambiente>/terraform.tfstate`

---

## Partial Configuration (Backend dinâmico)

Para não repetir valores em todo lugar:

**backend/dev.hcl**
```hcl
bucket         = "estudo-terraform-terraform-state"
key            = "app/dev/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "estudo-terraform-terraform-locks"
```

```bash
terraform init -backend-config="backend/dev.hcl"
```

---

## Locking na Prática

```
Usuário A: terraform apply
  → Adquire lock (LockID gravado no DynamoDB)
  → Trabalhando...

Usuário B: terraform apply
  → Tenta adquirir lock
  → ERRO: "Error acquiring the state lock"
  → Mensagem mostra quem tem o lock e desde quando

Usuário A: apply completo
  → Libera lock

Usuário B: terraform apply
  → Adquire lock ✅
  → Funciona
```

### Forçar unlock (emergência):
```bash
# CUIDADO — só use se o processo morreu sem liberar
terraform force-unlock <LOCK_ID>
```

---

## Boas Práticas

1. **Um bucket de state por conta/organização** — Não um bucket por projeto
2. **KMS encryption** — Melhor que AES256 padrão
3. **Bucket policy restritiva** — Só CI/CD e admins acessam
4. **Versionamento SEMPRE** — Permite rollback de state corrompido
5. **Separar state por domínio** — networking, compute, database independentes
6. **Nunca editar state manualmente no S3**

---

## Exercício Prático

1. Crie o diretório `bootstrap/` com o código acima
2. Rode `terraform apply` para criar o bucket e tabela
3. Adicione o bloco `backend "s3"` no projeto principal
4. Rode `terraform init -migrate-state`
5. Verifique no console AWS que o state está no S3

---

## Anterior: [10 — Ambientes](./10-ambientes.md) | Próximo: [12 — IAM e Segurança](./12-iam-seguranca.md)
