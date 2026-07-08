# =============================================================================
# VARIABLES (Inputs)
# =============================================================================
# Aqui declaramos TODAS as variáveis que o projeto aceita.
#
# POR QUE separar?
# - Qualquer pessoa abre este arquivo e sabe o que precisa configurar
# - Funciona como "documentação viva" do projeto
#
# BOAS PRÁTICAS:
# - Sempre defina `description` — é a documentação da variável
# - Sempre defina `type` — evita erros silenciosos
# - Use `default` só quando faz sentido ter um valor padrão seguro
# - Use `validation` para regras de negócio
# - Variáveis sensíveis: marque com `sensitive = true`
# =============================================================================

variable "aws_region" {
  description = "Região AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto, usado em tags e naming de recursos"
  type        = string
  default     = "estudo-terraform"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+$", var.project_name))
    error_message = "O project_name deve conter apenas letras minúsculas, números e hífens, começando com letra."
  }
}

variable "environment" {
  description = "Ambiente de deploy (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment deve ser: dev, staging ou prod."
  }
}
