# 📖 06 — Outputs e State

## Outputs

Outputs expõem valores **após o apply**. Servem para:

1. Exibir informações úteis no terminal
2. Compartilhar dados entre módulos
3. Ser consultados via `terraform output` ou scripts

### Sintaxe

```hcl
output "bucket_name" {
  description = "Nome do bucket S3 criado"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN do bucket (para policies IAM)"
  value       = aws_s3_bucket.this.arn
}

output "database_password" {
  description = "Senha do banco"
  value       = random_password.db.result
  sensitive   = true   # Não mostra no terminal
}
```

### Usando outputs entre módulos

```hcl
# Módulo A expõe:
output "vpc_id" {
  value = aws_vpc.this.id
}

# Módulo B consome:
module "networking" {
  source = "../modules/networking"
}

resource "aws_instance" "this" {
  subnet_id = module.networking.vpc_id   # ← consome output
}
```

### Consultando outputs

```bash
terraform output                   # Mostra todos
terraform output bucket_name       # Mostra um específico
terraform output -json             # Formato JSON (útil para scripts)
```

---

## State — O coração do Terraform

### O que é o State?

O state é um arquivo JSON que mapeia **seu código** para **recursos reais** na cloud.

```
Código (.tf)          State (.tfstate)         Infra Real (AWS)
─────────────         ────────────────         ────────────────
aws_s3_bucket.this → "arn:aws:s3:::bucket" → Bucket real na AWS
```

### Por que o State existe?

1. **Mapeamento** — Sabe qual resource no código = qual recurso na AWS
2. **Performance** — Não precisa consultar a API para tudo
3. **Metadata** — Guarda dependências entre resources
4. **Detecção de drift** — Compara state vs realidade no `plan`

### O que contém o state?

```json
{
  "resources": [
    {
      "type": "aws_s3_bucket",
      "name": "this",
      "instances": [
        {
          "attributes": {
            "id": "estudo-terraform-dev-artifacts",
            "arn": "arn:aws:s3:::estudo-terraform-dev-artifacts",
            "region": "us-east-1"
          }
        }
      ]
    }
  ]
}
```

> ⚠️ O state pode conter **dados sensíveis** em plain text (senhas, tokens). NUNCA commite no git!

---

## State Local vs Remoto

### Local (padrão — só para estudo)

```
projeto/
└── terraform.tfstate   # Arquivo local — PERIGOSO em time
```

Problemas:
- Sem lock — duas pessoas podem aplicar ao mesmo tempo
- Sem backup — se perder o arquivo, perde o controle da infra
- Sem compartilhamento — cada um tem seu state local

### Remoto (obrigatório em time/produção)

```hcl
terraform {
  backend "s3" {
    bucket         = "minha-empresa-terraform-state"
    key            = "estudo-terraform/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"  # Locking!
  }
}
```

Benefícios:
- ✅ **Lock** — DynamoDB impede applies simultâneos
- ✅ **Criptografia** — State encriptado em repouso
- ✅ **Compartilhamento** — Time inteiro usa o mesmo state
- ✅ **Backup** — S3 versioning protege contra corrupção

---

## Comandos de State

```bash
# Listar todos os recursos no state
terraform state list

# Ver detalhes de um recurso
terraform state show aws_s3_bucket.this

# Mover recurso (renomear sem destruir)
terraform state mv aws_s3_bucket.old aws_s3_bucket.new

# Remover do state (Terraform "esquece" o recurso — não destrói)
terraform state rm aws_s3_bucket.this

# Importar recurso existente para o state
terraform import aws_s3_bucket.this nome-do-bucket-real
```

---

## Drift Detection

```
Estado normal:
  Código = State = Realidade   ✅

Drift (alguém mexeu no console):
  Código = State ≠ Realidade   ⚠️

O que terraform plan mostra:
  "Resource has been changed outside of Terraform"
  Plan: update in-place (volta ao estado do código)
```

---

## Boas Práticas de State

1. **NUNCA** edite o state manualmente
2. **SEMPRE** use backend remoto em time
3. **SEMPRE** habilite encryption
4. **SEMPRE** habilite DynamoDB locking
5. **SEMPRE** habilite S3 versioning no bucket de state
6. **Um state por ambiente** — dev, staging e prod separados
7. **Um state por domínio** — networking, compute, database separados

---

---

## Exercício Prático

1. Crie outputs para: bucket name, bucket arn, e um output sensitive
2. Rode `terraform apply` e veja os outputs no terminal
3. Rode `terraform output` e `terraform output -json`
4. Rode `terraform state list` para ver os resources no state
5. Rode `terraform state show aws_s3_bucket.this` para ver detalhes
6. Faça uma mudança manual no console (adicione tag) e rode `terraform plan`
7. Observe a mensagem de drift e o que o Terraform propõe fazer

---

## Anterior: [05 — Resources](./05-resources.md) | Início: [README](../README.md)
