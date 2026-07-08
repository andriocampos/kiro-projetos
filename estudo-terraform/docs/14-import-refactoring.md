# 📖 14 — Import e Refactoring

## O Problema

Você tem infraestrutura criada manualmente (no console) ou por outro IaC e quer passar a gerenciar com Terraform. Ou precisa renomear/mover resources sem destruí-los.

---

## Import — Trazer recursos existentes para o Terraform

### Método 1: `terraform import` (CLI)

```bash
# Sintaxe: terraform import <endereço_no_código> <id_real_na_aws>
terraform import aws_s3_bucket.existing meu-bucket-existente
terraform import aws_instance.web i-1234567890abcdef0
terraform import aws_iam_role.app my-app-role
```

**Passo a passo:**

1. Escreva o bloco `resource` no código (pode estar vazio inicialmente):
```hcl
resource "aws_s3_bucket" "existing" {
  bucket = "meu-bucket-existente"
}
```

2. Rode o import:
```bash
terraform import aws_s3_bucket.existing meu-bucket-existente
```

3. Rode `terraform plan` — vai mostrar diferenças entre código e realidade

4. Ajuste o código até `plan` mostrar "No changes"

### Método 2: `import` block (Terraform 1.5+) ✅ Recomendado

```hcl
# No código — declarativo, auditável, funciona em CI/CD
import {
  to = aws_s3_bucket.existing
  id = "meu-bucket-existente"
}

resource "aws_s3_bucket" "existing" {
  bucket = "meu-bucket-existente"
}
```

```bash
terraform plan    # Mostra o que vai importar
terraform apply   # Importa e sincroniza state
```

Vantagens do import block:
- ✅ Versionável no git (aparece na PR)
- ✅ Funciona em CI/CD (sem comandos manuais)
- ✅ Pode importar múltiplos de uma vez
- ✅ Após importar, pode remover o bloco `import`

### Método 3: Gerar código automaticamente (Terraform 1.5+)

```bash
# Gera o código HCL a partir do recurso importado
terraform plan -generate-config-out=generated.tf
```

---

## Moved Blocks — Renomear/Mover sem destruir

### Renomear resource

Antes:
```hcl
resource "aws_s3_bucket" "my_bucket" { }
```

Depois:
```hcl
moved {
  from = aws_s3_bucket.my_bucket
  to   = aws_s3_bucket.logs
}

resource "aws_s3_bucket" "logs" { }
```

```bash
terraform plan
# Mostra: aws_s3_bucket.my_bucket has moved to aws_s3_bucket.logs
# Nenhum destroy! Apenas atualiza o state.
```

### Mover para dentro de um módulo

```hcl
moved {
  from = aws_s3_bucket.logs
  to   = module.storage.aws_s3_bucket.logs
}
```

### Mover de for_each para nome fixo

```hcl
moved {
  from = aws_s3_bucket.this["logs"]
  to   = aws_s3_bucket.logs
}
```

### Depois de aplicar

Após o `apply` processar os moved blocks, você pode removê-los do código. Eles só precisam existir durante a transição.

---

## Refactoring — State Surgery

### `terraform state mv` — Mover no state

```bash
# Renomear
terraform state mv aws_s3_bucket.old aws_s3_bucket.new

# Mover para módulo
terraform state mv aws_s3_bucket.this module.storage.aws_s3_bucket.this

# Mover entre states (avançado)
terraform state mv -state-out=other.tfstate aws_s3_bucket.this aws_s3_bucket.this
```

> ⚠️ Prefira `moved` blocks sobre `state mv`. Moved blocks são declarativos, auditáveis e funcionam em CI/CD.

### `terraform state rm` — Terraform "esquece" um resource

```bash
# Terraform para de gerenciar, MAS não destrói na AWS
terraform state rm aws_s3_bucket.this
```

Útil quando:
- Quer transferir ownership para outro state
- Quer parar de gerenciar sem destruir
- Resource foi criado por engano no state errado

---

## `removed` block (Terraform 1.7+)

Declarativo para remover do state sem destruir:

```hcl
removed {
  from = aws_s3_bucket.old_bucket

  lifecycle {
    destroy = false   # NÃO destruir na AWS
  }
}
```

---

## Workflow Completo de Import

```bash
# 1. Identificar recursos existentes
aws s3 ls
aws ec2 describe-instances --query 'Reservations[].Instances[].InstanceId'

# 2. Escrever código Terraform
# (ou usar -generate-config-out)

# 3. Importar
terraform import aws_s3_bucket.this meu-bucket

# 4. Rodar plan e ajustar até "No changes"
terraform plan
# Ajustar código...
terraform plan  # Repetir até clean

# 5. Commitar
git add . && git commit -m "feat: import bucket existente para Terraform"
```

---

## Boas Práticas

1. **Prefira import blocks** sobre CLI `terraform import`
2. **Prefira moved blocks** sobre `terraform state mv`
3. **Sempre rode plan** após qualquer operação de state
4. **Backup do state** antes de operações arriscadas: `terraform state pull > backup.tfstate`
5. **Um import por PR** — facilita review
6. **Remova import/moved blocks** após aplicar (mantém código limpo)

---

## Exercício Prático

1. Crie um bucket manualmente no console AWS
2. Escreva o resource block no Terraform
3. Use `import` block para importar
4. Rode `plan` e ajuste até "No changes"
5. Renomeie o resource com `moved` block
6. Confirme que plan não mostra destroy

---

## Anterior: [13 — CI/CD](./13-cicd.md) | Próximo: [15 — Testing](./15-testing.md)
