#!/bin/bash

set -euo pipefail

# Destruye todos los recursos de AWS creados por Terraform (dev, qas, prd),
# limpia buckets S3 (incluyendo versiones y delete markers),
# elimina roles OIDC de GitHub Actions y el backend remoto de Terraform (S3+DynamoDB).
# Uso:
#   ./scripts/destroy-all.sh --yes [--profile <aws-profile>] [--region <aws-region>]

REGION="${AWS_REGION:-us-east-1}"
PROFILE="${AWS_PROFILE:-}"
YES=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes|-y)
      YES=1
      shift
      ;;
    --profile)
      PROFILE="$2"
      shift 2
      ;;
    --region)
      REGION="$2"
      shift 2
      ;;
    *)
      echo "Uso: $0 --yes [--profile <aws-profile>] [--region <aws-region>]" >&2
      exit 1
      ;;
  esac
done

if [[ "$YES" -ne 1 ]]; then
  echo "❌ Debes pasar --yes para continuar (operación destructiva)" >&2
  exit 1
fi

if ! command -v aws >/dev/null 2>&1; then
  echo "❌ AWS CLI no está instalado" >&2
  exit 1
fi

if ! command -v terraform >/dev/null 2>&1; then
  echo "❌ Terraform no está instalado" >&2
  exit 1
fi

AWS_BASE=(aws)
if [[ -n "$PROFILE" ]]; then
  AWS_BASE+=(--profile "$PROFILE")
fi
AWS_BASE+=(--region "$REGION")

function empty_bucket_data() {
  local bucket="$1"

  if ! "${AWS_BASE[@]}" s3api head-bucket --bucket "$bucket" >/dev/null 2>&1; then
    echo "⏭️  Bucket $bucket no existe, continuo"
    return 0
  fi

  echo "🧹 Vaciando objetos en s3://$bucket (incluyendo versiones y delete markers)..."
  # Objetos actuales
  "${AWS_BASE[@]}" s3 rm "s3://$bucket" --recursive >/dev/null 2>&1 || true

  # Eliminar versiones y delete markers en lotes
  while true; do
    local had_items=0

    # Versions
    while IFS=$'\t' read -r key vid; do
      [[ -z "${key:-}" || -z "${vid:-}" ]] && continue
      had_items=1
      "${AWS_BASE[@]}" s3api delete-object --bucket "$bucket" --key "$key" --version-id "$vid" >/dev/null 2>&1 || true
    done < <("${AWS_BASE[@]}" s3api list-object-versions --bucket "$bucket" --query 'Versions[][Key,VersionId]' --output text 2>/dev/null || true)

    # DeleteMarkers
    while IFS=$'\t' read -r key vid; do
      [[ -z "${key:-}" || -z "${vid:-}" ]] && continue
      had_items=1
      "${AWS_BASE[@]}" s3api delete-object --bucket "$bucket" --key "$key" --version-id "$vid" >/dev/null 2>&1 || true
    done < <("${AWS_BASE[@]}" s3api list-object-versions --bucket "$bucket" --query 'DeleteMarkers[][Key,VersionId]' --output text 2>/dev/null || true)

    [[ $had_items -eq 0 ]] && break
  done

  echo "✅ Bucket $bucket vaciado"
}

function tf_destroy_env() {
  local env="$1"
  echo "\n💥 Destruyendo infraestructura Terraform en $env ..."

  # Vaciar bucket del frontend antes del destroy (para evitar bloqueos)
  local frontend_bucket="turnaki-nexioq-${env}-frontend"
  empty_bucket_data "$frontend_bucket" || true

  # Ejecutar destroy
  local env_dir="$(cd "$(dirname "$0")"/.. && pwd)/terraform/environments/${env}"
  if [[ ! -d "$env_dir" ]]; then
    echo "⏭️  Directorio de entorno no encontrado: $env_dir"
    return 0
  fi

  ( cd "$env_dir" && terraform init -input=false && terraform destroy -auto-approve -input=false ) || true
  echo "✅ Destroy $env completado (o no quedaban recursos)"
}

