# Outputs del módulo S3-CloudFront

output "bucket_name" {
  description = "Nombre del bucket S3"
  value       = aws_s3_bucket.frontend.bucket
}

output "bucket_arn" {
  description = "ARN del bucket S3"
  value       = aws_s3_bucket.frontend.arn
}

output "cloudfront_domain_name" {
  description = "Domain name de CloudFront"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "cloudfront_distribution_id" {
  description = "ID de la distribución CloudFront"
  value       = aws_cloudfront_distribution.frontend.id
}

output "cloudfront_url" {
  description = "URL completa de CloudFront"
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

