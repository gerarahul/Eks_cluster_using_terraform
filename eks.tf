
# Eks cluster IAM Role 
resource "aws_iam_role" "cluster" {
  name = "${var.environment}_eks_iam_role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# Attaching IAM role policy to the IAM Role that created above for eks cluster

# attaching --->> AmazonEKSClusterPolicy to iam role
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# attaching --->> AmazonEC2ContainerRegistryReadOnly to iam role
resource "aws_iam_role_policy_attachment" "cluster_AmazonEC2ContainerRegistryReadOnly-EKS" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.cluster.name
}

# Once the policies are attached, create the EKS cluster.
resource "aws_eks_cluster" "ekscluster" {
  name     = "${var.environment}_ekscluster"
  role_arn = aws_iam_role.cluster.arn // arn is Amazon resource name

  // vpc config is the part of creating eks cluster
  vpc_config {
    subnet_ids = flatten([aws_subnet.public_subnet[*].id, aws_subnet.private_subnet[*].id])
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEC2ContainerRegistryReadOnly-EKS
  ]
}

/// -----------Worker Nodes Configuration --------------------------------

/* Set up an IAM role for the worker nodes. The process is similar to the IAM role creation 
for the EKS cluster except this time the policies that you attach will be for the EKS worker node policies. 
The policies include:

AmazonEKSWorkerNodePolicy 
AmazonEKS_CNI_Policy
AmazonEC2ContainerRegistryReadOnly */


# EKS Node IAM Role
resource "aws_iam_role" "node" {
  name = "${var.environment}-Worker-Role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# Attaching IAM role policy to the IAM Role that created above for worker nodes
resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

# EKS Node Groups
resource "aws_eks_node_group" "worker_node_group" {
  cluster_name    = aws_eks_cluster.ekscluster.name
  node_group_name = "${var.environment}_worker_node_group"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = aws_subnet.private_subnet[*].id

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  # type of ami associated  with worker node group
  ami_type       = "AL2_x86_64" # AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64, CUSTOM
  capacity_type  = "ON_DEMAND"  # ON_DEMAND, SPOT
  disk_size      = 10           # Disk size in GiB for worker nodes (in real time production env --> take 100 GiB)
  instance_types = ["t2.medium"]

  depends_on = [
   aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
   aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
   aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
  ]
 }
