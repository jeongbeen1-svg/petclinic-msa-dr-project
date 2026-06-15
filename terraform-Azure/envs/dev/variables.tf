variable "bastion_allowed_cidrs" {
  type        = list(string)
  description = "CIDR blocks allowed to SSH to the Azure bastion VM"
  default     = ["58.72.80.6/32"]
}
