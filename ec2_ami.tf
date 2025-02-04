//1. create the ec2 instance
resource "aws_instance" "example_instance" {
  ami                         = "ami-018875e7376831abe" # Specify the base AMI ID
  instance_type               = "t2.micro"     # Specify the instance type
  associate_public_ip_address = true           # Adjust as needed
  subnet_id                   = aws_subnet.public_subnet[0].id


  user_data = filebase64("userdata.sh")
  tags = {
    Name = "example-instance"
  }

}
//2. Create the AMI from the ec2 instance
resource "aws_ami_from_instance" "example_ami" {
  name               = "custom-ami"
  source_instance_id = aws_instance.example_instance.id

}

//3. Wait for the AMI then Terminate the ec2 instance
data "aws_instance" "example_running" {
    filter {
        name = "instance-state-name"
        values = ["running"]
    }

    instance_id = aws_instance.example_instance.id

    depends_on = [aws_ami_from_instance.example_ami]
}

output "instance_id" {
    value = data.aws_instance.example_running.id
}

resource "null_resource" "delete_instances" {
    triggers = {
        instance_id = "${aws_instance.example_instance.id}"
    }
    depends_on = [aws_ami_from_instance.example_ami]
    provisioner "local-exec" {
        command = "aws ec2 terminate-instances --instance-ids ${aws_instance.example_instance.id}"
    }
}
