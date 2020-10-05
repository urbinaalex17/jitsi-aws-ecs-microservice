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


# Actually create Jitsi Services

resource "aws_ecs_service" "web" {
  name = "web"
  cluster = "${aws_ecs_cluster.jitsi.id}"
  task_definition = "${aws_ecs_task_definition.web.arn}"
  launch_type = "FARGATE"
  desired_count = 3 
  network_configuration {
    subnets = ["${aws_subnet.subnet_a.id}", "${aws_subnet.subnet_b.id}", "${aws_subnet.subnet_c.id}"]
    assign_public_ip = true
  }
}
