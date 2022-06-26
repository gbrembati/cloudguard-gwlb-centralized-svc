# CloudGuard GWLB Deployment on AWS
This Terraform project is intended to be used as a template in a demonstration or to build a test environment.  
What it does is creating an infrastructure composed of application VPCs, Shared Services VPC, Transit Gateway, and protect them with an auto-scaling group of CloudGuard gateways by using the newly AWS GWLB service. These applications will have then the East-West and Outgoiung traffic protected by a CloudGuard Instances.    

## Do you want to see more?    
Check out other CloudGuard examples at [Github/gbrembati](https://github.com/gbrembati/)

## Which are the components created?
The project creates the following resources and combine them:
1. **VPCs**: 
2. **Transit Gateway**:

## How to use it
The only thing that you need to do is changing the __*terraform.tfvars*__ file located in this directory.

```hcl
# Set in this file your deployment variables
region      = "xx-xxxx-x" 
access_key  = "xxxxxxxxxxxxxxx"
secret_key  = "xxxxxxxxxxxxxxx"

```
If you want (or need) to further customize other project details, you can change defaults in the different __*name-variables.tf*__ files.   
Here you will also able to find the descriptions that explains what each variable is used for.

## The infrastruction created with the following design:
![Architectural Design](/zimages/gwlb-centralized-design.jpg)
