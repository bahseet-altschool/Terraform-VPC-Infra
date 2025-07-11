## VPC Provisioning Ensuring Secure Connections within resources inside

### Files and its content

#### 1. terraform.tf
  - terraform configuration is defined.
  - uncomment the **cloud block** and input your organization and workspace name to use Hashicorp terraform (Remote state)

#### 2. provider.tf
   - provider configuration is defined
   - Note: I export my credentials data in my terminal which is secure than listing it as arguments in the provider block;
     - $ export AWS_ACCESS_KEY_ID=myAwsAccesskey
     - $ export AWS_SECRET_ACCESS_KEY=myAwsSecretKey

#### 3. main.tf
   - contain all resources;
     - VPC
     - Private subnet: uncomment the "map_public_ip_on_launch" if you want the resources in private subnet to have public IP address, which is not so secure.
     - Public subnet
     - Internet gateway
     - Route table;
       - a default route created when a new VPC has been created, though AWS provider ignore it but it is always present in AWS.
         - destination/cidr_block = "the-VPC-cidr-block"
         - target/gateway_id = local
        - another route saying any IP coming from anywhere should pass through the internet gateway defined above
          - destination/cidr_block = "0.0.0.0/0"
          - target/gateway_id = my_internet_gateway_id
      - Route association table; linking the public subnet and the route table together
      - 3 Security groups
      - 2 Key pairs
        Note: I created the key-pairs locally using ```ssh-keygen -t rsa -b 4096 -f ~/.ssh/name-of-your-file``` before publishing the public key as file to AWS
      - 3 EC2 Instances

#### 4. output.tf
   - contains the output of;
     - the frontend public ipaddress block
     - the bastion host public address ip block
     - the server private address ip block
