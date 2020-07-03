module github.com/cloudposse/terraform-aws-eks-cluster

go 1.13

require (
	github.com/aws/aws-sdk-go v1.33.0
	github.com/gruntwork-io/terratest v0.16.0
	github.com/pquerna/otp v1.2.0 // indirect
	github.com/stretchr/testify v1.5.1
	k8s.io/api v0.18.5
	k8s.io/client-go v0.17.0
	sigs.k8s.io/aws-iam-authenticator v0.5.1
)
