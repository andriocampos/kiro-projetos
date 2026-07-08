# 📖 02 — Estrutura de Projeto

## Por que a estrutura importa?

A organização dos arquivos `.tf` é a **primeira decisão arquitetural** do seu projeto. Errar aqui custa caro depois — refatorar Terraform com state existente é complexo.

> 90% dos projetos que viram "legado difícil" erraram na estrutura logo no início.

---

## A Estrutura Padrão (Single Module)

```
projeto-terraform/
├── providers.tf       # Providers e versões
├── variables.tf       # Todas as variáveis (inputs)
├── locals.tf          # Valores computados
├── main.tf            # Recursos principais
├── outputs.tf         # Valores expostos
├── terraform.tfvars   # Valores das variáveis
├── .gitignore         # State e cache ignorados
└── .terraform.lock.hcl # Lock de versões (COMMITAR!)
```

---

## Regras de Separação

### 1. Um tipo de configuração por arquivo

| Arquivo | Contém APENAS |
|---------|---------------|
| `providers.tf` | Blocos `terraform {}` e `provider {}` |
| `variables.tf` | Blocos `variable {}` |
| `locals.tf` | Bloco `locals {}` |
| `outputs.tf` | Blocos `output {}` |
| `main.tf` | Blocos `resource {}` e `data {}` |

### 2. Quando main.tf fica grande demais

Se `main.tf` passar de ~100 linhas, quebre por **domínio**:

```
├── networking.tf      # VPC, subnets, route tables, security groups
├── compute.tf         # EC2, ASG, Launch Templates
├── storage.tf         # S3, EFS, EBS
├── database.tf        # RDS, DynamoDB
├── iam.tf             # Roles, policies, users
├── monitoring.tf      # CloudWatch, SNS
```

### 3. A regra: agrupe pelo que MUDA junto

Se mexer no security group sempre implica mexer na EC2, eles ficam no mesmo arquivo.

---

## Convenções de Naming

### Resources

```hcl
# Quando existe APENAS UM do tipo no projeto:
resource "aws_s3_bucket" "this" { }

# Quando existem VÁRIOS do tipo:
resource "aws_s3_bucket" "logs" { }
resource "aws_s3_bucket" "artifacts" { }
```

### Variáveis

```hcl
variable "vpc_cidr" { }          # Boa - específica
variable "database_name" { }     # Boa - específica
variable "name" { }              # Ruim - genérica demais
```

---

## Estrutura para Múltiplos Ambientes

### Abordagem 1: Diretórios separados (recomendada)

```
projeto/
├── modules/
│   └── app/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   └── prod/
```

### Abordagem 2: Workspaces

```bash
terraform workspace select dev
terraform apply -var-file="environments/dev.tfvars"
```

| Critério | Diretórios | Workspaces |
|----------|-----------|------------|
| Ambientes muito diferentes | ✅ | ❌ |
| Ambientes quase iguais | ❌ | ✅ |
| Time grande | ✅ | ❌ |

---

## O que NÃO fazer

❌ Um arquivo gigante com 500 linhas

❌ Misturar provider junto com resources

❌ Nomes genéricos: `resource "aws_instance" "instance1"`

❌ Hardcoded values direto no resource

❌ Copiar/colar entre ambientes — Use módulos

---

## Anterior: [01 — Fundamentos](./01-fundamentos.md) | Próximo: [03 — Providers](./03-providers.md)
