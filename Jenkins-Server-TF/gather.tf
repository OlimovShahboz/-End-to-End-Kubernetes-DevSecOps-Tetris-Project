data "aws_ami" "ami" {
  owners = ["099720109477"]
  filter {
    name   = "image-id"
    values = ["ami-0aba19e56f3eaec05"]
  }
}
