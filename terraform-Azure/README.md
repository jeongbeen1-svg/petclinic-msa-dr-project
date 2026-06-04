Azure Terraform version of the original AWS `test` stack.

This creates the Azure equivalents of the active AWS stack:

- AWS VPC/subnets/NAT -> Azure Resource Group, VNet, subnets, NAT Gateway
- AWS EKS node group -> Azure AKS cluster and default node pool
- Helm Argo CD deployment remains the same and targets AKS

Before running:

1. Authenticate to Azure:

   ```bash
   az login
   az account set --subscription "<subscription-id>"
   ```

2. Edit `envs/dev/providers.tf` backend values or comment out the `backend "azurerm"` block for local state.

3. Apply from the environment directory:

   ```bash
   cd envs/dev
   terraform init
   terraform apply
   ```

Default region is `koreacentral`. Change `local.location` in `envs/dev/locals.tf` if needed.
