# Standard AWS Provider Block
terraform {
    required_version = ">= 1.0"
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = ">= 5.0"
        }
    }
}

data "aws_region" "current" {}
data "aws_availability_zones" "available" {}

# Resource VPC
resource "aws_vpc" "VPC"{
    count = (var.VPC.NAME != "" ? 1 : 0)

    tags = {
        Name = "${var.VPC.NAME}"
    }

    cidr_block = var.VPC.CIDR
    enable_dns_support = try(var.VPC.DNS_SUP, true)
    enable_dns_hostnames = try(var.VPC.DNS_HOST, true)
}

# Resource Subnet
resource "aws_subnet" "Za_SNs" {
    count = (length(aws_vpc.VPC) > 0 &&        
            length(var.VPC.Za_SNs_NAME) != null ? length(var.VPC.Za_SNs_NAME) : 0)
    depends_on = [ aws_vpc.VPC ]

    vpc_id = aws_vpc.VPC[0].id
    cidr_block = var.VPC.Za_SNs_CIDR[count.index]
    availability_zone = "${data.aws_region.current.name}a"
    tags = {
        Name = "${var.VPC.Za_SNs_NAME[count.index]}"
    }
}

resource "aws_subnet" "Zb_SNs" {
    count = (length(aws_vpc.VPC) > 0 &&        
            length(var.VPC.Zb_SNs_NAME) > 0 ? length(var.VPC.Zb_SNs_NAME) : 0)
    depends_on = [ aws_vpc.VPC ]

    vpc_id = aws_vpc.VPC[0].id
    cidr_block = var.VPC.Zb_SNs_CIDR[count.index]
    availability_zone = "${data.aws_region.current.name}b"
    tags = {
        Name = "${var.VPC.Zb_SNs_NAME[count.index]}"
    }
}

resource "aws_subnet" "Zc_SNs" {
    count = (length(aws_vpc.VPC) > 0 &&        
            length(var.VPC.Zc_SNs_NAME) > 0 ? length(var.VPC.Zc_SNs_NAME) : 0)
    depends_on = [ aws_vpc.VPC ]

    vpc_id = aws_vpc.VPC[0].id
    cidr_block = var.VPC.Zc_SNs_CIDR[count.index]
    availability_zone = "${data.aws_region.current.name}c"
    tags = {
        Name = "${var.VPC.Zc_SNs_NAME[count.index]}"
    }
}

# Resource DHCP options
resource "aws_default_vpc_dhcp_options" "DEFAULT_DHCP" {
    count = (length(aws_vpc.VPC) > 0 ? 1 : 0)    
    tags = {
        Name = "DEFAULT_DHCP"  
    }
}

resource "aws_vpc_dhcp_options" "DHCP"{
    count = (length(aws_vpc.VPC) > 0 &&    
            var.VPC.DHCP_NAME != "" ? 1 : 0)
    depends_on = [ aws_vpc.VPC ]

    tags = {
        Name = "${var.VPC.DHCP_NAME}"
    }

    domain_name             = try(var.VPC.DHCP_DOMAIN, "${data.aws_region.current.name}.compute.internal")
    domain_name_servers     = try(var.VPC.DHCP_DOMAIN_NSs, ["AmazonProvidedDNS"])
    ntp_servers             = try(var.VPC.DHCP_DOMAIN_NTPs, [])
    netbios_name_servers    = try(var.VPC.DHCP_DOMAIN_NBSs, [])
    netbios_node_type       = try(var.VPC.DHCP_DOMAIN_NODE, null)
}

resource "aws_vpc_dhcp_options_association" "DHCP" {
    count = (length(aws_vpc.VPC) > 0 &&    
            var.VPC.DHCP_NAME != "" ? 1 : 0)
    depends_on = [ aws_vpc_dhcp_options.DHCP ]

    vpc_id = aws_vpc.VPC[0].id
    dhcp_options_id = aws_vpc_dhcp_options.DHCP[count.index].id
}

