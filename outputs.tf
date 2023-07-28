output "VPC_ID" {
    value = aws_vpc.VPC[0].id
}

output "Za_SNs_ID" {
    value = try(aws_subnet.Za_SNs[*].id, null)
}

output "Zb_SNs_ID" {
    value = try(aws_subnet.Zb_SNs[*].id, null)
}

output "Zc_SNs_ID" {
    value = try(aws_subnet.Zc_SNs[*].id, null)
}

output "DEFAULT_SG_ID" {
    value = try(aws_default_security_group.DEFAULT_SG[0].id, null)
}

output "SG_ID" {
    value = try(aws_security_group.SG[*].id, null)
}

output "DEFAULT_RTB_ID" {
    value = try(aws_default_route_table.DEFAULT_RTB[0].id, null)
}

output "RTB_ID"{
    value = try(aws_route_table.RTB[*].id, null)
}