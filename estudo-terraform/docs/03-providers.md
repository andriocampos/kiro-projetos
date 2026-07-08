# 📖 03 — Providers

## O que é um Provider?

Um provider é um **plugin** que permite ao Terraform interagir com APIs de serviços externos. Sem provider, o Terraform não sabe fazer nada.

```
  Seu Código (.tf)  ──►  Provider (plugin)  ──►  API AWS (real)
```

### Providers populares:

| Provider | O que gerencia |
|----------|---------------|
| `hashicorp/aws` | Todos os serviços AWS |
| `hashicorp/azurerm` | Serviços Azure |
| `hashicorp/google` | Google Cloud |
| `hashicorp/kubernetes` | Resources do K8s |
| `integrations/github` | Repos, teams, webhooks |
| `hashicorp/random` | Valores aleatórios |

---

## Configuração do Provider AWS

### Bloco terraform — Declarar requisitos

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
```

### Bloco provider — Configurar o plugin

```hcl
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "meu-projeto"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}
```

---

## Versionamento de Providers (CRÍTICO)

| Constraint | Significado | Recomendação |
|-----------|-------------|--------------|
| `= 5.0.0` | Exatamente esta | Rígido demais |
| `>= 5.0.0` | Esta ou superior | ⚠️ Perigoso |
| `~> 5.0` | >= 5.0, < 6.0 | ✅ **Recomendado** |
| `~> 5.0.0` | >= 5.0.0, < 5.1.0 | Só patches |

### O `.terraform.lock.hcl`

Gerado no `terraform init`, contém hashes exatos dos providers.

> ⚠️ **SEMPRE commitar `.terraform.lock.hcl` no git!** Garante mesma versão para todos.

---

## Autenticação com AWS

Ordem de prioridade:

```
1. Argumentos no bloco provider    (❌ NUNCA)
2. Environment variables           (✅ CI/CD)
3. ~/.aws/credentials              (✅ local)
4. IAM Instance Profile            (✅ produção)
```

### ❌ NUNCA faça isso:

```hcl
provider "aws" {
  access_key = "AKIAIOSFODNN7EXAMPLE"   # CRIME
  secret_key = "wJalrXUtn..."           # CRIME
}
```

### ✅ Forma correta:

```bash
aws configure
# Ou
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
```

---

## Provider com múltiplas regiões (alias)

```hcl
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "europe"
  region = "eu-west-1"
}

resource "aws_s3_bucket" "eu_bucket" {
  provider = aws.europe
  bucket   = "meu-bucket-europa"
}
```

---

## Default Tags (Boa Prática)

Por que usar:
1. **Nenhum recurso fica sem tag** — mesmo se esquecer
2. **Facilita billing** — filtrar custos por projeto
3. **Compliance** — tags obrigatórias garantidas
4. **Automação** — scripts agem com base em tags

Se definir a mesma tag no `default_tags` E no resource, a do resource **vence**.

---

## Comandos Úteis

```bash
terraform providers          # Ver providers instalados
terraform init -upgrade      # Atualizar providers
```

---

## Anterior: [02 — Estrutura de Projeto](./02-estrutura-projeto.md) | Próximo: [04 — Variables e Locals](./04-variables-locals.md)
