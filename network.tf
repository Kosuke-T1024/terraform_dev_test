# VPCリソースの定義
resource "aws_vpc" "test-system-dev-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "test-system-dev-vpc"
  }
}

/* パブリックネットワーク設計 */

# パブリックサブネットリソースの定義
resource "aws_subnet" "test-system-dev-public-subnet1a" {
  vpc_id                  = aws_vpc.test-system-dev-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "test-system-dev-public-subnet1a"
  }
}

resource "aws_subnet" "test-system-dev-public-subnet1c" {
  vpc_id                  = aws_vpc.test-system-dev-vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "test-system-dev-public-subnet1c"
  }
}

# インターネットゲートウェイリソースの定義
resource "aws_internet_gateway" "test-system-dev-igw" {
  vpc_id = aws_vpc.test-system-dev-vpc.id

  tags = {
    Name = "test-system-dev-igw"
  }
}

# ルートテーブルリソースの定義
resource "aws_route_table" "test-system-dev-pubric-rtb" {
  vpc_id = aws_vpc.test-system-dev-vpc.id

  tags = {
    Name = "test-system-dev-pubric-rtb"
  }
}

# ルートの定義
resource "aws_route" "test-system-dev-pubric-rt" {
  route_table_id         = aws_route_table.test-system-dev-pubric-rtb.id
  gateway_id             = aws_internet_gateway.test-system-dev-igw.id
  destination_cidr_block = "0.0.0.0/0"
}

# ルートテーブルの関連付け
resource "aws_route_table_association" "test-system-dev-pubric-rtb-asso1a" {
  subnet_id      = aws_subnet.test-system-dev-public-subnet1a.id
  route_table_id = aws_route_table.test-system-dev-pubric-rtb.id
}

resource "aws_route_table_association" "test-system-dev-pubric-rtb-asso1c" {
  subnet_id      = aws_subnet.test-system-dev-public-subnet1c.id
  route_table_id = aws_route_table.test-system-dev-pubric-rtb.id
}

/* プライベートネットワーク設計 */

# プライベートサブネットリソースの定義
resource "aws_subnet" "test-system-dev-private-subnet1a" {
  vpc_id                  = aws_vpc.test-system-dev-vpc.id
  cidr_block              = "10.0.65.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "test-system-dev-private-subnet1a"
  }
}

resource "aws_subnet" "test-system-dev-private-subnet1c" {
  vpc_id                  = aws_vpc.test-system-dev-vpc.id
  cidr_block              = "10.0.66.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = false

  tags = {
    Name = "test-system-dev-private-subnet1c"
  }
}

# EIPリソースの定義
resource "aws_eip" "test-system-dev-eip1a" {
  vpc        = true
  depends_on = [aws_internet_gateway.test-system-dev-igw]
}

resource "aws_eip" "test-system-dev-eip1c" {
  vpc        = true
  depends_on = [aws_internet_gateway.test-system-dev-igw]
}

# NATゲートウェイリソースの定義
resource "aws_nat_gateway" "test-system-dev-private-ngw1a" {
  allocation_id = aws_eip.test-system-dev-eip1a.id
  subnet_id     = aws_subnet.test-system-dev-public-subnet1a.id
  depends_on    = [aws_internet_gateway.test-system-dev-igw]

  tags = {
    Name = "test-system-dev-private-ngw1a"
  }
}

resource "aws_nat_gateway" "test-system-dev-private-ngw1c" {
  allocation_id = aws_eip.test-system-dev-eip1c.id
  subnet_id     = aws_subnet.test-system-dev-public-subnet1c.id
  depends_on    = [aws_internet_gateway.test-system-dev-igw]

  tags = {
    Name = "test-system-dev-private-ngw1c"
  }
}

# ルートテーブルリソースの定義
resource "aws_route_table" "test-system-dev-private-rtb1a" {
  vpc_id = aws_vpc.test-system-dev-vpc.id

  tags = {
    Name = "test-system-dev-private-rtb1a"
  }
}

resource "aws_route_table" "test-system-dev-private-rtb1c" {
  vpc_id = aws_vpc.test-system-dev-vpc.id
  tags = {
    Name = "test-system-dev-private-rtb1c"
  }
}

# ルートの定義
resource "aws_route" "test-system-dev-private-rt1a" {
  route_table_id         = aws_route_table.test-system-dev-private-rtb1a.id
  nat_gateway_id         = aws_nat_gateway.test-system-dev-private-ngw1a.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "test-system-dev-private-rt1c" {
  route_table_id         = aws_route_table.test-system-dev-private-rtb1c.id
  nat_gateway_id         = aws_nat_gateway.test-system-dev-private-ngw1c.id
  destination_cidr_block = "0.0.0.0/0"
}

# ルートテーブルの関連付け
resource "aws_route_table_association" "test-system-dev-private-rtb-asso1a" {
  subnet_id      = aws_subnet.test-system-dev-private-subnet1a.id
  route_table_id = aws_route_table.test-system-dev-private-rtb1a.id
}

resource "aws_route_table_association" "test-system-dev-private-rtb-asso1c" {
  subnet_id      = aws_subnet.test-system-dev-private-subnet1c.id
  route_table_id = aws_route_table.test-system-dev-private-rtb1c.id
}