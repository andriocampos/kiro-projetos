# 📖 04 — Variables e Locals

## Variables (Inputs)

Variables são os **parâmetros de entrada** do seu código Terraform.

### Anatomia de uma Variable

```hcl
variable "nome_da_variavel" {
  description = "Explicação do que ela faz"
  type        = string
  default     = "valor-padrao"
  sensitive   = false
  nullable    = true

  validation {
    condition     = length(var.nome_da_variavel) > 3
    error_message = "Deve ter mais de 3 caracteres."
  }
}
```

---

## Sistema de Tipos

### Primitivos

| Tipo | Exemplo | Uso |
|------|---------|-----|
| `string` | `"us-east-1"` | Textos, nomes |
| `number` | `3`, `1.5` | Contagens |
| `bool` | `true`, `false` | Flags |

### Complexos

```hcl
# Lista
variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

# Mapa
variable "instance_sizes" {
  type = map(string)
  default = {
    dev  = "t3.micro"
    prod = "t3.medium"
  }
}

# Objeto (struct tipada)
variable "database_config" {
  type = object({
    engine         = string
    instance_class = string
    multi_az       = bool
  })
}
```

---

## Ordem de Precedência (menor → maior)

```
1. default no bloco variable
2. terraform.tfvars
3. *.auto.tfvars (ordem alfabética)
4. -var-file="arquivo.tfvars"
5. -var="key=value" na CLI
6. TF_VAR_nome (environment variable)  ← VENCE
```

---

## Validations (Fail Fast)

```hcl
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment deve ser: dev, staging ou prod."
  }
}

variable "instance_type" {
  type = string
  validation {
    condition     = can(regex("^t[23]\\.", var.instance_type))
    error_message = "Apenas instâncias t2.* ou t3.* permitidas."
  }
}
```

---

## Sensitive Variables

```hcl
variable "database_password" {
  type      = string
  sensitive = true   # Oculta do plan/apply
}
```

> ⚠️ `sensitive = true` NÃO criptografa — apenas oculta do terminal. Valor fica no state em plain text!

---

## Locals (Valores Computados)

### Variable vs Local

| Critério | Variable | Local |
|----------|----------|-------|
| Quem define? | Usuário externo | Lógica interna |
| É input? | Sim | Não |
| Pode ter validation? | Sim | Não |

**Regra**: Variable = varia entre deploys. Local = derivado/calculado.

### Exemplos

```hcl
locals {
  name_prefix   = "${var.project_name}-${var.environment}"
  is_production = var.environment == "prod"
  instance_type = local.is_production ? "t3.large" : "t3.micro"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
```

---

## Anti-patterns

❌ Local onde deveria ser variable:
```hcl
locals { region = "us-east-1" }   # Isso muda! Deveria ser variable
```

❌ Variable onde deveria ser local:
```hcl
variable "name_prefix" { default = "projeto-dev" }  # É calculado!
```

❌ Variable sem tipo:
```hcl
variable "count" { }   # Aceita qualquer coisa — perigoso
```

---

## Dicas de Senior

1. **Sempre `description`** — Documentação viva
2. **Sempre `type`** — Fail fast
3. **Use `validation`** — Protege contra erros humanos
4. **Não exagere em locals** — Se só usa uma vez, não precisa
5. **Prefira `terraform.tfvars`** — Versionável e auditável

---

---

## Exercício Prático

1. Crie variáveis com tipos: `string`, `number`, `bool`, `list(string)`, `map(string)`, `object`
2. Adicione `validation` na variável de environment (aceitar só dev/staging/prod)
3. Adicione `validation` em um CIDR block usando `can(cidrhost(...))`
4. Crie um `terraform.tfvars` com valores e rode `terraform plan`
5. Sobrescreva uma variável via CLI: `terraform plan -var="environment=prod"`
6. Sobrescreva via env var: `export TF_VAR_environment="staging"` e veja qual vence
7. Crie locals que derivem: `name_prefix`, `is_production`, e `instance_type` condicional

---

## Anterior: [03 — Providers](./03-providers.md) | Próximo: [05 — Resources](./05-resources.md)
