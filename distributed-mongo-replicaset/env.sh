# Change the following parrameters to your setup

# Site 1 details
export TF_VAR_g8_1_url="https://be-gnt-dc01-01.gig.tech/"
export TF_VAR_g8_1_account="GIG Engineering"

# Site 2 details
export TF_VAR_g8_2_url="https://at-vie-dc01-001.gig.tech/"
export TF_VAR_g8_2_account="GIG Engineering"

# Site 3 details
export TF_VAR_g8_3_url="https://ch-lug-dc01-001.gig.tech/"
export TF_VAR_g8_3_account="GIG Engineering"

# Name for your cluster
export TF_VAR_cluster_name="GeertsGeoRedundantMongoDBCluster"

# Your ssh public key. This will be provisioned in the vms for access to the ansible and root accounts on the vms.
export TF_VAR_ssh_key="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAs5awEroyPXJcHe8auLe1VPhi4LI6U7WiulMNpNgkZqIPduGErLXAN+XArV4stkPRLiD5y+lMSYtlAbkRB4mTjsvOBMgAC731iIX5lgAPJr/XFqlQGSgRFn7cFfcAaeaL4/jy2f1G02rThDSK8V4zHDuJFWrDmkrJYY0ze0/7tpHfg84eohusK7zIy6fxR1ZygG0omyNmqq+9WnXMZbV6xMYIfmD8oaBg2/CcJTBk7cDA1F4CblJhyWh3x7kytehlXC4rtPpci2XK3mCAOBbsC34NqDDZ901OORqUnYytd+3qz/bnNx3oAUemEcZPLm2DwYYwf7q3yaRveN4PzCycIw== geert@Geert-Audenaerts-MacBook-Pro.local"
