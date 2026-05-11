#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
DAYS="${DAYS:-14}"
END_DATE=$(date -u +%F)
START_DATE=$(date -u -d "${DAYS} days ago" +%F)

echo "AWS cost report"
echo "Region: ${AWS_REGION}"
echo "Period: ${START_DATE} to ${END_DATE}"
echo

echo "Cost by AWS service:"
aws ce get-cost-and-usage \
  --time-period Start="${START_DATE}",End="${END_DATE}" \
  --granularity DAILY \
  --metrics UnblendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --query 'ResultsByTime[].Groups[].{Service:Keys[0],Amount:Metrics.UnblendedCost.Amount,Unit:Metrics.UnblendedCost.Unit}' \
  --output table

echo
echo "Cost by Project tag, if activated in AWS Billing Cost Allocation Tags:"
aws ce get-cost-and-usage \
  --time-period Start="${START_DATE}",End="${END_DATE}" \
  --granularity DAILY \
  --metrics UnblendedCost \
  --group-by Type=TAG,Key=Project \
  --query 'ResultsByTime[].Groups[].{Project:Keys[0],Amount:Metrics.UnblendedCost.Amount,Unit:Metrics.UnblendedCost.Unit}' \
  --output table || true