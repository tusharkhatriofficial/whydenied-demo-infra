# whydenied-demo-infra

A small Terraform app used to demo [WhyDenied](https://github.com/tusharkhatriofficial/whydenied).

`orders-api` is a Lambda that reads its database URL from SSM Parameter Store. Its IAM role (`orders-api-role`) is **deliberately missing** `ssm:GetParameter`, so every call fails with `AccessDenied`.

WhyDenied catches that denial and opens a pull request on this repo that adds the missing permission.

## Run it

```bash
export AWS_PROFILE=whydenied
terraform init
terraform apply

# fails with AccessDenied
aws lambda invoke --function-name orders-api out.json && cat out.json
```

After merging WhyDenied's PR, run `terraform apply` again and invoke it once more. It returns `"status": "ok"`.
