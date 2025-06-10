import ipaddress
import sys
import json
import os
from datetime import datetime

def get_script_paths(provider):
    """Return absolute paths for reliable file operations"""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_dir = os.path.join(script_dir, '..', 'output')
    os.makedirs(output_dir, exist_ok=True)
    return {
        'output': os.path.join(output_dir, f'warp_subnets_including_all_except_{provider}_internal_subnet.json'),
        'error': os.path.join(output_dir, f'{provider}_subnet_error.json')
    }

def validate_input(input_str):
    """Validate and normalize input with comprehensive checks"""
    if '/' not in input_str:
        input_str += '/32'
    
    if input_str.count('/') != 1:
        raise ValueError(f"Invalid CIDR format: '{input_str}'")
    
    ip_part, mask_part = input_str.split('/')
    
    try:
        mask = int(mask_part)
        if not 0 <= mask <= 32:
            raise ValueError("Mask must be 0-32")
    except ValueError:
        raise ValueError(f"Invalid mask value: '{mask_part}'")
    
    try:
        network = ipaddress.ip_network(input_str, strict=True)
    except ValueError as e:
        raise ValueError(f"Invalid network: {str(e)}")
    
    return str(network)

def infer_base_cidr(exclude_cidr):
    """Infer base CIDR from RFC1918 ranges with better error reporting"""
    try:
        exclude_network = ipaddress.ip_network(exclude_cidr, strict=True)
    except ValueError as e:
        raise ValueError(f"Invalid exclusion CIDR: {str(e)}") from e
    
    rfc1918_ranges = [
        ipaddress.ip_network("10.0.0.0/8"),
        ipaddress.ip_network("172.16.0.0/12"),
        ipaddress.ip_network("192.168.0.0/16"),
    ]

    for base_cidr in rfc1918_ranges:
        if exclude_network.subnet_of(base_cidr):
            return str(base_cidr)
    
    raise ValueError(f"IP network {exclude_cidr} not in RFC1918 private ranges")

def calculate_exclusions(base_cidr, exclude_cidr):
    """Enhanced CIDR exclusion with edge case handling"""
    base = ipaddress.ip_network(base_cidr)
    exclude = ipaddress.ip_network(exclude_cidr)

    # Handle full range exclusion
    if base == exclude:
        return []
    
    # Handle single IP exclusion
    if exclude.prefixlen == 32:
        excluded_ip = int(exclude.network_address)
        ranges = []
        
        if base.network_address < excluded_ip:
            ranges.append((base.network_address, excluded_ip - 1))
        if excluded_ip < base.broadcast_address:
            ranges.append((excluded_ip + 1, base.broadcast_address))
    else:
        # Use native exclusion for larger networks
        try:
            return [str(net) for net in base.address_exclude(exclude)]
        except ValueError:
            return [str(base)]

    # Convert ranges to CIDRs
    results = []
    for start, end in ranges:
        results.extend(ipaddress.summarize_address_range(
            ipaddress.IPv4Address(start),
            ipaddress.IPv4Address(end)
        ))
    
    return [str(net) for net in results if net.subnet_of(base)]

def main():
    if len(sys.argv) != 3:
        error = {
            "timestamp": datetime.utcnow().isoformat(),
            "error": "Invalid arguments",
            "usage": "python3 generate_subnets.py <IP_or_CIDR> <provider>",
            "example": "python3 generate_subnets.py 10.156.0.23/32 aws",
            "valid_providers": ["aws", "azure", "gcp"]
        }
        # Attempt to write error to a generic error file if possible
        script_dir = os.path.dirname(os.path.abspath(__file__))
        output_dir = os.path.join(script_dir, '..', 'output')
        os.makedirs(output_dir, exist_ok=True)
        error_path = os.path.join(output_dir, 'subnet_error.json')
        with open(error_path, 'w') as f:
            json.dump(error, f, indent=2)
        sys.exit(1)

    input_str = sys.argv[1].strip()
    provider = sys.argv[2].strip().lower()

    valid_providers = ['aws', 'azure', 'gcp']
    if provider not in valid_providers:
        error = {
            "timestamp": datetime.utcnow().isoformat(),
            "input_received": input_str,
            "error_type": "InvalidProviderError",
            "message": f"Provider '{provider}' is not valid. Must be one of {valid_providers}.",
            "usage": "python3 generate_subnets.py <IP_or_CIDR> <provider>",
            "example": "python3 generate_subnets.py 10.156.0.23/32 aws"
        }
        script_dir = os.path.dirname(os.path.abspath(__file__))
        output_dir = os.path.join(script_dir, '..', 'output')
        os.makedirs(output_dir, exist_ok=True)
        error_path = os.path.join(output_dir, f'{provider}_subnet_error.json')
        with open(error_path, 'w') as f:
            json.dump(error, f, indent=2)
        sys.exit(1)

    paths = get_script_paths(provider)
    result = {}

    try:
        # Validate and process input
        exclude_cidr = validate_input(input_str)
        base_cidr = infer_base_cidr(exclude_cidr)
        
        # Calculate exclusions
        excluded_nets = calculate_exclusions(base_cidr, exclude_cidr)
        
        # Build result structure
        result = {
            "metadata": {
                "generated_at": datetime.utcnow().isoformat(),
                "script_version": "1.1",
                "input_received": input_str,
                "normalized_exclusion": exclude_cidr,
                "base_network": base_cidr,
                "provider": provider
            },
            "exclusions": [
                {
                    "address": cidr,
                    "description": f"{provider.upper()} Excluded Subnet {i+1}",
                    "type": "calculated"
                } for i, cidr in enumerate(excluded_nets)
            ],
            "validation": {
                "rfc1918_compliant": True,
                "complete_coverage": len(excluded_nets) > 0
            }
        }

        with open(paths['output'], 'w') as f:
            json.dump(result, f, indent=2)
        
        print(f"Successfully generated {len(excluded_nets)} exclusion rules in {paths['output']}")

    except Exception as e:
        error = {
            "timestamp": datetime.utcnow().isoformat(),
            "input_received": input_str,
            "error_type": type(e).__name__,
            "message": str(e),
            "possible_fixes": [
                "Ensure input is a valid IPv4 address/CIDR",
                "Check if IP belongs to RFC1918 private ranges",
                "Verify network mask validity (0-32)",
                "Use a valid provider argument: aws, azure, or gcp"
            ]
        }
        with open(paths['error'], 'w') as f:
            json.dump(error, f, indent=2)
        sys.exit(1)

if __name__ == "__main__":
    main()
