# 📖 01 — Fundamentos do Terraform

## O que é Infrastructure as Code (IaC)?

Infrastructure as Code é a prática de gerenciar e provisionar infraestrutura através de **arquivos de configuração** ao invés de processos manuais (clicar no console, rodar comandos ad-hoc).

### Analogia

| Sem IaC | Com IaC |
|---------|---------|
| Receita de bolo na cabeça do cozinheiro | Receita escrita, versionada, reproduzível |
| "Cria um EC2 t2.micro na us-east-1" (falado) | Código que descreve exatamente o que precisa existir |
| Se der problema, quem fez precisa lembrar o que fez | Git log mostra exatamente o que mudou e quando |

### Benefícios Concretos

1. **Reprodutibilidade** — Mesmo código = mesma infra, sempre
2. **Versionamento** — Git history da sua infraestrutura
3. **Code Review** — PR antes de mudar produção
4. **Automação** — CI/CD pode aplicar mudanças
5. **Documentação viva** — O código É a documentação

---

## Terraform vs Alternativas

| Ferramenta | Abordagem | Multi-cloud | Linguagem |
|------------|-----------|-------------|-----------|
| **Terraform** | Declarativa | ✅ Sim | HCL |
| CloudFormation | Declarativa | ❌ Só AWS | YAML/JSON |
| Pulumi | Imperativa/Declarativa | ✅ Sim | TypeScript, Python, Go |
| Ansible | Procedural | ✅ Sim | YAML |
| CDK | Imperativa | ❌ Só AWS* | TypeScript, Python |

> **Terraform vence em**: simplicidade, ecossistema, adoção de mercado, portabilidade.

---

## Linguagem HCL (HashiCorp Configuration Language)

HCL é a linguagem usada pelo Terraform. Ela é:

- **Declarativa** — Você descreve O QUE quer, não COMO fazer
- **Legível** — Parece JSON mais humano
- **Tipada** — Suporta string, number, bool, list, map, object

### Sintaxe Básica

```hcl
# Isso é um comentário

# Bloco com tipo, label(s) e corpo
resource "aws_s3_bucket" "meu_bucket" {
  bucket = "nome-do-bucket"

  tags = {
    Name = "Meu Bucket"
  }
}
```

Cada bloco tem:
- **Tipo do bloco**: `resource`, `variable`, `output`, `data`, `locals`, `terraform`, `provider`
- **Labels**: identificam o bloco (tipo do recurso + nome lógico)
- **Corpo**: argumentos dentro das chaves `{}`

---

## Ciclo de Vida do Terraform

```
   terraform init       → Baixa providers e módulos
   terraform validate   → Verifica sintaxe e consistência
   terraform plan       → Compara CÓDIGO vs STATE vs INFRA REAL
   terraform apply      → Executa as mudanças e atualiza o STATE
   terraform destroy    → Remove TUDO que está no state
```

### O que acontece em cada comando:

| Comando | Lê código? | Lê state? | Consulta API? | Muda infra? |
|---------|-----------|-----------|---------------|-------------|
| `init` | ✅ | ❌ | ✅ (baixa providers) | ❌ |
| `validate` | ✅ | ❌ | ❌ | ❌ |
| `plan` | ✅ | ✅ | ✅ (refresh) | ❌ |
| `apply` | ✅ | ✅ | ✅ | ✅ |
| `destroy` | ✅ | ✅ | ✅ | ✅ (remove) |

---

## Instalação

### Linux/macOS (recomendado: tfenv)

```bash
# tfenv permite gerenciar múltiplas versões do Terraform
git clone https://github.com/tfutils/tfenv.git ~/.tfenv
echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Instalar versão específica
tfenv install 1.9.0
tfenv use 1.9.0
terraform version
```

---

## Conceitos-Chave para Memorizar

| Conceito | Definição Simples |
|----------|------------------|
| **Provider** | Plugin que conecta Terraform a um serviço (AWS, Azure, etc.) |
| **Resource** | Um objeto de infraestrutura (bucket, EC2, VPC, etc.) |
| **Data Source** | Consulta algo que JÁ existe (sem criar) |
| **State** | Arquivo que rastreia o que o Terraform gerencia |
| **Plan** | Preview das mudanças antes de aplicar |
| **Module** | Grupo de resources reutilizável |
| **Backend** | Onde o state é armazenado (local, S3, etc.) |

---

---

## Exercício Prático

1. Instale o Terraform (use `tfenv` para gerenciar versões)
2. Crie uma pasta vazia e um arquivo `main.tf` com apenas:
   ```hcl
   terraform {
     required_version = ">= 1.5.0"
   }

   output "hello" {
     value = "Terraform funcionando!"
   }
   ```
3. Rode `terraform init` → `terraform plan` → `terraform apply`
4. Veja o output no terminal
5. Rode `terraform destroy`
6. Observe que o ciclo `init → plan → apply → destroy` é a base de TUDO

---

## Próximo: [02 — Estrutura de Projeto](./02-estrutura-projeto.md)
