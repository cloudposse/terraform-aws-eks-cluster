package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Test the Terraform module in examples/complete using Terratest.
func TestExamplesComplete(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../examples/complete",
		Upgrade:      true,
		// Variables to pass to our Terraform code using -var-file options
		VarFiles: []string{"fixtures.us-east-2.tfvars"},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the value of an output variable
	vpcCidr := terraform.Output(t, terraformOptions, "vpc_cidr")
	// Verify we're getting back the outputs we expect
	assert.Equal(t, "172.16.0.0/16", vpcCidr)

	// Run `terraform output` to get the value of an output variable
	privateSubnetCidrs := terraform.OutputList(t, terraformOptions, "private_subnet_cidrs")
	// Verify we're getting back the outputs we expect
	assert.Equal(t, []string{"172.16.0.0/19", "172.16.32.0/19"}, privateSubnetCidrs)

	// Run `terraform output` to get the value of an output variable
	publicSubnetCidrs := terraform.OutputList(t, terraformOptions, "public_subnet_cidrs")
	// Verify we're getting back the outputs we expect
	assert.Equal(t, []string{"172.16.96.0/19", "172.16.128.0/19"}, publicSubnetCidrs)

	// Run `terraform output` to get the value of an output variable
	workersAutoscalingGroupName := terraform.Output(t, terraformOptions, "workers_autoscaling_group_name")
	// Verify we're getting back the outputs we expect
	assert.Contains(t, workersAutoscalingGroupName, "eg-test-eks-cluster")

	// Run `terraform output` to get the value of an output variable
	workersLaunchTemplateArn := terraform.Output(t, terraformOptions, "workers_launch_template_arn")
	// Verify we're getting back the outputs we expect
	assert.Contains(t, workersLaunchTemplateArn, "arn:aws:ec2:us-east-2:126450723953:launch-template")

	// Run `terraform output` to get the value of an output variable
	workersSecurityGroupName := terraform.Output(t, terraformOptions, "workers_security_group_name")
	// Verify we're getting back the outputs we expect
	assert.Equal(t, "eg-test-eks-cluster-workers", workersSecurityGroupName)

	// Run `terraform output` to get the value of an output variable
	workerRoleName := terraform.Output(t, terraformOptions, "workers_role_name")
	// Verify we're getting back the outputs we expect
	assert.Equal(t, "eg-test-eks-cluster-workers", workerRoleName)

	// Run `terraform output` to get the value of an output variable
	eksClusterId := terraform.Output(t, terraformOptions, "eks_cluster_id")
	// Verify we're getting back the outputs we expect
	assert.Equal(t, "eg-test-eks-cluster-cluster", eksClusterId)

	// Run `terraform output` to get the value of an output variable
	eksClusterSecurityGroupName := terraform.Output(t, terraformOptions, "eks_cluster_security_group_name")
	// Verify we're getting back the outputs we expect
	assert.Equal(t, "eg-test-eks-cluster-cluster", eksClusterSecurityGroupName)
}
