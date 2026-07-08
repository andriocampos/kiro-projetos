# =============================================================================
# OUTPUTS
# =============================================================================
# Outputs expõem valores APÓS o apply para:
# 1. Exibir informações úteis no terminal (bucket name, URL, etc.)
# 2. Compartilhar dados entre módulos (módulo A expõe ARN, módulo B consome)
# 3. Ser consultados via `terraform output` ou por scripts
#
# BOA PRÁTICA:
# - Sempre defina `description`
# - Exponha apenas o que é ÚTIL para quem consome
# - Use `sensitive = true` para valores secretos (não aparece no terminal)
# =============================================================================

output "bucket_name" {
  description = "Nome do bucket S3 criado"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN do bucket S3 (útil para policies IAM)"
  value       = aws_s3_bucket.this.arn
}
