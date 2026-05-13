#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
CLUSTER_NAME="${CLUSTER_NAME:-bader-gitops-otel-demo-dev}"
ROLE_NAME="${ROLE_NAME:-bader-cluster-autoscaler-irsa}"
POLICY_NAME="${POLICY_NAME:-bader-cluster-autoscaler-policy}"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
OIDC_ISSUER=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" --query "cluster.identity.oidc.issuer" --output text)
OIDC_PROVIDER=${OIDC_ISSUER#https://}
ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME"
POLICY_ARN="arn:aws:iam::$ACCOUNT_ID:policy/$POLICY_NAME"

cat > /tmp/cluster-autoscaler-trust.json <<EOF_TRUST
{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Federated":"arn:aws:iam::$ACCOUNT_ID:oidc-provider/$OIDC_PROVIDER"},"Action":"sts:AssumeRoleWithWebIdentity","Condition":{"StringEquals":{"$OIDC_PROVIDER:aud":"sts.amazonaws.com","$OIDC_PROVIDER:sub":"system:serviceaccount:kube-system:cluster-autoscaler"}}}]}
EOF_TRUST

cat > /tmp/cluster-autoscaler-policy.json <<'EOF_POLICY'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeScalingActivities",
        "autoscaling:DescribeTags",
        "ec2:DescribeImages",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeLaunchTemplateVersions",
        "ec2:GetInstanceTypesFromInstanceRequirements",
        "eks:DescribeNodegroup"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled": "true",
          "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/bader-gitops-otel-demo-dev": "owned"
        }
      }
    }
  ]
}
EOF_POLICY

if aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
  echo "role exists: $ROLE_ARN"
else
  aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document file:///tmp/cluster-autoscaler-trust.json >/dev/null
  echo "created role: $ROLE_ARN"
fi

if aws iam get-policy --policy-arn "$POLICY_ARN" >/dev/null 2>&1; then
  echo "policy exists: $POLICY_ARN"
else
  aws iam create-policy --policy-name "$POLICY_NAME" --policy-document file:///tmp/cluster-autoscaler-policy.json >/dev/null
  echo "created policy: $POLICY_ARN"
fi

aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "$POLICY_ARN" >/dev/null || true

NODEGROUP=$(aws eks list-nodegroups --cluster-name "$CLUSTER_NAME" --region "$AWS_REGION" --query 'nodegroups[0]' --output text)
ASG_NAME=$(aws eks describe-nodegroup --cluster-name "$CLUSTER_NAME" --nodegroup-name "$NODEGROUP" --region "$AWS_REGION" --query 'nodegroup.resources.autoScalingGroups[0].name' --output text)
aws autoscaling create-or-update-tags --region "$AWS_REGION" --tags \
  "ResourceId=$ASG_NAME,ResourceType=auto-scaling-group,Key=k8s.io/cluster-autoscaler/enabled,Value=true,PropagateAtLaunch=true" \
  "ResourceId=$ASG_NAME,ResourceType=auto-scaling-group,Key=k8s.io/cluster-autoscaler/$CLUSTER_NAME,Value=owned,PropagateAtLaunch=true"

echo "NODEGROUP=$NODEGROUP"
echo "ASG_NAME=$ASG_NAME"
echo "ROLE_ARN=$ROLE_ARN"