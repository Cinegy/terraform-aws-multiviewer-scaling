variable "domain_name" {
    description = "Active Directory fully-qualified domain name"
    default     = "ad.cinegy.local"
    type        = string
}

variable "domain_admin_password" {
    description = "Domain admin password - sensitive value, recommended to be passed in via environment variables"
    type        = string
}