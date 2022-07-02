resource "aws_route53_record" "urlshortener_api_prod" {
  zone_id = var.route53_zone_id
  name    = "api.urlshortener.yaphc.com"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.web.public_ip]
}