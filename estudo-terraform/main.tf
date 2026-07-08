# =============================================================================
# MAIN — Recursos principais
# =============================================================================
# Este arquivo contém os recursos de infraestrutura do projeto.
#
# POR QUE "main.tf"?
# - Convenção da comunidade Terraform
# - Em projetos pequenos, todos os resources ficam aqui
# - Em projetos maiores, quebre em arquivos por domínio:
#   Ex: s3.tf, iam.tf, networking.tf, compute.tf
#
# QUANDO quebrar:
# - Se main.tf passar de ~100 linhas, considere separar
# - Agrupe por domínio (rede com rede, storage com storage)
#
# BOA PRÁTICA DE NAMING:
# - resource "aws_s3_bucket" "this" — quando só tem UM do tipo
# - resource "aws_s3_bucket" "logs" — quando tem VÁRIOS, use nome descritivo
# =============================================================================

# -----------------------------------------------------------------------------
# Exemplo: S3 Bucket
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "this" {
  bucket = "${local.name_prefix}-artifacts"

  tags = local.common_tags
}

# BOA PRÁTICA: Configurações de bucket ficam em resources separados (não inline)
# Isso facilita adicionar/remover features sem mexer no resource principal
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled" # Protege contra deleção acidental
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  # BOA PRÁTICA: Bloquear acesso público por padrão. SEMPRE.
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
