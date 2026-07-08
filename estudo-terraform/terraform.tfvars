# =============================================================================
# TERRAFORM.TFVARS — Valores das variáveis para este ambiente
# =============================================================================
# Este arquivo atribui valores às variáveis declaradas em variables.tf.
# O Terraform carrega automaticamente arquivos chamados:
#   - terraform.tfvars
#   - *.auto.tfvars
#
# IMPORTANTE:
# - NÃO coloque secrets aqui (passwords, tokens, keys)
# - Secrets devem vir via: environment variables, AWS Secrets Manager, ou Vault
#
# PARA MÚLTIPLOS AMBIENTES:
# - dev.tfvars, staging.tfvars, prod.tfvars
# - Aplica com: terraform apply -var-file="prod.tfvars"
# =============================================================================

aws_region   = "us-east-1"
project_name = "estudo-terraform"
environment  = "dev"
