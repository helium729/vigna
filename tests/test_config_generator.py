#!/usr/bin/env python3
"""
Test script for the VIGNA configuration generator.
Validates that generated configurations work correctly.
"""

import os
import sys
import tempfile
import subprocess

# Add tools directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'tools'))

from vigna_config_generator import VignaConfigGenerator, PREDEFINED_CONFIGS

def test_predefined_configs():
    """Test that predefined configurations can be generated."""
    generator = VignaConfigGenerator()
    
    print("Testing predefined configurations...")
    
    for config_name in PREDEFINED_CONFIGS:
        print(f"  Testing {config_name}...")
        
        # Generate configuration
        config = generator.get_predefined_config(config_name)
        
        # Validate
        is_valid, errors = generator.validate_config(config)
        if not is_valid:
            print(f"    ERROR: {config_name} validation failed:")
            for error in errors:
                print(f"      - {error}")
            return False
        
        # Generate file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.vh', delete=False) as f:
            temp_file = f.name
        
        try:
            success = generator.generate_config_file(config, temp_file, 
                                                   PREDEFINED_CONFIGS[config_name]['name'])
            if not success:
                print(f"    ERROR: Failed to generate {config_name}")
                return False
            
            # Check file exists and has content
            if not os.path.exists(temp_file):
                print(f"    ERROR: Generated file doesn't exist for {config_name}")
                return False
            
            with open(temp_file, 'r') as f:
                content = f.read()
            
            if len(content) < 100:  # Sanity check
                print(f"    ERROR: Generated file too small for {config_name}")
                return False
            
            print(f"    ✓ {config_name} generated successfully")
            
        finally:
            if os.path.exists(temp_file):
                os.unlink(temp_file)
    
    print("All predefined configurations test passed!")
    return True

def test_parse_existing_configs():
    """Test parsing existing configuration files."""
    generator = VignaConfigGenerator()
    
    print("Testing parsing of existing configurations...")
    
    # Find existing config files
    config_files = []
    for filename in os.listdir('.'):
        if filename.startswith('vigna_conf_') and filename.endswith('.vh'):
            config_files.append(filename)
    
    if not config_files:
        print("  No existing configuration files found to test")
        return True
    
    for config_file in config_files:
        print(f"  Testing {config_file}...")
        
        try:
            config = generator.parse_existing_config(config_file)
            
            # Validate parsed config
            is_valid, errors = generator.validate_config(config)
            if not is_valid:
                print(f"    WARNING: {config_file} has validation issues:")
                for error in errors:
                    print(f"      - {error}")
            else:
                print(f"    ✓ {config_file} parsed and validated successfully")
                
        except Exception as e:
            print(f"    ERROR: Failed to parse {config_file}: {e}")
            return False
    
    print("Parsing tests completed!")
    return True

def test_cli_interface():
    """Test the CLI interface."""
    print("Testing CLI interface...")
    
    script_path = os.path.join('tools', 'vigna_config_generator.py')
    
    # Test help
    result = subprocess.run([sys.executable, script_path, '--help'], 
                          capture_output=True, text=True)
    if result.returncode != 0:
        print("  ERROR: --help failed")
        return False
    print("  ✓ --help works")
    
    # Test list
    result = subprocess.run([sys.executable, script_path, '--list'], 
                          capture_output=True, text=True)
    if result.returncode != 0:
        print("  ERROR: --list failed")
        return False
    if 'rv32i' not in result.stdout:
        print("  ERROR: --list doesn't show expected configurations")
        return False
    print("  ✓ --list works")
    
    # Test config generation
    with tempfile.NamedTemporaryFile(suffix='.vh', delete=False) as f:
        temp_file = f.name
    
    try:
        result = subprocess.run([sys.executable, script_path, 
                               '--config', 'rv32i', '--output', temp_file], 
                              capture_output=True, text=True)
        if result.returncode != 0:
            print(f"  ERROR: config generation failed: {result.stderr}")
            return False
        
        if not os.path.exists(temp_file):
            print("  ERROR: Output file not created")
            return False
        
        with open(temp_file, 'r') as f:
            content = f.read()
        
        if '`ifndef VIGNA_CONF_VH' not in content:
            print("  ERROR: Generated file doesn't have expected header")
            return False
            
        print("  ✓ config generation works")
        
    finally:
        if os.path.exists(temp_file):
            os.unlink(temp_file)
    
    print("CLI interface tests passed!")
    return True

def test_validation():
    """Test configuration validation."""
    print("Testing configuration validation...")
    
    generator = VignaConfigGenerator()
    
    # Test valid configuration
    valid_config = {
        'bus_binding': True,
        'm_extension': True,
        'c_extension': True
    }
    
    is_valid, errors = generator.validate_config(valid_config)
    if not is_valid:
        print(f"  ERROR: Valid config marked as invalid: {errors}")
        return False
    print("  ✓ Valid configuration accepted")
    
    # Test invalid configuration (dependency not met)
    invalid_config = {
        'm_fpga_fast': True,  # Depends on m_extension
        'm_extension': False
    }
    
    is_valid, errors = generator.validate_config(invalid_config)
    if is_valid:
        print("  ERROR: Invalid config marked as valid")
        return False
    print("  ✓ Invalid configuration rejected")
    
    print("Validation tests passed!")
    return True

def main():
    """Run all tests."""
    print("VIGNA Configuration Generator Test Suite")
    print("=" * 50)
    
    # Change to repo root
    script_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.dirname(script_dir)
    os.chdir(repo_root)
    
    tests = [
        test_predefined_configs,
        test_parse_existing_configs,
        test_cli_interface,
        test_validation
    ]
    
    passed = 0
    failed = 0
    
    for test in tests:
        try:
            if test():
                passed += 1
            else:
                failed += 1
        except Exception as e:
            print(f"ERROR: Test {test.__name__} crashed: {e}")
            failed += 1
        print()
    
    print("=" * 50)
    print(f"Test Results: {passed} passed, {failed} failed")
    
    if failed > 0:
        sys.exit(1)
    else:
        print("All tests passed!")

if __name__ == "__main__":
    main()