# 📖 15 — Testing

## Por que testar Terraform?

Terraform gerencia infraestrutura real. Um erro pode:
- Derrubar produção
- Expor dados sensíveis
- Gerar custos inesperados

Testes dão confiança para mudar código sem medo.

---

## Níveis de Teste

```
    ┌──────────────────┐
    │  Integration     │  ← Mais lento, mais confiável
    │  (terraform apply)│
    ├──────────────────┤
    │  Contract Tests  │
    │  (terraform test)│
    ├──────────────────┤
    │  Static Analysis │  ← Mais rápido, menos cobertura
    │  (validate, lint)│
    └──────────────────┘
```

---

## Nível 1: Análise Estática (rápido, sem infra)

### terraform validate

```bash
terraform validate
# Success! The configuration is valid.
```

Verifica: sintaxe, tipos, referências quebradas. NÃO consulta APIs.

### terraform fmt

```bash
# Verificar formatação (CI)
terraform fmt -check -recursive

# Formatar automaticamente
terraform fmt -recursive
```

### tflint — Linter para Terraform

```bash
# Instalar
brew install tflint   # macOS
# ou
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Rodar
tflint --init
tflint
```

`.tflint.hcl`:
```hcl
plugin "aws" {
  enabled = true
  version = "0.30.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

rule "terraform_naming_convention" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}
```

### Checkov / tfsec — Segurança

```bash
# Checkov
pip install checkov
checkov -d .

# tfsec
brew install tfsec
tfsec .
```

Detecta: buckets públicos, encryption faltando, security groups abertos, etc.

---

## Nível 2: Terraform Test Framework (1.6+)

O framework nativo de testes do Terraform.

### Estrutura

```
projeto/
├── main.tf
├── variables.tf
├── outputs.tf
└── tests/
    ├── basic.tftest.hcl
    └── validation.tftest.hcl
```

### Teste básico

**tests/basic.tftest.hcl**
```hcl
# Variáveis para o teste
variables {
  project_name = "test-project"
  environment  = "dev"
}

# Teste que roda apenas plan (rápido, sem criar nada)
run "plan_creates_bucket" {
  command = plan

  assert {
    condition     = aws_s3_bucket.this.bucket == "test-project-dev-artifacts"
    error_message = "Bucket name incorreto"
  }
}

# Teste que roda apply (cria infra real temporária)
run "apply_creates_bucket" {
  command = apply

  assert {
    condition     = aws_s3_bucket.this.id != ""
    error_message = "Bucket não foi criado"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.block_public_acls == true
    error_message = "Bucket deve bloquear acesso público"
  }
}
```

### Rodar testes:

```bash
terraform test
# tests/basic.tftest.hcl... pass
#   run "plan_creates_bucket"... pass
#   run "apply_creates_bucket"... pass
```

### Teste de validação de variáveis

**tests/validation.tftest.hcl**
```hcl
# Testar que validações rejeitam valores inválidos
run "rejects_invalid_environment" {
  command = plan

  variables {
    environment = "invalid"
  }

  expect_failures = [
    var.environment   # Espera que esta variável falhe na validação
  ]
}

run "rejects_uppercase_project" {
  command = plan

  variables {
    project_name = "UPPERCASE"
  }

  expect_failures = [
    var.project_name
  ]
}
```

### Teste de módulo com mock

```hcl
# Testar módulo isoladamente
run "module_creates_resources" {
  command = apply

  module {
    source = "./modules/s3-bucket"
  }

  variables {
    bucket_name       = "test-bucket-${run.id}"
    environment       = "test"
    enable_versioning = true
  }

  assert {
    condition     = output.bucket_arn != ""
    error_message = "Módulo deve retornar ARN"
  }
}
```

---

## Nível 3: Testes de Integração (Terratest)

Para testes mais complexos em Go:

```go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestS3Bucket(t *testing.T) {
    opts := &terraform.Options{
        TerraformDir: "../estudo-terraform",
        Vars: map[string]interface{}{
            "environment":  "test",
            "project_name": "terratest",
        },
    }

    // Cleanup após teste
    defer terraform.Destroy(t, opts)

    // Cria infra real
    terraform.InitAndApply(t, opts)

    // Verifica outputs
    bucketName := terraform.Output(t, opts, "bucket_name")
    assert.Contains(t, bucketName, "terratest")
}
```

---

## Estratégia de Testes Recomendada

| Nível | Quando rodar | Tempo | O que testa |
|-------|-------------|-------|-------------|
| `fmt + validate` | Todo commit | 5s | Sintaxe básica |
| `tflint` | Todo commit | 10s | Convenções, erros comuns |
| `checkov/tfsec` | Toda PR | 30s | Segurança |
| `terraform test` (plan) | Toda PR | 1-2min | Lógica, outputs |
| `terraform test` (apply) | Pre-merge/nightly | 5-10min | Infra real temporária |
| Terratest | Release | 10-30min | Integração completa |

---

## Exercício Prático

1. Rode `terraform validate` e `terraform fmt -check`
2. Instale tflint e rode no projeto
3. Crie `tests/basic.tftest.hcl` com um teste de plan
4. Crie um teste que valida rejeição de environment inválido
5. Rode `terraform test`

---

## Anterior: [14 — Import e Refactoring](./14-import-refactoring.md) | Próximo: [16 — Troubleshooting](./16-troubleshooting.md)
