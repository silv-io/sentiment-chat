resource "aws_memorydb_subnet_group" "main" {
  name       = "${var.project_name}-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

resource "aws_memorydb_cluster" "main" {
  name                 = "${var.project_name}-cluster"
  acl_name             = "open-access"
  node_type            = "db.t4g.small"
  num_shards           = 1
  subnet_group_name    = aws_memorydb_subnet_group.main.name
  security_group_ids   = [aws_security_group.memorydb.id]
  snapshot_retention_limit = 7
  kms_key_arn          = aws_kms_key.main.arn
  tls_enabled          = true
}
