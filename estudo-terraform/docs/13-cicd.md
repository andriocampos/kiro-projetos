# 📖 13 — CI/CD com Terraform

## Por que CI/CD para Terraform?

Sem CI/CD:
```
Dev faz mudança → roda terraform apply local → esquece de commitar → ninguém sabe o que mudou
```

Com CI/CD:
```
Dev faz mudança → PR → plan automático → review → merge → apply controlado
```

---

## Workflow Padrão

```
┌────────────┐     ┌────────────┐     ┌────────────┐     ┌────────────┐
│  PR aberto │ ──► │   Plan     │ ──► │  Review    │ ──► │   Apply    │
│            │     │ (automático)│     │ (humano)   │     │ (no merge) │
└────────────┘     └────────────┘     └────────────┘     └────────────┘
```

### Princípios:

1. **Plan em toda PR** — Mostra exatamente o que vai mudar
2. **Nunca apply sem review** — Alguém precisa validar o plan
3. **Apply só após merge** — Branch main é a fonte de verdade
4. **Sem apply local** — Ninguém roda apply da máquina pessoal

---

## GitHub Actions — Exemplo Completo

### .github/workflows/terraform.yml

```yaml
name: Terraform

on:
  pull_request:
    branches: [main]
    paths: ['estudo-terraform/**']
  push:
    branches: [main]
    paths: ['estudo-terraform/**']

permissions:
  contents: read
  pull-requests: write    # Para comentar o plan na PR
  id-token: write         # Para OIDC (sem secrets estáticas)

env:
  TF_DIR: estudo-terraform
  AWS_REGION: us-east-1

jobs:
  terraform-plan:
    name: Plan
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'

    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.9.0

      # Autenticação via OIDC (sem access keys!)
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/terraform-ci
          aws-region: ${{ env.AWS_REGION }}

      - name: Terraform Init
        working-directory: ${{ env.TF_DIR }}
        run: terraform init

      - name: Terraform Validate
        working-directory: ${{ env.TF_DIR }}
        run: terraform validate

      - name: Terraform Plan
        working-directory: ${{ env.TF_DIR }}
        id: plan
        run: terraform plan -no-color -out=tfplan
        continue-on-error: true

      # Comentar plan na PR
      - uses: actions/github-script@v7
        with:
          script: |
            const output = `#### Terraform Plan 📖
            \`\`\`
            ${{ steps.plan.outputs.stdout }}
            \`\`\`
            *Triggered by @${{ github.actor }}*`;
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: output
            })

      - name: Plan Status
        if: steps.plan.outcome == 'failure'
        run: exit 1

  terraform-apply:
    name: Apply
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'

    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.9.0

      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/terraform-ci
          aws-region: ${{ env.AWS_REGION }}

      - name: Terraform Init
        working-directory: ${{ env.TF_DIR }}
        run: terraform init

      - name: Terraform Apply
        working-directory: ${{ env.TF_DIR }}
        run: terraform apply -auto-approve
```

---

## OIDC — Autenticação sem Secrets

Em vez de guardar `AWS_ACCESS_KEY_ID` como secret no GitHub:

```hcl
# Role para o GitHub Actions assumir via OIDC
resource "aws_iam_role" "github_actions" {
  name = "terraform-ci"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${local.account_id}:oidc-provider/token.actions.githubusercontent.com"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:minha-org/meu-repo:*"
        }
      }
    }]
  })
}
```

Benefícios do OIDC:
- ✅ Sem secrets estáticas (sem rotation)
- ✅ Credenciais temporárias
- ✅ Limitado por repo/branch

---

## Proteções Extras

### 1. Require approvals para prod

```yaml
jobs:
  terraform-apply-prod:
    environment: production   # Requer approval no GitHub
    runs-on: ubuntu-latest
```

### 2. Limitar scope por branch

```yaml
# Só aplica em prod a partir de main
if: github.ref == 'refs/heads/main'
```

### 3. Checkov/tfsec — Scan de segurança

```yaml
- name: Security Scan
  uses: bridgecrewio/checkov-action@v12
  with:
    directory: ${{ env.TF_DIR }}
    framework: terraform
```

### 4. terraform fmt — Formatação consistente

```yaml
- name: Terraform Format Check
  run: terraform fmt -check -recursive
```

---

## Ferramentas Complementares

| Ferramenta | O que faz |
|-----------|-----------|
| **Atlantis** | Plan/apply em PRs (self-hosted) |
| **Spacelift** | CI/CD para Terraform (SaaS) |
| **Terraform Cloud** | HashiCorp oficial (SaaS) |
| **Checkov** | Scan de segurança/compliance |
| **tfsec** | Análise de segurança estática |
| **infracost** | Estimativa de custo na PR |
| **terraform-docs** | Gera documentação do módulo |

---

## Exercício Prático

1. Crie `.github/workflows/terraform.yml` no repositório
2. Configure OIDC ou use secrets para autenticação
3. Abra uma PR que altere um resource
4. Veja o plan como comentário na PR
5. Após merge, verifique o apply automático

---

## Anterior: [12 — IAM e Segurança](./12-iam-seguranca.md) | Próximo: [14 — Import e Refactoring](./14-import-refactoring.md)
