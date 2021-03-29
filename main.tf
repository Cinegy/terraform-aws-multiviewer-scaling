# mark this installation as being hosted by Terraform Cloud in the Cinegy org
terraform {
  backend "remote" {
    organization = "cinegy"

    workspaces {
      name = "MultiviewerScaling"
    }
  }
}

# define repeatedly re-used variables here
locals {
  app_name = "multiviewer-scaletest"
  aws_region = "eu-west-1"
  customer_tag = "Cinegy"
  environment_name = "demo"
}

# define the specific providers, including providers required to pass into modules
provider "aws" {
  region  = local.aws_region
}

provider "tls" {
}

provider "template" {
}

# install the base infrastructure required to support other module elements
module "cinegy_base" {
  source  = "app.terraform.io/cinegy/cinegy-base/aws"
  version = "0.0.12"
  
  app_name = local.app_name
  aws_region = local.aws_region
  customer_tag = local.customer_tag
  environment_name = local.environment_name

  aws_secrets_privatekey_arn = "arn:aws:secretsmanager:eu-west-1:564731076164:secret:cinegy-qa/privatekey.pem-ChNfQs"
  domain_name = var.domain_name
  domain_admin_password = var.domain_admin_password
}

module "cinegy-mv" {
  source            = "app.terraform.io/cinegy/cinegy-base-winvm/aws"
  version           = "0.0.28"

  app_name          = local.app_name
  aws_region        = local.aws_region
  customer_tag      = local.customer_tag
  environment_name  = local.environment_name
  instance_profile  = module.cinegy_base.instance_profile_default_ec2_instance_name
  vpc_id            = module.cinegy_base.main_vpc
  ad_join_doc_name  = module.cinegy_base.ad_join_doc_name

  count = 1

  ami_name        = "Air_MV_Cap_v15_Marketplace*" - use this AMI if you are not running from a Cinegy AWS account to get licenses for Air / MV injected automatically
  //ami_name          = "Windows_Server-2019-English-Full-Base*"
  instance_type     = "g3s.xlarge"
  host_name_prefix  = "MV${count.index+1}A"
  host_description  = "${upper(local.environment_name)}-Multiviewer (MV) ${count.index+1}A"
  instance_subnet   = module.cinegy_base.public_subnets.a
  root_volume_size  = 65

  security_groups = [
    module.cinegy_base.remote_access_security_group,
    module.cinegy_base.remote_access_udp_6000_6100
  ]
  
  user_data_script_extension = <<EOF
  
  Uninstall-WindowsFeature -Name Windows-Defender
  Set-Service wuauserv -StartupType Disabled

  Install-CinegyPowershellModules
  Install-DefaultPackages
  Get-AwsLicense -UseTaggedHostname $true

  Install-Product -PackageName Cinegy-Multiviewer-Trunk -VersionTag dev
  Install-Product -PackageName Thirdparty-AirNvidiaAwsDrivers-v14.x -VersionTag dev
  RenameHost
EOF
}
