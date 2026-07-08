# 📖 10 — Ambientes (dev/staging/prod)

## O Problema

Você tem o mesmo código Terraform mas precisa rodar em ambientes diferentes:
- **dev**: instâncias pequenas, poucos recursos
- **staging**: similar à prod, para testes
- **prod**: HA, multi-AZ, monitoramento total

Como separar sem duplicar código?

---

## Abordagem 1: Var-files por Ambiente (Simples)

A mais simples — mesmo código, diferentes valores.

### Estrutura

```
projeto/
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
├── environments/
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
└── backend/
    ├── dev.hcl
    ├── staging.hcl
    └── prod.hcl
```

### environments/dev.tfvars
```hcl
environment    = "dev"
instance_type  = "t3.micro"
instance_count = 1
multi_az       = false
enable_backup  = false
```

### environments/prod.tfvars
```hcl
environment    = "prod"
instance_type  = "t3.large"
instance_count = 3
multi_az       = true
enable_backup  = true
```

### Uso:
```bash
# Dev
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"

# Prod
terraform plan -var-file="environments/prod.tfvars"
terraform apply -var-file="environments/prod.tfvars"
```

### Backend separado por ambiente:

**backend/dev.hcl**
```hcl
bucket         = "minha-empresa-tfstate"
key            = "projeto/dev/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-locks"
encrypt        = true
```

```bash
terraform init -backend-config="backend/dev.hcl"
```

---

## Abordagem 2: Workspaces

Workspaces criam states separados com o mesmo código.

```bash
# Criar workspaces
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Listar
terraform workspace list

# Mudar
terraform workspace select dev
```

### Usando workspace no código:

```hcl
locals {
  environment = terraform.workspace

  config = {
    dev = {
      instance_type  = "t3.micro"
      instance_count = 1
    }
    staging = {
      instance_type  = "t3.small"
      instance_count = 2
    }
    prod = {
      instance_type  = "t3.large"
      instance_count = 3
    }
  }

  current = local.config[local.environment]
}

resource "aws_instance" "this" {
  count         = local.current.instance_count
  instance_type = local.current.instance_type
  # ...
}
```

### Prós e contras:

| ✅ Prós | ❌ Contras |
|---------|-----------|
| Um único diretório | Fácil aplicar no workspace errado |
| Simples para ambientes iguais | Config fica no código (não em tfvars) |
| State isolado por workspace | Dificil ter infra DIFERENTE por ambiente |

---

## Abordagem 3: Diretórios por Ambiente + Módulos (Recomendada)

A mais robusta para times e produção.

### Estrutura

```
projeto/
├── modules/
│   ├── networking/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── compute/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── database/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── providers.tf
│   ├── staging/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── providers.tf
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       └── providers.tf
```

### environments/dev/main.tf

```hcl
module "networking" {
  source = "../../modules/networking"

  environment = var.environment
  vpc_cidr    = "10.0.0.0/16"
  azs         = ["us-east-1a"]   # Dev: 1 AZ
}

module "compute" {
  source = "../../modules/compute"

  environment   = var.environment
  instance_type = "t3.micro"
  min_size      = 1
  max_size      = 1
  subnet_ids    = module.networking.private_subnet_ids
}

# Dev não tem database dedicada (usa RDS serverless)
```

### environments/prod/main.tf

```hcl
module "networking" {
  source = "../../modules/networking"

  environment = var.environment
  vpc_cidr    = "10.0.0.0/16"
  azs         = ["us-east-1a", "us-east-1b", "us-east-1c"]  # Prod: 3 AZs
}

module "compute" {
  source = "../../modules/compute"

  environment   = var.environment
  instance_type = "t3.large"
  min_size      = 3
  max_size      = 10
  subnet_ids    = module.networking.private_subnet_ids
}

module "database" {
  source = "../../modules/database"

  environment    = var.environment
  instance_class = "db.r5.large"
  multi_az       = true
  subnet_ids     = module.networking.database_subnet_ids
}
```

---

## Comparação Final

| Critério | Var-files | Workspaces | Diretórios + Módulos |
|----------|-----------|-----------|---------------------|
| Simplicidade | ✅✅ | ✅ | ⚠️ |
| Ambientes diferentes | ⚠️ | ❌ | ✅✅ |
| Segurança (isolamento) | ⚠️ | ✅ | ✅✅ |
| CI/CD | ✅ | ⚠️ | ✅✅ |
| Time grande | ⚠️ | ❌ | ✅✅ |
| Projetos pequenos | ✅✅ | ✅ | ❌ (overkill) |

### Minha recomendação:

- **Estudo/pessoal**: Var-files
- **Startup/time pequeno**: Var-files ou Workspaces
- **Empresa/produção séria**: Diretórios + Módulos

---

## Exercício Prático

1. Crie `environments/dev.tfvars` e `environments/prod.tfvars`
2. Use condicionais no código para variar resources por ambiente
3. Rode `terraform plan -var-file=environments/dev.tfvars`
4. Compare com `terraform plan -var-file=environments/prod.tfvars`

---

## Anterior: [09 — Expressions e Funções](./09-expressions-funcoes.md) | Próximo: [11 — Backend Remoto](./11-backend-remoto.md)
