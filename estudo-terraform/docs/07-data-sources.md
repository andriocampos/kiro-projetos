# 📖 07 — Data Sources

## O que são Data Sources?

Data sources permitem **consultar informações** de recursos que já existem, sem criá-los ou gerenciá-los. São **read-only**.

```
resource = "Crie isso para mim"
data     = "Me diga informações sobre isso que já existe"
```

---

## Sintaxe

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]   # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Uso: data.<TIPO>.<NOME>.<ATRIBUTO>
resource "aws_instance" "this" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
}
```

---

## Casos de Uso Comuns

### 1. Buscar AMI mais recente

```hcl
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}
```

### 2. Buscar VPC existente

```hcl
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["minha-vpc-producao"]
  }
}

# Usar em security group
resource "aws_security_group" "this" {
  vpc_id = data.aws_vpc.main.id
}
```

### 3. Buscar Availability Zones da região

```hcl
data "aws_availability_zones" "available" {
  state = "available"
}

# Resultado: ["us-east-1a", "us-east-1b", "us-east-1c", ...]
resource "aws_subnet" "this" {
  count             = 2
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = "10.0.${count.index}.0/24"
  vpc_id            = aws_vpc.this.id
}
```

### 4. Buscar Account ID atual

```hcl
data "aws_caller_identity" "current" {}

# Uso em policies
locals {
  account_id = data.aws_caller_identity.current.account_id
}
```

### 5. Buscar região atual

```hcl
data "aws_region" "current" {}

output "region" {
  value = data.aws_region.current.name
}
```

### 6. Referenciar outro state (Remote State)

```hcl
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "meu-state-bucket"
    key    = "networking/terraform.tfstate"
    region = "us-east-1"
  }
}

# Usar output do outro state
resource "aws_instance" "this" {
  subnet_id = data.terraform_remote_state.networking.outputs.subnet_id
}
```

---

## Data Source vs Resource

| Aspecto | Resource | Data Source |
|---------|----------|-------------|
| Cria recurso? | ✅ Sim | ❌ Não |
| Gerencia lifecycle? | ✅ Sim | ❌ Não |
| Aparece no state? | ✅ Sim | ✅ Sim (read-only) |
| Prefixo | `resource` | `data` |
| Referência | `aws_vpc.this.id` | `data.aws_vpc.this.id` |

---

## Quando usar Data Sources

✅ Buscar AMI mais recente automaticamente

✅ Referenciar VPC/Subnet que outro time gerencia

✅ Pegar account ID, região, AZs dinamicamente

✅ Consultar outputs de outro Terraform state

✅ Buscar certificados ACM, hosted zones Route53

❌ **NÃO use** para recursos que VOCÊ deveria gerenciar — crie um `resource`

---

## Exercício Prático

Crie um arquivo `data.tf` no projeto que:
1. Busque as AZs disponíveis na região
2. Busque o account ID atual
3. Busque a AMI mais recente do Amazon Linux 2023
4. Crie um output mostrando cada valor

---

## Anterior: [06 — Outputs e State](./06-outputs-state.md) | Próximo: [08 — Módulos](./08-modulos.md)
