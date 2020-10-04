# Create the AWS ECS Cluster
resource "aws_ecs_cluster" "jitsi" {
  name = "jitsi-ecs-cluster"
}