# Default Security Group
resource "aws_default_security_group" "DEFAULT_SG" {
    count = (length(aws_vpc.VPC) > 0 ? 1 : 0)

    vpc_id = aws_vpc.VPC[0].id
    tags = {
        Name = "${var.VPC.NAME}_DEFAULT_SG"
    }
}

# Resource Security Group
resource "aws_security_group" "SG" {
    count = (length(var.SGs) > 0 ?
            length(var.SGs) : 0)
    depends_on = [ aws_vpc.VPC ]

    vpc_id = aws_vpc.VPC[0].id
    name_prefix = "${var.SGs[count.index].NAME}"
    tags = {
        Name = "${var.SGs[count.index].NAME}"
    }

    dynamic "ingress" {
        for_each = length(var.SGs[count.index].INGRESS) > 0 ? (var.SGs[count.index].INGRESS) : [null]
        content {
            from_port   = try(ingress.value.from_port, 0)
            to_port     = try(ingress.value.to_port, 0)
            protocol    = try(ingress.value.protocol, "")
            cidr_blocks = try(ingress.value.cidr_blocks, [])
            description = try(ingress.value.description, "")
        }
    }

    dynamic "egress" {    
        for_each = length(var.SGs[count.index].EGRESS) > 0 ? (var.SGs[count.index].EGRESS) : [null]
        content {
            from_port   = try(egress.value.from_port, 0)
            to_port     = try(egress.value.to_port, 0)
            protocol    = try(egress.value.protocol, "")
            cidr_blocks = try(egress.value.cidr_blocks, [])
            description = try(egress.value.description, "")
        }
    }
}

# Default Route Table
resource "aws_default_route_table" "DEFAULT_RTB" {
    count = (length(aws_vpc.VPC) > 0 ? 1 : 0)
    depends_on = [ aws_vpc.VPC ]

    default_route_table_id = "${aws_vpc.VPC[0].default_route_table_id}"
    tags = {
        Name = "${var.VPC.NAME}_DEFAULT_RTB"   
    }
}

# Resource Route Table
resource "aws_route_table" "RTB" {
    count = (length(aws_vpc.VPC) > 0 &&        
            length(var.RTBs) > 0 ? length(var.RTBs) : 0)
    depends_on = [ aws_vpc.VPC ]
    vpc_id = aws_vpc.VPC[0].id

    tags = {
        Name = "${var.RTBs[count.index].NAME}"
    }

    # One of the following targets must be provided
    # Gateway_id and Instance_id will be conflict
    dynamic "route" {
        for_each = var.RTBs[count.index].ROUTE
        content {
            cidr_block      = try(route.value.cidr_block, null)
            ipv6_cidr_block = try(route.value.ipv6_cidr_block, null)   
            egress_only_gateway_id    = try(route.value.egress_only_gateway_id, null)
            gateway_id                = try(route.value.gateway_id, null)
            nat_gateway_id            = try(route.value.nat_gateway_id, null)
            network_interface_id      = try(route.value.network_interface_id, null)
            transit_gateway_id        = try(route.value.transit_gateway_id, null)
            vpc_endpoint_id           = try(route.value.vpc_endpoint_id, null)
            vpc_peering_connection_id = try(route.value.vpc_peering_connection_id, null)            
        }
    }
}

# Associate Route table with Subnet
resource "aws_route_table_association" "RTB_ASS" {
    count = (length(aws_vpc.VPC) > 0 &&        
            length(var.RTBs) > 0 ? length(var.RTBs) : 0)

    depends_on = [aws_vpc.VPC, aws_route_table.RTB]
    subnet_id      = var.RTBs[count.index].SN_ID
    route_table_id = aws_route_table.RTB[count.index].id
}

resource "aws_route53_resolver_config" "RT53_RESOLV" {
    count = (length(aws_vpc.VPC) > 0 ? length(aws_vpc.VPC) : 0)
    resource_id              = aws_vpc.VPC[0].id
    autodefined_reverse_flag = "ENABLE"
}
