# 🏗️ Estudo Terraform — Do Fundamento à Produção

## O que é Terraform?

Terraform é uma ferramenta de **Infrastructure as Code (IaC)** criada pela HashiCorp que permite definir, provisionar e gerenciar infraestrutura de forma declarativa usando a linguagem **HCL (HashiCorp Configuration Language)**.

### Por que Terraform?

| Característica | Benefício |
|---|---|
| **Declarativo** | Você descreve o estado desejado, não os passos |
| **Multi-cloud** | AWS, Azure, GCP, Kubernetes com a mesma ferramenta |
| **State** | Sabe o que existe vs o que deveria existir |
| **Plan** | Mostra o que vai mudar ANTES de aplicar |
| **Idempotente** | Rodar 10x produz o mesmo resultado |
| **Ecossistema** | 3000+ providers, módulos reutilizáveis |

---

## 📋 Índice do Módulo

### Teoria (pasta `docs/`)

| # | Documento | Conteúdo |
|---|-----------|----------|
| 1 | [Fundamentos](./docs/01-fundamentos.md) | IaC, HCL, ciclo de vida, instalação |
| 2 | [Estrutura de Projeto](./docs/02-estrutura-projeto.md) | Organização de arquivos, convenções |
| 3 | [Providers](./docs/03-providers.md) | Configuração, versionamento, autenticação |
| 4 | [Variables e Locals](./docs/04-variables-locals.md) | Inputs, tipos, validações, precedência |
| 5 | [Resources](./docs/05-resources.md) | Ciclo de vida, meta-arguments, dependências |
| 6 | [Outputs e State](./docs/06-outputs-state.md) | Exposição de dados, state file, remote state |

### Código Prático

| Arquivo | O que demonstra |
|---------|----------------|
| [`providers.tf`](./providers.tf) | Provider AWS com default_tags e versionamento |
| [`variables.tf`](./variables.tf) | Variáveis com tipagem, validação e defaults |
| [`locals.tf`](./locals.tf) | Valores computados e naming padronizado |
| [`main.tf`](./main.tf) | S3 bucket com segurança by default |
| [`outputs.tf`](./outputs.tf) | Exposição de valores úteis |
| [`terraform.tfvars`](./terraform.tfvars) | Valores concretos por ambiente |

---

## 🚀 Como usar

```bash
# 1. Instalar Terraform
# https://developer.hashicorp.com/terraform/install

# 2. Configurar AWS CLI
aws configure

# 3. Inicializar o projeto (baixa providers)
terraform init

# 4. Validar sintaxe
terraform validate

# 5. Ver o plano de execução
terraform plan

# 6. Aplicar (criar recursos na AWS)
terraform apply

# 7. Ver outputs
terraform output

# 8. Destruir tudo
terraform destroy
```

---

## 🎯 Roadmap de Estudo

- [x] Fase 1 — Fundação (estrutura, providers, variables)
- [ ] Fase 2 — Composição (data sources, módulos, environments)
- [ ] Fase 3 — Produção (CI/CD, remote state, segurança avançada)
- [ ] Fase 4 — Avançado (workspaces, import, moved blocks, testing)

---

## 💡 Regra de Ouro

> **Se você não consegue destruir e recriar tudo com `terraform apply`, seu código não está completo.**
>
> Zero configuração manual. Zero click no console. Tudo é código.
