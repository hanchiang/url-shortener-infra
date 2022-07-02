resource "aws_route53_zone" "route53_zone" {
    name = "yaphc.com"
}

resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.route53_zone.id
  name    = "yaphc.com"
  type    = "A"
  ttl     = "300"
  records = ["76.76.21.21"]
}

resource "aws_route53_record" "txt" {
  zone_id = aws_route53_zone.route53_zone.id
  name    = "yaphc.com"
  type    = "TXT"
  ttl     = "300"
  records = ["google-site-verification=E4DMb9opQogXH6RzuMusSh7eCAgzRvYBVgJugEtbopE"]
}

resource "aws_route53_record" "urlshortener_frontend_prod" {
  zone_id = aws_route53_zone.route53_zone.id
  name    = "urlshortener.yaphc.com"
  type    = "CNAME"
  ttl     = "300"
  records = ["url-shortener-frontend-kappa.vercel.app"]
}

resource "aws_route53_record" "urlshortener_api_prod" {
  zone_id = aws_route53_zone.route53_zone.id
  name    = "api.urlshortener.yaphc.com"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.web.public_ip]
}

resource "aws_route53_record" "urlshortener_frontend_staging" {
  zone_id = aws_route53_zone.route53_zone.id
  name    = "staging.urlshortener.yaphc.com"
  type    = "CNAME"
  ttl     = "300"
  records = ["cname.vercel-dns.com"]
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.route53_zone.id
  name    = "www.yaphc.com"
  type    = "CNAME"
  ttl     = "300"
  records = ["hashnode.network"]
}
