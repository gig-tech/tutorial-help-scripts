variable "client_jwt" {
  description = "jwt token"
}
variable "g8_1_url" {
  description = "API server URL for G8 1"
}
variable "g8_1_account" {
  description = "Account name for G8 1"
}
variable "g8_2_url" {
  description = "API server URL for G8 2"
}
variable "g8_2_account" {
  description = "Account name for G8 2"
}
variable "g8_3_url" {
  description = "API server URL for G8 3"
}
variable "g8_3_account" {
  description = "Account name for G8 3"
}
variable "ssh_key" {
  description = "Admin ssh key"
}
variable "cluster_name" {
  description = "Mongo cluster name"
}
variable "image_name" {
  description = "Image name or a regex string to much image name"
  default = "Ubuntu 16.04 x64"
}
variable "mongo_memory" {
  description = "Memory provisioned for the worker VM"
  default     = 8192
}
variable "mongo_vcpus" {
  description = "Number of CPUs provisioned for the worker VM"
  default     = 4
}
variable "mongo_boot_disk_size" {
  description = "Worker vm Boot disk size"
  default     = 20
}
variable "mongo_data_disk_size" {
  description = "Data disk size"
  default     = 500
}
variable "mongo_iops" {
  description = "IOPS of data disks"
  default     = 10000
}