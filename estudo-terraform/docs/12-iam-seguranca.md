# 📖 12 — IAM e Segurança

## Princípio: Least Privilege

> Conceda apenas as permissões MÍNIMAS necessárias, pelo MENOR tempo possível.

Se um serviço precisa ler de um bucket, ele NÃO precisa de `s3:*`. Precisa de `s3:GetObject` naquele bucket específico.

---

## IAM no Terraform — Conceitos

| Componente | O que é | Analogia |
|-----------|---------|----------|
| **User** | Identidade com credenciais | Pessoa |
| **Group** | Agrupamento de users | Departamento |
| **Role** | Identidade assumível por serviços | Crachá temporário |
| **Policy** | Documento JSON de permissões | Lista de acessos |
| **Instance Profile** | Wrapper de Role para EC2 | Crachá preso na máquina |

---

## Criando IAM Roles (Forma Correta)

### Role para EC2

```hcl
# 1. Trust Policy — QUEM pode assumir a role
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# 2. A Role em si
resource "aws_iam_role" "app" {
  name               = "${local.name_prefix}-app-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

# 3. Permission Policy — O QUE a role pode fazer
data "aws_iam_policy_document" "app_permissions" {
  # Ler objetos de um bucket específico
  statement {
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = [
      aws_s3_bucket.app_data.arn,
      "${aws_s3_bucket.app_data.arn}/*"
    ]
  }

  # Escrever logs no CloudWatch
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:log-group:/app/*"]
  }
}

# 4. Anexar policy à role
resource "aws_iam_role_policy" "app" {
  name   = "app-permissions"
  role   = aws_iam_role.app.id
  policy = data.aws_iam_policy_document.app_permissions.json
}

# 5. Instance Profile (necessário para EC2)
resource "aws_iam_instance_profile" "app" {
  name = "${local.name_prefix}-app-profile"
  role = aws_iam_role.app.name
}
```

---

## Data Source `aws_iam_policy_document` vs JSON

### ✅ Recomendado: Data Source

```hcl
data "aws_iam_policy_document" "example" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]
  }
}
```

### ❌ Evitar: JSON inline

```hcl
resource "aws_iam_role_policy" "example" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "s3:GetObject"
      Resource = "${aws_s3_bucket.this.arn}/*"
    }]
  })
}
```

**Por que data source é melhor?**
- Terraform valida a sintaxe
- Pode interpolar references
- Pode combinar múltiplos documents
- Mais legível

---

## Segurança de Secrets

### Regra: Nunca hardcode secrets no código

```hcl
# ❌ CRIME
variable "db_password" {
  default = "minha-senha-123"
}

# ✅ CORRETO — sem default, obriga passar externamente
variable "db_password" {
  type      = string
  sensitive = true
}
```

### Formas de passar secrets:

```bash
# 1. Environment variable (CI/CD)
export TF_VAR_db_password="senha-segura"

# 2. Arquivo tfvars NÃO commitado
echo 'db_password = "senha"' > secret.tfvars
terraform apply -var-file="secret.tfvars"

# 3. AWS Secrets Manager (melhor)
```

### Usando Secrets Manager:

```hcl
# Criar o secret
resource "aws_secretsmanager_secret" "db_password" {
  name = "${local.name_prefix}/db-password"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password
}

# Ler um secret existente (outro projeto/time criou)
data "aws_secretsmanager_secret_version" "api_key" {
  secret_id = "prod/api-key"
}

locals {
  api_key = data.aws_secretsmanager_secret_version.api_key.secret_string
}
```

---

## Sensitive Outputs

```hcl
output "db_endpoint" {
  value = aws_db_instance.this.endpoint
}

output "db_password" {
  value     = aws_db_instance.this.password
  sensitive = true  # Não aparece no terminal
}
```

> Mesmo com `sensitive = true`, o valor fica no state. Por isso remote state com encryption é obrigatório.

---

## Boas Práticas de Segurança

1. **Roles > Users** — Serviços usam roles, nunca access keys
2. **Policies específicas** — Nunca `"*"` em actions ou resources
3. **Conditions** — Restrinja por IP, VPC, ou tags quando possível
4. **`sensitive = true`** — Em toda variable/output com secrets
5. **Secrets Manager/SSM** — Nunca secrets em tfvars commitados
6. **State encriptado** — KMS no backend S3
7. **MFA em operações destrutivas** — Policy com condition MFA
8. **Auditoria** — CloudTrail habilitado para IAM changes

---

## Exemplo: Policy com Conditions

```hcl
data "aws_iam_policy_document" "restricted" {
  statement {
    actions   = ["s3:*"]
    resources = ["${aws_s3_bucket.this.arn}/*"]

    # Só permite de dentro da VPC
    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpc"
      values   = [aws_vpc.this.id]
    }
  }
}
```

---

## Exercício Prático

1. Crie uma Role para EC2 com acesso read-only a um bucket específico
2. Use `aws_iam_policy_document` (não JSON inline)
3. Crie um secret no Secrets Manager via Terraform
4. Marque a variable do secret como `sensitive = true`
5. Verifique que `terraform plan` mostra `(sensitive value)`

---

## Anterior: [11 — Backend Remoto](./11-backend-remoto.md) | Próximo: [13 — CI/CD](./13-cicd.md)
