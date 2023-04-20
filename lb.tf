# ALBの定義
resource "aws_lb" "test-system-dev-alb" {
  name                       = "test-system-dev-alb"
  load_balancer_type         = "application"
  internal                   = false
  idle_timeout               = 60
  enable_deletion_protection = true

  subnets = [
    aws_subnet.test-system-dev-public-subnet1a.id,
    aws_subnet.test-system-dev-public-subnet1c.id,
  ]

  access_logs {
    bucket  = aws_s3_bucket.alb_log.id
    enabled = true
  }

  security_groups = [
    module.test-system-dev-http-sg.security_group_id,
    module.test-system-dev-https-sg.security_group_id,
    module.test-system-dev-http_redirect_sg.security_group_id,
  ]
}

output "alb_dns_name" {
  value = aws_lb.test-system-dev-alb.dns_name
}

# HTTPリスナーの定義
resource "aws_lb_listener" "test-system-dev-http-listener" {
  load_balancer_arn = aws_lb.test-system-dev-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "これは『HTTP』です"
      status_code  = "200"
    }
  }
}

# HTTPSリスナーの定義
resource "aws_lb_listener" "test-system-dev-https-listener" {
  load_balancer_arn = aws_lb.test-system-dev-alb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.test-system-dev-acm-certificate.arn
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "これは『HTTPS』ですよ"
      status_code  = "200"
    }
  }
}

# HTTPリダイレクト
resource "aws_lb_listener" "redirect_http_to_https" {
  load_balancer_arn = aws_lb.test-system-dev-alb.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ターゲットグループの定義
resource "aws_lb_target_group" "test-system-dev-lb-target-group" {
  name                 = "example"
  target_type          = "ip"
  vpc_id               = aws_vpc.test-system-dev-vpc.id
  port                 = 80
  protocol             = "HTTP"
  deregistration_delay = 300

  health_check {
    path                = "/"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = 200
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  depends_on = [aws_lb.test-system-dev-alb]
}

# リスナールールの定義
resource "aws_lb_listener_rule" "test-system-dev-lb-listener-rule" {
  listener_arn = aws_lb_listener.test-system-dev-https-listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test-system-dev-lb-target-group.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}