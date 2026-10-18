# koba-app

A lightweight Go HTTP microservice designed to run on AWS EKS.

## Endpoints

| Method | Path      | Response                                      |
|--------|-----------|-----------------------------------------------|
| GET    | `/`       | `{"status":"ok","service":"koba-service",...}` |
| GET    | `/healthz`| `{"status":"healthy"}`                        |

## Local Development

```bash
# Run tests
go test -v ./...

# Run server locally
PORT=8080 go run main.go

# Build Docker image
docker build -t koba-app:local .

# Run container
docker run -p 8080:8080 koba-app:local
```

## CI/CD Pipeline

Triggered on every push/PR to `main`:

1. **test** — runs `go test -v -race ./...` on every push and PR
2. **build-push** — builds Docker image and pushes to AWS ECR (push to `main` only)

Image is tagged with both `${{ github.sha }}` and `latest`.

## Required GitHub Secrets

| Secret           | Description                                    |
|------------------|------------------------------------------------|
| `AWS_ROLE_ARN`   | IAM Role ARN for GitHub OIDC authentication    |
| `AWS_REGION`     | AWS region (e.g. `us-east-1`)                  |
| `ECR_REPOSITORY` | ECR repository name (e.g. `koba-app`)          |

## Post-Setup Steps

### 1. Create ECR Repository

```bash
aws ecr create-repository \
  --repository-name koba-app \
  --region us-east-1
```

### 2. Set Up GitHub OIDC in AWS IAM

Create an OIDC identity provider for GitHub Actions in your AWS account:

```bash
# OIDC provider URL
https://token.actions.githubusercontent.com

# Audience
sts.amazonaws.com
```

Then create an IAM role with this trust policy (replace `YOUR_ACCOUNT_ID` and `YOUR_GITHUB_ORG`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_ORG/koba-app:*"
        }
      }
    }
  ]
}
```

Attach `AmazonEC2ContainerRegistryPowerUser` policy to the role.

### 3. Update Image Tag in koba-config

After a new image is pushed to ECR, update `deployment.yaml` in the `koba-config` repo:

```yaml
image: <AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/koba-app:<NEW_SHA>
```
