# =============================================================================
# LOCALS
# =============================================================================
# Locals são "variáveis computadas" — valores derivados de outras variáveis
# ou lógica interna que NÃO devem ser expostos como input.
#
# QUANDO usar Locals vs Variables?
# - Variable: valor que MUDA entre ambientes ou deploys (input externo)
# - Local: valor CALCULADO a partir de variables ou lógica fixa
#
# EXEMPLO PRÁTICO:
# - variable "environment" = "dev"  (muda por ambiente)
# - local "name_prefix" = "estudo-terraform-dev" (calculado, não é input)
#
# BOA PRÁTICA: Use locals para evitar repetição de expressões complexas
# =============================================================================

locals {
  # Prefixo padronizado para nomes de recursos
  # Resultado: "estudo-terraform-dev"
  name_prefix = "${var.project_name}-${var.environment}"

  # Tags comuns que complementam as default_tags do provider
  common_tags = {
    Owner = "agcampos"
  }
}