function delete_oidc_and_roles() {
  echo "\n🧨 Eliminando roles IAM y OIDC de GitHub Actions..."

  local account_id
  account_id=$("${AWS_BASE[@]}" sts get-caller-identity --query Account --output text 2>/dev/null || echo "")

  # Roles creados por setup-aws-oidc.sh
  local roles=("github-actions-terraform-dev" "github-actions-terraform-prd")
  for role in "${roles[@]}"; do
    if "${AWS_BASE[@]}" iam get-role --role-name "$role" >/dev/null 2>&1; then
      # Eliminar política inline si existe
      "${AWS_BASE[@]}" iam delete-role-policy --role-name "$role" --policy-name TerraformStateAccess >/dev/null 2>&1 || true
      # Desanexar políticas administradas conocidas
      "${AWS_BASE[@]}" iam detach-role-policy --role-name "$role" --policy-arn arn:aws:iam::aws:policy/PowerUserAccess >/dev/null 2>&1 || true
      # Borrar el rol
      "${AWS_BASE[@]}" iam delete-role --role-name "$role" >/dev/null 2>&1 || true
      echo "✅ Rol eliminado: $role"
    else
      echo "⏭️  Rol no existe: $role"
    fi
  done

  # OIDC Provider
  if [[ -n "$account_id" ]]; then
    local oidc_arn="arn:aws:iam::${account_id}:oidc-provider/token.actions.githubusercontent.com"
    if "${AWS_BASE[@]}" iam get-open-id-connect-provider --open-id-connect-provider-arn "$oidc_arn" >/dev/null 2>&1; then
      "${AWS_BASE[@]}" iam delete-open-id-connect-provider --open-id-connect-provider-arn "$oidc_arn" >/dev/null 2>&1 || true
      echo "✅ OIDC Provider eliminado: $oidc_arn"
    else
      echo "⏭️  OIDC Provider no existe"
    fi
  fi
}

function delete_tf_backend() {
  echo "\n🧨 Eliminando backend remoto de Terraform (S3 + DynamoDB locks)..."

  local tf_bucket="turnaki-nexioq-terraform-state"
  local tf_locks_table="turnaki-nexioq-terraform-locks"

  # Vaciar y eliminar bucket del tfstate (versionado)
  empty_bucket_data "$tf_bucket" || true
  if "${AWS_BASE[@]}" s3api head-bucket --bucket "$tf_bucket" >/dev/null 2>&1; then
    "${AWS_BASE[@]}" s3api delete-bucket --bucket "$tf_bucket" >/dev/null 2>&1 || true
    echo "✅ Bucket backend eliminado: $tf_bucket"
  else
    echo "⏭️  Bucket backend no existe: $tf_bucket"
  fi

  # Eliminar tabla de locks de DynamoDB
  if "${AWS_BASE[@]}" dynamodb describe-table --table-name "$tf_locks_table" >/dev/null 2>&1; then
    "${AWS_BASE[@]}" dynamodb delete-table --table-name "$tf_locks_table" >/dev/null 2>&1 || true
    # Esperar hasta que se elimine
    "${AWS_BASE[@]}" dynamodb wait table-not-exists --table-name "$tf_locks_table" >/dev/null 2>&1 || true
    echo "✅ Tabla de locks eliminada: $tf_locks_table"
  else
    echo "⏭️  Tabla de locks no existe: $tf_locks_table"
  fi
}

echo "🚨 Iniciando destrucción TOTAL en región $REGION ${PROFILE:+(perfil $PROFILE)}"

# Destruir por entornos (pre-vaciado de buckets incluido)
tf_destroy_env dev
tf_destroy_env qas
tf_destroy_env prd

# Eliminar recursos fuera de Terraform
delete_oidc_and_roles

# Eliminar backend remoto (al final)
delete_tf_backend

echo "\n🎉 Operación completada."


