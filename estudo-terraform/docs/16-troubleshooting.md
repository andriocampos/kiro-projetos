# 📖 16 — Troubleshooting

## Erros Mais Comuns e Como Resolver

---

### 1. "Error acquiring the state lock"

```
Error: Error acquiring the state lock
Lock Info:
  ID:        abcd-1234-efgh
  Path:      s3://bucket/terraform.tfstate
  Operation: OperationTypeApply
  Who:       user@machine
  Created:   2024-01-15 10:30:00
```

**Causa:** Outro processo (ou um processo que morreu) está segurando o lock.

**Solução:**
```bash
# 1. Verificar se realmente ninguém está rodando apply
# 2. Se o processo morreu:
terraform force-unlock abcd-1234-efgh
```

> ⚠️ Só use `force-unlock` se tem CERTEZA que ninguém está aplicando.

---

### 2. "Resource already exists"

```
Error: creating S3 Bucket (meu-bucket): BucketAlreadyOwnedByYou
```

**Causa:** O resource existe na AWS mas não está no state do Terraform.

**Soluções:**
```bash
# Opção A: Importar o recurso existente
terraform import aws_s3_bucket.this meu-bucket

# Opção B: Usar import block
# import { to = aws_s3_bucket.this; id = "meu-bucket" }

# Opção C: Mudar o nome no código (se é outro bucket)
```

---

### 3. "Cycle detected" (dependência circular)

```
Error: Cycle: aws_security_group.a, aws_security_group.b
```

**Causa:** Resource A referencia B, e B referencia A.

**Solução:** Separar a regra em `aws_security_group_rule`:
```hcl
resource "aws_security_group" "a" {
  name = "sg-a"
}

resource "aws_security_group" "b" {
  name = "sg-b"
}

# Regra separada quebra o ciclo
resource "aws_security_group_rule" "a_to_b" {
  security_group_id        = aws_security_group.a.id
  source_security_group_id = aws_security_group.b.id
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
}
```

---

### 4. "Provider configuration not present"

```
Error: Provider configuration not present
```

**Causa:** Esqueceu de rodar `terraform init` após adicionar/mudar provider.

**Solução:**
```bash
terraform init
# ou, se mudou versão:
terraform init -upgrade
```

---

### 5. "Invalid count/for_each argument"

```
Error: Invalid for_each argument
  The "for_each" map includes keys derived from resource attributes that
  cannot be determined until apply
```

**Causa:** O valor de `for_each` depende de algo que só existe após apply.

**Solução:**
```hcl
# ❌ NÃO funciona — depende de atributo computado
resource "aws_subnet" "this" {
  for_each = toset(aws_vpc.this.availability_zones)  # Não existe antes do apply!
}

# ✅ Use valor estático ou variable
resource "aws_subnet" "this" {
  for_each = toset(var.availability_zones)  # Conhecido antes do apply
}
```

---

### 6. "Error: Unsupported attribute"

```
Error: Unsupported attribute
  on main.tf line 5: This object has no argument, nested block, or exported attribute named "xyz"
```

**Causa:** Atributo não existe no provider/resource. Pode ser versão antiga do provider.

**Solução:**
```bash
# Verificar docs do provider
# Atualizar provider se necessário
terraform init -upgrade
```

---

### 7. State drift — "has been changed outside of Terraform"

```
Note: Objects have changed outside of Terraform
  # aws_s3_bucket.this has been changed
  ~ tags = {
      + "Manual" = "true"
    }
```

**Causa:** Alguém alterou o recurso fora do Terraform (console, CLI, outro script).

**Soluções:**
```bash
# Opção A: Aceitar mudança do Terraform (sobrescrever)
terraform apply   # Volta ao estado do código

# Opção B: Atualizar código para refletir a realidade
# Edite o .tf para incluir a tag manual

# Opção C: Ignorar atributo específico
# lifecycle { ignore_changes = [tags["Manual"]] }

# Opção D: Atualizar state sem mudar infra
terraform refresh   # Deprecated — plan faz isso automaticamente
```

---

### 8. "Terraform plan shows changes every run"

**Causas comuns:**

```hcl
# ❌ timestamp() muda a cada run
tags = {
  UpdatedAt = timestamp()
}

# ✅ Ignore no lifecycle
lifecycle {
  ignore_changes = [tags["UpdatedAt"]]
}
```

```hcl
# ❌ Ordenação de listas não determinística
security_groups = [aws_security_group.a.id, aws_security_group.b.id]

# ✅ Use toset() ou sort()
security_groups = sort([aws_security_group.a.id, aws_security_group.b.id])
```

---

### 9. "Error: Inconsistent dependency lock file"

```
Error: Inconsistent dependency lock file
  The following dependency selections recorded in the lock file are
  inconsistent with the current configuration
```

**Solução:**
```bash
# Atualizar lock file
terraform init -upgrade
# Commitar .terraform.lock.hcl atualizado
```

---

### 10. Destroy acidental — Como recuperar

```bash
# Se tem state versionado no S3:
# 1. Listar versões
aws s3api list-object-versions --bucket meu-state-bucket --prefix path/terraform.tfstate

# 2. Baixar versão anterior
aws s3api get-object --bucket meu-state-bucket --key path/terraform.tfstate --version-id "abc123" recovered.tfstate

# 3. Enviar state recuperado
terraform state push recovered.tfstate

# 4. Verificar
terraform plan
```

---

## Debugging

### Logs detalhados

```bash
# Níveis: TRACE, DEBUG, INFO, WARN, ERROR
export TF_LOG=DEBUG
terraform plan

# Salvar em arquivo
export TF_LOG_PATH="terraform.log"
terraform plan

# Desabilitar
unset TF_LOG TF_LOG_PATH
```

### Plan detalhado

```bash
# Mostra quais atributos mudaram
terraform plan -detailed-exitcode

# Exit codes:
# 0 = no changes
# 1 = error
# 2 = changes pending
```

### Ver state atual

```bash
terraform state list                    # Listar recursos
terraform state show aws_s3_bucket.this  # Ver detalhes
terraform show                           # Ver state completo
```

---

## Comandos de Emergência

```bash
# Backup do state
terraform state pull > backup-$(date +%Y%m%d-%H%M%S).tfstate

# Desbloquear state travado
terraform force-unlock <LOCK_ID>

# Marcar recurso para recriação
terraform taint aws_instance.this          # Deprecated
terraform apply -replace=aws_instance.this  # Preferir este

# Destruir recurso específico (sem destruir tudo)
terraform destroy -target=aws_instance.this
```

---

## Checklist de Troubleshooting

1. [ ] `terraform init` está atualizado?
2. [ ] `terraform validate` passa?
3. [ ] Versão do provider é compatível?
4. [ ] Credenciais AWS estão configuradas?
5. [ ] State está acessível?
6. [ ] Alguém mais está rodando apply?
7. [ ] Houve mudanças manuais (drift)?
8. [ ] O recurso já existe fora do state?

---

## Anterior: [15 — Testing](./15-testing.md) | Início: [README](../README.md)
