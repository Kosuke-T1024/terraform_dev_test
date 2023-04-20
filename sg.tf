# セキュリティグループモジュールの読み込み
module "test-system-dev-ssh-sg" {
  source      = "./modules/security_group/"
  name        = "test-system-dev-ssh-sg"
  vpc_id      = aws_vpc.test-system-dev-vpc.id
  port        = 22
  cidr_blocks = ["0.0.0.0/0"]
  tags        = "test-system-dev-ssh-sg"
}

module "test-system-dev-http-sg" {
  source      = "./modules/security_group/"
  name        = "test-system-dev-http-sg"
  vpc_id      = aws_vpc.test-system-dev-vpc.id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
  tags        = "test-system-dev-http-sg"
}

module "test-system-dev-https-sg" {
  source      = "./modules/security_group/"
  name        = "https-sg"
  vpc_id      = aws_vpc.test-system-dev-vpc.id
  port        = 443
  cidr_blocks = ["0.0.0.0/0"]
  tags        = "test-system-dev-https-sg"
}

module "test-system-dev-http_redirect_sg" {
  source      = "./modules/security_group/"
  name        = "http-redirect-sg"
  vpc_id      = aws_vpc.test-system-dev-vpc.id
  port        = 8080
  cidr_blocks = ["0.0.0.0/0"]
  tags        = "test-system-dev-http_redirect_sg"
}