# Create the AWS ECS Cluster
resource "aws_ecs_cluster" "jitsi" {
  name = "jitsi-ecs-cluster"
  capacity_providers = ["FARGATE"]
}


# Create IAM Role and policy
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name = "ecsTaskExecutionRole"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = "${aws_iam_role.ecsTaskExecutionRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


# Create task definitions for Jitsi Services

resource "aws_ecs_task_definition" "web" {
  family = "web"
  container_definitions = file("task_definitions/web.json")
  requires_compatibilities = ["FARGATE"]
  network_mode= "awsvpc"
  memory = 512
  cpu = 256 
}

resource "aws_ecs_task_definition" "prosody" {
  family = "prosody"
  container_definitions = file("task_definitions/prosody.json")
  requires_compatibilities = ["FARGATE"]
  network_mode= "awsvpc"
  memory = 512
  cpu = 256
}

resource "aws_ecs_task_definition" "jicofo" {
  family = "jicofo"
  container_definitions = file("task_definitions/jicofo.json")
  requires_compatibilities = ["FARGATE"]
  network_mode= "awsvpc"
  memory = 512
  cpu = 256
}


# Create the Application Load Balancer, Target Group and Security Group
resource "aws_alb" "alb_web" {
  name = "jitsi-web-alb"
  load_balancer_type = "application"
  subnets = [ 
    "${aws_subnet.subnet_a.id}",
    "${aws_subnet.subnet_b.id}",
    "${aws_subnet.subnet_c.id}"
  ]
  security_groups = ["${aws_security_group.jitsi_alb_sec_group.id}"]
}

# Creating a security group for the load balancer:
resource "aws_security_group" "jitsi_alb_sec_group" {
  vpc_id   = aws_vpc.jitsi_vpc.id 
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "tg_web" {
  name     = "jitsi-web-tg-http"
  port     = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = aws_vpc.jitsi_vpc.id
}

resource "aws_lb_target_group" "tg_web_https" {
  name     = "jitsi-web-tg-https"
  port     = 443
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = aws_vpc.jitsi_vpc.id
}

resource "aws_lb_listener" "lb_web_listener" {
  load_balancer_arn = "${aws_alb.alb_web.arn}" # Referencing our load balancer
  port = "80"
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = "${aws_lb_target_group.tg_web.arn}" # Referencing our tagrte group
  }
}

resource "aws_lb_listener" "lb_web_listener_https" {
  load_balancer_arn = "${aws_alb.alb_web.arn}" # Referencing our load balancer
  port = "443"
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = "${aws_lb_target_group.tg_web_https.arn}" # Referencing our tagrte group
  }
}


# Actually create Jitsi Services

resource "aws_ecs_service" "web" {
  name = "web"
  cluster = "${aws_ecs_cluster.jitsi.id}"
  task_definition = "${aws_ecs_task_definition.web.arn}"
  launch_type = "FARGATE"
  desired_count = 1 

  network_configuration {
    subnets = ["${aws_subnet.subnet_a.id}", "${aws_subnet.subnet_b.id}", "${aws_subnet.subnet_c.id}"]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg_web.arn
    container_name   = "web"
    container_port   = 80
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg_web_https.arn
    container_name   = "web"
    container_port   = 443 
  }

  depends_on = [aws_ecs_cluster.jitsi]

}

resource "aws_ecs_service" "prosody" {
  name = "prosody"
  cluster = "${aws_ecs_cluster.jitsi.id}"
  task_definition = "${aws_ecs_task_definition.prosody.arn}"
  launch_type = "FARGATE"
  desired_count = 1 

  network_configuration {
    subnets = ["${aws_subnet.subnet_a.id}", "${aws_subnet.subnet_b.id}", "${aws_subnet.subnet_c.id}"]
    assign_public_ip = false
  }

  depends_on = [aws_ecs_cluster.jitsi]

}

resource "aws_ecs_service" "jicofo" {
  name = "jicofo"
  cluster = "${aws_ecs_cluster.jitsi.id}"
  task_definition = "${aws_ecs_task_definition.jicofo.arn}"
  launch_type = "FARGATE"
  desired_count = 1 

  network_configuration {
    subnets = ["${aws_subnet.subnet_a.id}", "${aws_subnet.subnet_b.id}", "${aws_subnet.subnet_c.id}"]
    assign_public_ip = false
  }

  depends_on = [aws_ecs_service.prosody]

}
