variable "project_name" {
  default = "expense"
}
variable "environment" {
  default = "dev"
}


variable "common_tags" {
    default = {
          Project = "Expense"
          Environment = "Dev"
          Teraform = true
    }
  }

  variable "zone_name" {
  type        = string
  default     = "harishbalike.online"
  description = "description"
}
