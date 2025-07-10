resource "aws_vpc" "main_V" {
  cidr_block = "20.0.0.0/16"

  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "prv_1" {
  vpc_id                  = aws_vpc.main_V.id
  cidr_block              = "20.0.0.0/22"
  availability_zone       = "eu-west-2a"
  # map_public_ip_on_launch = true

  tags = {
    Name = "private-subnet"
  }
}

resource "aws_subnet" "pub_1" {
  vpc_id                  = aws_vpc.main_V.id
  cidr_block              = "20.0.4.0/22"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_V.id

  tags = {
    Name = "main-igw"
  }
}

resource "aws_route_table" "main_rt" {
  vpc_id = aws_vpc.main_V.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "main_rt"
  }
}

resource "aws_route_table_association" "pub_rta" {
  subnet_id      = aws_subnet.pub_1.id
  route_table_id = aws_route_table.main_rt.id
}

resource "aws_security_group" "main_sg" {
  name        = "main_sg"
  description = "allow tcp inbound traffic and all outbound rule"
  vpc_id      = aws_vpc.main_V.id

  ingress {
    description = "HTTP Access"
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH Access"
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"] # or ip-address of engineer(s) working on the application
  }

  ingress {
    description = "HTTPS Access"
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All traffic"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "main-sg"
  }
}

resource "aws_security_group" "bh_sg" {
  name        = "bh_sg"
  description = "to allow connection from my ip address to  Bastion Host"
  vpc_id      = aws_vpc.main_V.id

  ingress {
    description = "SSH Access"
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"] # ensure to replace it with your ip address, ending it with "/32". That is, your permanent IP address should be in double quote inside the square bracket
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Bastion-Host-sg"
  }
}

resource "aws_security_group" "prv_sg" {
  name        = "prv_sg"
  description = "configured to allow connection from the bastion host only"
  vpc_id      = aws_vpc.main_V.id

  ingress {
    description     = "SSH Access"
    from_port       = 22
    protocol        = "tcp"
    to_port         = 22
    security_groups = [aws_security_group.bh_sg.id] # this should be the ip address or security group of the Bastion Host
  }

  egress {
    description = "All traffic"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "prv-sg"
  }
}

resource "aws_key_pair" "bh_kp" {
  key_name   = "Bastion-Host-kp"
  public_key = file("C:/Users/MKT/.ssh/bh_kp.pub") # refrencing an already created key-pair path and indicating that it should be process as a "file".
}                                                  # To create a key-pair, run command: ssh-keygen -t rsa -b 4096 -f ~/.ssh/bh_kp. Note: this key-pair will also be use to connect to all resources in the public subnet.

resource "aws_key_pair" "prv_kp" {
  key_name   = "Private-Resources-kp"               # This should be attached to the private resources to be created and also the private key-pair should be 
  public_key = file("C:/Users/MKT/.ssh/prv_kp.pub") # copied into a file in the bastion-host server
}

resource "aws_instance" "frontend_web" {
  ami                    = "ami-044415bb13eee2391"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.pub_1.id
  vpc_security_group_ids = [aws_security_group.main_sg.id]
  depends_on             = [aws_internet_gateway.main_igw]
  key_name               = aws_key_pair.bh_kp.key_name

  tags = {
    Name = "Frontend-web"
  }
}

resource "aws_instance" "bastion_host" {
  ami                    = "ami-044415bb13eee2391"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.pub_1.id
  vpc_security_group_ids = [aws_security_group.bh_sg.id]
  depends_on             = [aws_internet_gateway.main_igw]
  key_name               = aws_key_pair.bh_kp.key_name

  tags = {
    Name = "Bastion-Host"
  }
}

resource "aws_instance" "server_api" {
  ami                    = "ami-044415bb13eee2391"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.prv_1.id
  vpc_security_group_ids = [aws_security_group.prv_sg.id]
  depends_on             = [aws_internet_gateway.main_igw]
  key_name               = aws_key_pair.prv_kp.key_name

  tags = {
    Name = "server-api"
  }
}
