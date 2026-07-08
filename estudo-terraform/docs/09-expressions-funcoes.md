# 📖 09 — Expressions e Funções

## Expressions no HCL

Expressions são qualquer trecho de código que produz um valor. Vão além de simples strings.

---

## Interpolação e Referências

```hcl
# Interpolação de string
name = "bucket-${var.environment}-${var.project}"

# Referência direta (sem interpolação quando é o valor inteiro)
region = var.aws_region    # ✅ Correto
region = "${var.aws_region}"  # ❌ Desnecessário
```

---

## Operadores

```hcl
# Aritméticos
locals {
  total = 2 + 3        # 5
  diff  = 10 - 4       # 6
  prod  = 3 * 2        # 6
  div   = 10 / 3       # 3.333...
  mod   = 10 % 3       # 1
}

# Comparação
locals {
  is_prod = var.environment == "prod"
  is_big  = var.instance_count > 5
}

# Lógicos
locals {
  needs_ha = var.environment == "prod" && var.multi_az
  any_flag = var.enable_a || var.enable_b
  negation = !var.is_disabled
}
```

---

## Condicionais (Ternário)

```hcl
# condition ? valor_se_true : valor_se_false

locals {
  instance_type = var.environment == "prod" ? "t3.large" : "t3.micro"
  multi_az      = var.environment == "prod" ? true : false
  replica_count = var.environment == "prod" ? 3 : 1
}

# Criar ou não criar um resource
resource "aws_cloudwatch_log_group" "this" {
  count = var.enable_logging ? 1 : 0
  name  = "/app/${var.project_name}"
}
```

---

## For Expressions

### Transformar listas

```hcl
variable "names" {
  default = ["alice", "bob", "carol"]
}

locals {
  # Lista → Lista transformada
  upper_names = [for name in var.names : upper(name)]
  # Resultado: ["ALICE", "BOB", "CAROL"]

  # Lista com filtro
  long_names = [for name in var.names : name if length(name) > 3]
  # Resultado: ["alice", "carol"]
}
```

### Transformar maps

```hcl
variable "users" {
  default = {
    alice = { role = "admin" }
    bob   = { role = "dev" }
    carol = { role = "admin" }
  }
}

locals {
  # Map → Map transformado
  user_roles = { for name, config in var.users : name => config.role }
  # Resultado: { alice = "admin", bob = "dev", carol = "admin" }

  # Filtrar map
  admins = { for name, config in var.users : name => config if config.role == "admin" }
  # Resultado: { alice = { role = "admin" }, carol = { role = "admin" } }
}
```

---

## Splat Expressions

Atalho para acessar atributos de listas:

```hcl
# Sem splat (verboso)
output "instance_ids" {
  value = [for instance in aws_instance.servers : instance.id]
}

# Com splat (conciso)
output "instance_ids" {
  value = aws_instance.servers[*].id
}
```

---

## Funções Built-in Mais Usadas

### Strings

```hcl
locals {
  lower    = lower("HELLO")              # "hello"
  upper    = upper("hello")              # "HELLO"
  trim     = trimspace("  hello  ")      # "hello"
  replace  = replace("hello-world", "-", "_")  # "hello_world"
  substr   = substr("hello", 0, 3)       # "hel"
  format   = format("Hello, %s!", "World")  # "Hello, World!"
  join     = join(", ", ["a", "b", "c"]) # "a, b, c"
  split    = split(",", "a,b,c")         # ["a", "b", "c"]
}
```

### Coleções

```hcl
locals {
  # Listas
  length   = length(["a", "b", "c"])     # 3
  concat   = concat(["a"], ["b", "c"])   # ["a", "b", "c"]
  flatten  = flatten([["a"], ["b", "c"]])  # ["a", "b", "c"]
  distinct = distinct(["a", "b", "a"])   # ["a", "b"]
  sort     = sort(["c", "a", "b"])       # ["a", "b", "c"]
  contains = contains(["a", "b"], "a")   # true
  element  = element(["a", "b", "c"], 1) # "b"
  slice    = slice(["a", "b", "c", "d"], 1, 3)  # ["b", "c"]

  # Maps
  keys     = keys({ a = 1, b = 2 })     # ["a", "b"]
  values   = values({ a = 1, b = 2 })   # [1, 2]
  lookup   = lookup({ a = 1 }, "a", 0)  # 1 (default = 0)
  merge    = merge({ a = 1 }, { b = 2 })  # { a = 1, b = 2 }
}
```

### Numéricas

```hcl
locals {
  min_val = min(1, 5, 3)     # 1
  max_val = max(1, 5, 3)     # 5
  abs_val = abs(-10)          # 10
  ceil_v  = ceil(4.3)         # 5
  floor_v = floor(4.9)        # 4
}
```

### Encoding

```hcl
locals {
  json    = jsonencode({ name = "test", count = 3 })
  decoded = jsondecode("{\"name\": \"test\"}")
  b64     = base64encode("hello")
  b64dec  = base64decode("aGVsbG8=")
}
```

### Filesystem

```hcl
locals {
  # Ler arquivo (útil para policies JSON, scripts, etc.)
  policy = file("${path.module}/policies/s3-policy.json")

  # Renderizar template
  user_data = templatefile("${path.module}/scripts/init.sh", {
    environment = var.environment
    region      = var.aws_region
  })
}
```

### Type checking

```hcl
locals {
  # can() — retorna true se a expressão NÃO der erro
  is_valid_cidr = can(cidrhost("10.0.0.0/16", 0))

  # try() — retorna primeiro valor que não dá erro
  name = try(var.custom_name, "${var.project}-default")

  # coalesce() — retorna primeiro não-vazio
  region = coalesce(var.override_region, "us-east-1")
}
```

---

## Exemplos Práticos do Dia-a-dia

### Criar subnets dinamicamente

```hcl
variable "subnet_cidrs" {
  default = {
    public-a  = "10.0.1.0/24"
    public-b  = "10.0.2.0/24"
    private-a = "10.0.10.0/24"
    private-b = "10.0.11.0/24"
  }
}

resource "aws_subnet" "this" {
  for_each          = var.subnet_cidrs
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = contains(split("-", each.key), "a") ? "us-east-1a" : "us-east-1b"

  tags = { Name = each.key }
}
```

### Gerar policy JSON dinamicamente

```hcl
data "aws_iam_policy_document" "s3_read" {
  statement {
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*"
    ]
  }
}
```

---

## Exercício Prático

1. Crie um `locals.tf` que use `for` para gerar um map de tags a partir de uma lista
2. Use `templatefile` para renderizar um user_data script
3. Use `can()` e `validation` juntos para validar um CIDR
4. Crie 3 subnets com `for_each` e nomes derivados com `format()`

---

## Anterior: [08 — Módulos](./08-modulos.md) | Próximo: [10 — Ambientes](./10-ambientes.md)
