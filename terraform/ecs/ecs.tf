resource "aws_ecs_cluster" "test-cluster" {
  name = "myapp-cluster"
    setting {
      name  = "containerInsights"
      value = "enabled"
  }
  tags = {
      Name = "test-app"
  }

}
resource "aws_ecs_task_definition" "test-def" {
  # All options # Must be configured
  family                   = "testapp-task"
  
  execution_role_arn       = "execution_role"
  
  task_role_arn            = "task_role"
  
  network_mode             = "awsvpc" #this mode use for fargate

  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  
  container_definitions    = "${file("${path.module}/templates/image/image.json")}"

  volume {  
      name = "myEfsVolume"
            efs_volume_configuration {
                file_system_id= aws_efs_file_system.efs.id
                root_directory= "/"
                transit_encryption= "ENABLED"
                transit_encryption_port= 2999
                # authorization_config {
                #     access_point_id ="/"
                #     iam ="ENABLED"
                # }
            }
    }



  tags = {
      Name = "test-app"
      Environment="dev"
      CreatedBy=""
    }
}
resource "aws_efs_file_system" "efs" {
  creation_token = "efs-html"

  tags = {
      Name = "test-app"
      Environment="dev"
      CreatedBy=""
    }
}


resource "aws_ecs_service" "test-service" {
  
  # All options # Must be configured
  name            = "testapp-service"
  cluster         = aws_ecs_cluster.test-cluster.id
  task_definition = aws_ecs_task_definition.test-def.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"
  network_configuration {
    security_groups  = []
    subnets          = aws_subnet.private.*.id
    assign_public_ip = "enabled"
  }

  load_balancer {
  }

  iam_role = ""
  depends_on = [aws_alb_listener.testapp, aws_iam_role_policy_attachment.ecs_task_execution_role]

  # ServiceRegistries.ContainerName /already in task defination
  # ServiceRegistries.Port /already in task defination
  # ServiceRegistries.RegistryArn /already in task defination
  tags = {
      Name = "test-app"
      Environment="dev"
      CreatedBy=""
    }
}

resource "aws_ecs_task_set" "example" {
  service         = aws_ecs_service.example.id
  cluster         = aws_ecs_cluster.test-cluster.id
  task_definition = aws_ecs_task_definition.test-def.arn

  network_configuration {
    security_groups  = []
    # oak9: aws_ecs_task_set.network_configuration.security_groups is not configured
    subnets          = aws_subnet.private.*.id
    assign_public_ip = true
  }
  load_balancer {
  }
}