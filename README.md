# Terraform ECS Cluster Module

A terraform module that provides an ECS cluster.

## What's Included

- Two **IAM Roles**, both using default AWS managed policies (see below)
    1. A role the ECS service itself
    1. A role for the container servers
- A **Security Group** for the ECS servers. This comes without any rules.
- An **Autoscaling Group** that runs the ECS cluster

Lots of choices are made about the autoscaling group here. You may want to
disable it and make your own should you not agree with those choices.

### Note on IAM Policies

The policies provided by Amazon for the container servers and the ECS service
itself a fairly permissive and allow access to all resources.


## What's Not Included

- A load balancer
- IAM Roles for ECS tasks

## Usage

```hcl
module "ecscluster" {
    source = "github.com/AgencyPMG/terraform-ecscluster"
    app = "appname"
    env = "prod" // staging, etc
    cluster_name = "someecscluster"

    instance_ami = "..." // may hard code this or use `data "aws_ami"` to provide it
    instance_type = "t2.name"
    instance_keypair = "some_keypair"

    asg_subnets = ["subnet-xxxxxxx"] // subnets into which the servers will be placed
    asg_min_size = 1 // default 1
    asg_max_size = 1 // default 1
}
```

### Disabling the Autoscaling Group

```hcl
module "ecscluster" {
    source = "github.com/AgencyPMG/terraform-ecscluster"
    // ...
    asg_enabled = false
}
