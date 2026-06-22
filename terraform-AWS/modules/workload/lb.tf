# 로드밸런서 보안 그룹
resource "aws_security_group" "lb_sg" {
  name        = "petclinic-alb-sg"
  description = "Allow HTTPS access to ALB"
  vpc_id      = local.vpc_id

  # 외부에서 들어오는 HTTPS 트래픽 허용
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # EKS로 보내는 아웃바운드 트래픽 (Target Group 관련)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 로드밸런서 생성
resource "aws_lb" "alb" {
  name               = "petclinic-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = local.public_subnet_ids_lb
}

resource "aws_lb_target_group" "petclinic" {
  name        = "petclinic-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "instance" # 포드 IP가 아닌 노드(인스턴스) 대상

  health_check {
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# 443 포트 HTTPS 리스너 생성 (ACM 연동)
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  # 인증서 바인딩
  certificate_arn = local.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.petclinic.arn
  }

  depends_on = [local.acm_certificate_arn]
}