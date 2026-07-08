# 📖 05 — Resources

## O que é um Resource?

Um resource é a **unidade fundamental** do Terraform. Cada bloco `resource` declara um objeto de infraestrutura que o Terraform vai criar e gerenciar.

```hcl
resource "aws_s3_bucket" "meu_bucket" {
  bucket = "nome-unico-global"
}
```

Anatomia: `resource "<PROVIDER_TIPO>" "<NOME_LOGICO>"`
- **PROVIDER_TIPO**: `aws_s3_bucket` (provider_recurso)
- **NOME_LOGICO**: `meu_bucket` (identificador no código, não na AWS)

---

## Referenciando Resources

```hcl
resource "aws_s3_bucket" "logs" {
  bucket = "meus-logs"
}

# Referência: <tipo>.<nome>.<atributo>
resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id    # ← referência
}
```

O Terraform usa referências para construir o **grafo de dependências** e saber a ordem de criação.

---

## Meta-Arguments

Meta-arguments são argumentos especiais disponíveis em QUALQUER resource:

### depends_on — Dependência explícita

```hcl
resource "aws_s3_bucket" "this" {
  bucket = "meu-bucket"
}

resource "aws_instance" "this" {
  ami           = "ami-12345"
  instance_type = "t3.micro"

  # Força: crie o bucket ANTES da instância
  depends_on = [aws_s3_bucket.this]
}
```

> Use `depends_on` apenas quando a dependência NÃO é visível por referência. Na maioria dos casos, referências implícitas bastam.

### count — Criar N cópias

```hcl
variable "bucket_count" {
  default = 3
}

resource "aws_s3_bucket" "multi" {
  count  = var.bucket_count
  bucket = "bucket-${count.index}"  # bucket-0, bucket-1, bucket-2
}

# Referência: aws_s3_bucket.multi[0].id
```

### for_each — Criar baseado em map/set

```hcl
variable "buckets" {
  default = {
    logs      = "meu-projeto-logs"
    artifacts = "meu-projeto-artifacts"
    backups   = "meu-projeto-backups"
  }
}

resource "aws_s3_bucket" "this" {
  for_each = var.buckets
  bucket   = each.value

  tags = { Name = each.key }
}

# Referência: aws_s3_bucket.this["logs"].id
```

### count vs for_each

| Critério | count | for_each |
|----------|-------|----------|
| Baseado em | Número | Map ou Set |
| Identificador | Índice [0,1,2] | Chave ["logs"] |
| Remover item do meio | ⚠️ Recria tudo após | ✅ Remove só aquele |
| **Recomendação** | Simples on/off | ✅ **Preferir sempre** |

---

## Lifecycle — Controlar comportamento

```hcl
resource "aws_instance" "this" {
  ami           = "ami-12345"
  instance_type = "t3.micro"

  lifecycle {
    # Não destruir antes de criar o novo (zero downtime)
    create_before_destroy = true

    # Ignorar mudanças feitas fora do Terraform
    ignore_changes = [tags, ami]

    # IMPEDIR destruição acidental (banco de dados!)
    prevent_destroy = true
  }
}
```

### Quando usar cada um:

| Lifecycle | Caso de uso |
|-----------|------------|
| `create_before_destroy` | Resources com downtime (ASG, DNS) |
| `ignore_changes` | Tags gerenciadas por outro sistema |
| `prevent_destroy` | Databases, buckets com dados |

---

## Provisioners (Use com cautela)

```hcl
resource "aws_instance" "this" {
  ami           = "ami-12345"
  instance_type = "t3.micro"

  # Executar comando DEPOIS de criar
  provisioner "remote-exec" {
    inline = ["sudo apt update"]
  }

  # Executar comando LOCAL após criar
  provisioner "local-exec" {
    command = "echo ${self.public_ip} >> hosts.txt"
  }
}
```

> ⚠️ **Provisioners são último recurso.** Prefira user_data, AMIs pré-configuradas, ou ferramentas como Ansible.

---

## Data Sources — Consultar sem criar

```hcl
# Busca a AMI mais recente do Ubuntu
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "this" {
  ami = data.aws_ami.ubuntu.id   # Usa o resultado do data source
}
```

Data sources são **read-only** — consultam informação sem gerenciar o recurso.

---

## Boas Práticas em Resources

1. **Bloqueie acesso público por padrão** — Abrir é decisão consciente
2. **Use `for_each` sobre `count`** — Mais seguro para adições/remoções
3. **Separe configurações** — Bucket + versioning + policy em resources distintos
4. **`prevent_destroy` em dados** — RDS, DynamoDB, S3 com dados
5. **Naming consistente** — `"this"` para singleton, nome descritivo para múltiplos

---

## Anterior: [04 — Variables e Locals](./04-variables-locals.md) | Próximo: [06 — Outputs e State](./06-outputs-state.md)
