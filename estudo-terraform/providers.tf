# =============================================================================
# PROVIDERS
# =============================================================================
# Este arquivo declara QUAIS provedores de infraestrutura você usa e suas versões.
#
# POR QUE separar em arquivo próprio?
# - Facilita encontrar rapidamente qual provider e versão o projeto usa
# - Em projetos maiores, pode ter múltiplos providers (AWS + Datadog + GitHub)
#
# BOA PRÁTICA: Sempre travar a versão do provider para evitar breaking changes
# surpresa quando alguém rodar "terraform init" meses depois.
# =============================================================================

terraform {
  required_version = ">= 1.5.0" # Versão mínima do Terraform CLI

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Permite 5.x, mas não 6.0 (breaking changes)
    }
  }
}

provider "aws" {
  region = var.aws_region

  # BOA PRÁTICA: Tags padrão aplicadas automaticamente em TODOS os recursos
  # Isso garante que nada fique sem tag, mesmo se você esquecer no resource
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
