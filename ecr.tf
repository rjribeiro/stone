resource "aws_ecr_repository" "repo" {
  name = var.image_name
}

resource "aws_ecr_lifecycle_policy" "repo-policy" {
  repository = aws_ecr_repository.repo.name

  policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Delete all untagged images",
      "selection": {
        "tagStatus": "untagged",
        "countType": "imageCountMoreThan",
        "countNumber": 1
      },
      "action": {
        "type": "expire"
      }
    },
    {
      "rulePriority": 2,
      "description": "Keep last 2 any images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 2
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF

}



# ------ Push image ------------------------------
# Calculate hash of the Docker image source contents
# Calculate hash of the Docker image source contents
data "external" "hash" {
  program = [coalesce(var.hash_script, "${path.module}/hash_image.sh"), var.source_path]
}

# Build and push the Docker image whenever the hash changes
resource "null_resource" "push" {
  triggers = {
    hash = data.external.hash.result["hash"]
  }

  provisioner "local-exec" {
    command     = "${coalesce(var.push_script, "${path.module}/push_image.sh")} ${var.source_path} ${aws_ecr_repository.repo.repository_url} ${var.tag}"
    interpreter = ["bash", "-c"]
  }
}

data "aws_ecr_image" "service_image" {
  repository_name = aws_ecr_repository.repo.name
  image_tag       = var.tag

  depends_on = [null_resource.push]
}
