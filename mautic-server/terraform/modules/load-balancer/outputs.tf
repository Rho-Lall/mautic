# Load Balancer Module - Outputs
# Standard output pattern for module interconnection

output "load_balancer_id" {
  description = "Load balancer identifier"
  value       = aws_lb.main.id
}

output "load_balancer_arn" {
  description = "Load balancer ARN for cross-module references"
  value       = aws_lb.main.arn
}

output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "load_balancer_zone_id" {
  description = "Canonical hosted zone ID of the load balancer"
  value       = aws_lb.main.zone_id
}

output "target_group_id" {
  description = "Target group identifier"
  value       = aws_lb_target_group.main.id
}

output "target_group_arn" {
  description = "Target group ARN for cross-module references"
  value       = aws_lb_target_group.main.arn
}

output "http_listener_arn" {
  description = "HTTP listener ARN"
  value       = var.enable_https_redirect && length(aws_lb_listener.http) > 0 ? aws_lb_listener.http[0].arn : (length(aws_lb_listener.http_only) > 0 ? aws_lb_listener.http_only[0].arn : null)
}

output "https_listener_arn" {
  description = "HTTPS listener ARN"
  value       = length(aws_lb_listener.https) > 0 ? aws_lb_listener.https[0].arn : null
}

output "connection_info" {
  description = "Connection details for other modules"
  value = {
    dns_name         = aws_lb.main.dns_name
    zone_id          = aws_lb.main.zone_id
    target_group_arn = aws_lb_target_group.main.arn
  }
}