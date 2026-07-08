# 📖 08 — Módulos

## O que é um Módulo?

Um módulo é um **container reutilizável** de resources Terraform. Qualquer diretório com arquivos `.tf` é tecnicamente um módulo.

```
Módulo = Função em programação
  - Recebe inputs (variables)
  - Faz algo (resources)
  - Retorna outputs
```

### Por que usar módulos?

1. **DRY** — Não repetir código entre ambientes
2. **Abstração** — Esconder complexidade
3. **Padrões** — Forçar boas práticas (tags, segurança)
4. **Composição** — Montar infraestrutura como Lego
5. **Testabilidade** — Testar pedaços isolados

---

## Estrutura de um Módulo

```
modules/
└── s3-bucket/
    ├── main.tf          # Resources
    ├── variables.tf     # Inputs do módulo
    ├── outputs.tf       # O que o módulo expõe
    └── README.md        # Documentação
```

### Exemplo: Módulo de S3 Bucket

**modules/s3-bucket/variables.tf**
```hcl
variable "bucket_name" {
  description = "Nome do bucket"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "enable_versioning" {
  description = "Habilitar versionamento"
  type        = bool
  default     = true
}
```

**modules/s3-bucket/main.tf**
```hcl
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  tags   = { Environment = var.environment }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

**modules/s3-bucket/outputs.tf**
```hcl
output "bucket_id" {
  description = "ID do bucket"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN do bucket"
  value       = aws_s3_bucket.this.arn
}
```

---

## Chamando um Módulo

```hcl
# No seu main.tf principal:
module "logs_bucket" {
  source = "./modules/s3-bucket"

  bucket_name       = "${local.name_prefix}-logs"
  environment       = var.environment
  enable_versioning = true
}

module "artifacts_bucket" {
  source = "./modules/s3-bucket"

  bucket_name       = "${local.name_prefix}-artifacts"
  environment       = var.environment
  enable_versioning = false
}

# Acessar outputs do módulo:
output "logs_bucket_arn" {
  value = module.logs_bucket.bucket_arn
}
```

---

## Fontes de Módulos (source)

```hcl
# Local (pasta no mesmo repo)
module "vpc" {
  source = "./modules/vpc"
}

# GitHub
module "vpc" {
  source = "github.com/minha-org/terraform-modules//vpc?ref=v1.2.0"
}

# Terraform Registry (público)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
}

# S3
module "vpc" {
  source = "s3::https://s3.amazonaws.com/meu-bucket/modules/vpc.zip"
}
```

---

## Quando criar um módulo?

### ✅ Crie quando:
- O mesmo grupo de resources se repete 3+ vezes
- Quer forçar um padrão (ex: bucket SEMPRE com encryption)
- Quer esconder complexidade de quem consome
- Quer versionar independentemente

### ❌ NÃO crie quando:
- Só tem 1 resource — overengineering
- Só usa uma vez — premature abstraction
- Está começando — domine o básico antes

---

## Boas Práticas

1. **Nomeie como `terraform-<PROVIDER>-<NOME>`** — Convenção do registry
2. **Exponha o mínimo necessário** — Nem todo atributo vira output
3. **Use defaults sensatos** — Seguro por padrão
4. **Versione com tags git** — `v1.0.0`, `v1.1.0`
5. **Documente com README** — Inputs, outputs e exemplos
6. **Não hardcode provider** — Herde do root module

---

## Composição de Módulos

```hcl
module "networking" {
  source      = "./modules/networking"
  environment = var.environment
  vpc_cidr    = "10.0.0.0/16"
}

module "database" {
  source    = "./modules/database"
  subnet_ids = module.networking.private_subnet_ids
  vpc_id     = module.networking.vpc_id
}

module "app" {
  source       = "./modules/app"
  subnet_ids   = module.networking.public_subnet_ids
  database_url = module.database.connection_string
}
```

---

## Exercício Prático

1. Crie um módulo em `modules/s3-bucket/` com:
   - Input: nome, environment, enable_versioning
   - Segurança: public access block obrigatório
   - Output: id e arn
2. Chame o módulo 2x no `main.tf` (logs + artifacts)
3. Rode `terraform plan` e veja os resources prefixados com `module.`

---

## Anterior: [07 — Data Sources](./07-data-sources.md) | Próximo: [09 — Expressions e Funções](./09-expressions-funcoes.md)
