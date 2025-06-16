#!/usr/bin/env python3
"""
VIGNA Core Configuration Generator

A unified tool for generating VIGNA RISC-V processor configurations.
Supports both CLI and GUI interfaces for cross-platform compatibility.

Usage:
    python3 vigna_config_generator.py --help
    python3 vigna_config_generator.py --gui
    python3 vigna_config_generator.py --config rv32imc --output vigna_conf_custom.vh
"""

import os
import sys
import argparse
import json
from typing import Dict, List, Set, Optional, Tuple
import re

# Configuration options with descriptions and default values
CONFIG_OPTIONS = {
    # Core Architecture Options
    'e_extension': {
        'define': 'VIGNA_CORE_E_EXTENSION',
        'description': 'Enable E extension (16 registers instead of 32)',
        'default': False,
        'category': 'Core Architecture',
        'conflicts': []
    },
    'bus_binding': {
        'define': 'VIGNA_TOP_BUS_BINDING',
        'description': 'Enable unified bus (vs separate instruction/data buses)',
        'default': True,
        'category': 'Bus Architecture',
        'conflicts': []
    },
    'reset_addr': {
        'define': 'VIGNA_CORE_RESET_ADDR',
        'description': 'Core reset address',
        'default': '32\'h0000_0000',
        'category': 'Memory Configuration',
        'conflicts': [],
        'type': 'value'
    },
    'stack_reset_enable': {
        'define': 'VIGNA_CORE_STACK_ADDR_RESET_ENABLE',
        'description': 'Enable stack pointer reset (WARNING: doubles area)',
        'default': False,
        'category': 'Memory Configuration', 
        'conflicts': []
    },
    'stack_reset_value': {
        'define': 'VIGNA_CORE_STACK_ADDR_RESET_VALUE',
        'description': 'Stack pointer reset value',
        'default': '32\'h0000_1000',
        'category': 'Memory Configuration',
        'conflicts': [],
        'type': 'value',
        'depends_on': 'stack_reset_enable'
    },
    
    # Performance Options
    'two_stage_shift': {
        'define': 'VIGNA_CORE_TWO_STAGE_SHIFT',
        'description': 'Two-stage shift (better timing, larger area)',
        'default': True,
        'category': 'Performance',
        'conflicts': []
    },
    'preload_negative': {
        'define': 'VIGNA_CORE_PRELOAD_NEGATIVE',
        'description': 'Preload negative numbers (better timing, more resources)',
        'default': True,
        'category': 'Performance',
        'conflicts': []
    },
    'alignment': {
        'define': 'VIGNA_CORE_ALIGNMENT',
        'description': 'Enable alignment checks',
        'default': True,
        'category': 'Performance',
        'conflicts': []
    },
    
    # RISC-V Extensions
    'm_extension': {
        'define': 'VIGNA_CORE_M_EXTENSION',
        'description': 'Enable M extension (multiply/divide)',
        'default': False,
        'category': 'RISC-V Extensions',
        'conflicts': []
    },
    'm_fpga_fast': {
        'define': 'VIGNA_CORE_M_FPGA_FAST',
        'description': 'FPGA-optimized multiply/divide (TODO)',
        'default': False,
        'category': 'RISC-V Extensions',
        'conflicts': [],
        'depends_on': 'm_extension'
    },
    'c_extension': {
        'define': 'VIGNA_CORE_C_EXTENSION',
        'description': 'Enable C extension (compressed instructions)',
        'default': False,
        'category': 'RISC-V Extensions',
        'conflicts': []
    },
    'zicsr_extension': {
        'define': 'VIGNA_CORE_ZICSR_EXTENSION',
        'description': 'Enable Zicsr extension (control/status registers)',
        'default': False,
        'category': 'RISC-V Extensions',
        'conflicts': []
    },
    'interrupt': {
        'define': 'VIGNA_CORE_INTERRUPT',
        'description': 'Enable interrupt support',
        'default': False,
        'category': 'RISC-V Extensions',
        'conflicts': []
    },
    
    # Interface Options
    'axi_lite': {
        'define': 'VIGNA_AXI_LITE_INTERFACE',
        'description': 'Enable AXI4-Lite interface (vs simple interface)',
        'default': False,
        'category': 'Bus Interface',
        'conflicts': []
    }
}

# Predefined configurations
PREDEFINED_CONFIGS = {
    'rv32i': {
        'name': 'RV32I Base',
        'description': 'Minimal RISC-V base configuration',
        'options': {
            'bus_binding': True,
            'reset_addr': '32\'h0000_0000',
            'two_stage_shift': True,
            'preload_negative': True,
            'alignment': True
        }
    },
    'rv32e': {
        'name': 'RV32E Embedded',
        'description': 'Embedded configuration with 16 registers',
        'options': {
            'e_extension': True,
            'bus_binding': True,
            'reset_addr': '32\'h0000_0000',
            'two_stage_shift': True,
            'preload_negative': True,
            'alignment': True
        }
    },
    'rv32im': {
        'name': 'RV32IM',
        'description': 'Base + Multiply/Divide extension',
        'options': {
            'bus_binding': True,
            'reset_addr': '32\'h0000_0000',
            'two_stage_shift': True,
            'preload_negative': True,
            'alignment': True,
            'm_extension': True
        }
    },
    'rv32ic': {
        'name': 'RV32IC',
        'description': 'Base + Compressed instruction extension',
        'options': {
            'bus_binding': True,
            'reset_addr': '32\'h0000_0000',
            'two_stage_shift': True,
            'preload_negative': True,
            'alignment': True,
            'c_extension': True
        }
    },
    'rv32imc': {
        'name': 'RV32IMC',
        'description': 'Base + Multiply/Divide + Compressed instructions',
        'options': {
            'bus_binding': True,
            'reset_addr': '32\'h0000_0000',
            'two_stage_shift': True,
            'preload_negative': True,
            'alignment': True,
            'm_extension': True,
            'c_extension': True
        }
    },
    'rv32im_zicsr': {
        'name': 'RV32IM_Zicsr',
        'description': 'Base + Multiply/Divide + CSR extension',
        'options': {
            'bus_binding': True,
            'reset_addr': '32\'h0000_0000',
            'two_stage_shift': True,
            'preload_negative': True,
            'alignment': True,
            'm_extension': True,
            'interrupt': True,
            'zicsr_extension': True
        }
    },
    'rv32imc_zicsr': {
        'name': 'RV32IMC_Zicsr',
        'description': 'Full featured configuration',
        'options': {
            'bus_binding': True,
            'reset_addr': '32\'h0000_0000',
            'two_stage_shift': True,
            'preload_negative': True,
            'alignment': True,
            'm_extension': True,
            'c_extension': True,
            'interrupt': True,
            'zicsr_extension': True
        }
    }
}


class VignaConfigGenerator:
    """Main configuration generator class."""
    
    def __init__(self):
        self.options = CONFIG_OPTIONS.copy()
        self.current_config = {}
        
    def parse_existing_config(self, config_file: str) -> Dict[str, any]:
        """Parse an existing configuration file to extract current settings."""
        config = {}
        if not os.path.exists(config_file):
            return config
            
        with open(config_file, 'r') as f:
            content = f.read()
            
        for option_name, option_info in self.options.items():
            define_name = option_info['define']
            # Check if the define is enabled (not commented)
            pattern = rf'^`define\s+{re.escape(define_name)}'
            if re.search(pattern, content, re.MULTILINE):
                if option_info.get('type') == 'value':
                    # Extract the value
                    value_pattern = rf'^`define\s+{re.escape(define_name)}\s+(.+)$'
                    match = re.search(value_pattern, content, re.MULTILINE)
                    if match:
                        config[option_name] = match.group(1).strip()
                else:
                    config[option_name] = True
            else:
                # Check if it's commented out
                comment_pattern = rf'^//`define\s+{re.escape(define_name)}'
                if re.search(comment_pattern, content, re.MULTILINE):
                    config[option_name] = False
                    
        return config
    
    def validate_config(self, config: Dict[str, any]) -> Tuple[bool, List[str]]:
        """Validate a configuration for conflicts and dependencies."""
        errors = []
        
        # Check dependencies
        for option_name, value in config.items():
            if not value:
                continue
                
            option_info = self.options.get(option_name, {})
            depends_on = option_info.get('depends_on')
            if depends_on and not config.get(depends_on, False):
                errors.append(f"'{option_name}' requires '{depends_on}' to be enabled")
        
        # Check conflicts
        for option_name, value in config.items():
            if not value:
                continue
                
            option_info = self.options.get(option_name, {})
            conflicts = option_info.get('conflicts', [])
            for conflict in conflicts:
                if config.get(conflict, False):
                    errors.append(f"'{option_name}' conflicts with '{conflict}'")
        
        return len(errors) == 0, errors
    
    def generate_config_file(self, config: Dict[str, any], output_file: str, 
                           config_name: str = "Custom Configuration") -> bool:
        """Generate a configuration file from the given configuration."""
        try:
            with open(output_file, 'w') as f:
                f.write(f"`ifndef VIGNA_CONF_VH\n")
                f.write(f"`define VIGNA_CONF_VH\n\n")
                f.write(f"/* {config_name} */\n\n")
                
                # Group options by category
                categories = {}
                for option_name, option_info in self.options.items():
                    category = option_info.get('category', 'Other')
                    if category not in categories:
                        categories[category] = []
                    categories[category].append((option_name, option_info))
                
                # Write each category
                for category, options in categories.items():
                    f.write(f"/* {category} */\n")
                    f.write("/* " + "-" * 73 + " */\n\n")
                    
                    for option_name, option_info in options:
                        define_name = option_info['define']
                        description = option_info['description']
                        value = config.get(option_name)
                        
                        # Write description as comment
                        f.write(f"/* {description} */\n")
                        
                        # Handle dependencies
                        depends_on = option_info.get('depends_on')
                        if depends_on and not config.get(depends_on, False):
                            f.write(f"/* NOTE: Requires {depends_on} to be enabled */\n")
                        
                        # Write the define
                        if value is True:
                            f.write(f"`define {define_name}\n")
                        elif value is False or value is None:
                            f.write(f"//`define {define_name}\n")
                        else:
                            # Value-based define
                            f.write(f"`define {define_name} {value}\n")
                        
                        f.write("\n")
                    
                    f.write("\n")
                
                f.write("`endif\n")
            
            return True
            
        except Exception as e:
            print(f"Error writing configuration file: {e}")
            return False
    
    def get_predefined_config(self, config_name: str) -> Optional[Dict[str, any]]:
        """Get a predefined configuration by name."""
        if config_name in PREDEFINED_CONFIGS:
            return PREDEFINED_CONFIGS[config_name]['options']
        return None
    
    def list_predefined_configs(self) -> List[Tuple[str, str, str]]:
        """List all predefined configurations."""
        configs = []
        for name, info in PREDEFINED_CONFIGS.items():
            configs.append((name, info['name'], info['description']))
        return configs


def cli_interface():
    """Command-line interface for the configuration generator."""
    parser = argparse.ArgumentParser(
        description="VIGNA Core Configuration Generator",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=f"""
Examples:
  {sys.argv[0]} --list
  {sys.argv[0]} --config rv32imc --output my_config.vh
  {sys.argv[0]} --gui
  {sys.argv[0]} --parse vigna_conf.vh --output new_config.vh
        """
    )
    
    parser.add_argument('--gui', action='store_true', 
                       help='Launch graphical user interface')
    parser.add_argument('--list', action='store_true',
                       help='List all predefined configurations')
    parser.add_argument('--config', 
                       help='Use predefined configuration')
    parser.add_argument('--parse',
                       help='Parse existing configuration file')
    parser.add_argument('--output', default='vigna_conf_generated.vh',
                       help='Output configuration file (default: vigna_conf_generated.vh)')
    parser.add_argument('--validate', action='store_true',
                       help='Validate configuration only')
    
    # Add individual option flags
    for option_name, option_info in CONFIG_OPTIONS.items():
        flag_name = option_name.replace('_', '-')
        help_text = option_info['description']
        
        if option_info.get('type') == 'value':
            parser.add_argument(f'--{flag_name}', 
                               help=f'{help_text} (default: {option_info["default"]})')
        else:
            parser.add_argument(f'--enable-{flag_name}', action='store_true',
                               help=f'Enable: {help_text}')
            parser.add_argument(f'--disable-{flag_name}', action='store_true',
                               help=f'Disable: {help_text}')
    
    args = parser.parse_args()
    
    if args.gui:
        launch_gui()
        return
    
    generator = VignaConfigGenerator()
    
    if args.list:
        print("Available predefined configurations:")
        print("-" * 60)
        for name, display_name, description in generator.list_predefined_configs():
            print(f"{name:15} - {display_name:20} - {description}")
        return
    
    # Build configuration
    config = {}
    
    if args.config:
        predefined = generator.get_predefined_config(args.config)
        if predefined is None:
            print(f"Error: Unknown configuration '{args.config}'")
            print("Use --list to see available configurations")
            sys.exit(1)
        config.update(predefined)
        print(f"Using predefined configuration: {args.config}")
    
    if args.parse:
        parsed = generator.parse_existing_config(args.parse)
        config.update(parsed)
        print(f"Parsed configuration from: {args.parse}")
    
    # Apply individual option overrides
    for option_name in CONFIG_OPTIONS:
        flag_name = option_name.replace('_', '-')
        enable_attr = f'enable_{flag_name}'.replace('-', '_')
        disable_attr = f'disable_{flag_name}'.replace('-', '_')
        value_attr = flag_name.replace('-', '_')
        
        if hasattr(args, enable_attr) and getattr(args, enable_attr):
            config[option_name] = True
        elif hasattr(args, disable_attr) and getattr(args, disable_attr):
            config[option_name] = False
        elif hasattr(args, value_attr) and getattr(args, value_attr):
            config[option_name] = getattr(args, value_attr)
    
    # Validate configuration
    is_valid, errors = generator.validate_config(config)
    if not is_valid:
        print("Configuration validation errors:")
        for error in errors:
            print(f"  - {error}")
        if not args.validate:
            print("\nUse --validate flag to check configuration without generating file.")
        sys.exit(1)
    
    if args.validate:
        print("Configuration is valid!")
        return
    
    # Generate configuration file
    config_name = PREDEFINED_CONFIGS.get(args.config, {}).get('name', 'Custom Configuration')
    if generator.generate_config_file(config, args.output, config_name):
        print(f"Configuration file generated: {args.output}")
    else:
        print("Error generating configuration file")
        sys.exit(1)


def launch_gui():
    """Launch the graphical user interface."""
    try:
        import tkinter as tk
        from tkinter import ttk, filedialog, messagebox
    except ImportError:
        print("Error: tkinter not available. Please install python3-tk package.")
        sys.exit(1)
    
    class VignaConfigGUI:
        def __init__(self, root):
            self.root = root
            self.root.title("VIGNA Core Configuration Generator")
            self.root.geometry("800x700")
            
            self.generator = VignaConfigGenerator()
            self.config_vars = {}
            self.current_config = {}
            
            self.setup_ui()
            
        def setup_ui(self):
            # Create main frame with scrollbar
            main_frame = ttk.Frame(self.root)
            main_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
            
            # Title
            title_label = ttk.Label(main_frame, text="VIGNA Core Configuration Generator", 
                                  font=('Arial', 16, 'bold'))
            title_label.pack(pady=(0, 10))
            
            # Create notebook for tabs
            notebook = ttk.Notebook(main_frame)
            notebook.pack(fill=tk.BOTH, expand=True)
            
            # Predefined configurations tab
            predefined_frame = ttk.Frame(notebook)
            notebook.add(predefined_frame, text="Predefined Configurations")
            self.setup_predefined_tab(predefined_frame)
            
            # Custom configuration tab
            custom_frame = ttk.Frame(notebook)
            notebook.add(custom_frame, text="Custom Configuration")
            self.setup_custom_tab(custom_frame)
            
            # Actions frame
            actions_frame = ttk.Frame(main_frame)
            actions_frame.pack(fill=tk.X, pady=(10, 0))
            
            # Load/Save buttons
            ttk.Button(actions_frame, text="Load Config File", 
                      command=self.load_config_file).pack(side=tk.LEFT, padx=(0, 5))
            ttk.Button(actions_frame, text="Save Config File", 
                      command=self.save_config_file).pack(side=tk.LEFT, padx=(0, 5))
            ttk.Button(actions_frame, text="Validate Configuration", 
                      command=self.validate_config).pack(side=tk.LEFT, padx=(0, 5))
            ttk.Button(actions_frame, text="Generate & Save", 
                      command=self.generate_and_save).pack(side=tk.RIGHT)
            
        def setup_predefined_tab(self, parent):
            # Instructions
            inst_label = ttk.Label(parent, text="Select a predefined configuration:")
            inst_label.pack(anchor=tk.W, pady=(0, 10))
            
            # Predefined configurations listbox
            list_frame = ttk.Frame(parent)
            list_frame.pack(fill=tk.BOTH, expand=True)
            
            # Listbox with scrollbar
            scrollbar = ttk.Scrollbar(list_frame)
            scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
            
            self.config_listbox = tk.Listbox(list_frame, yscrollcommand=scrollbar.set)
            self.config_listbox.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
            scrollbar.config(command=self.config_listbox.yview)
            
            # Populate listbox
            for name, display_name, description in self.generator.list_predefined_configs():
                self.config_listbox.insert(tk.END, f"{display_name} ({name})")
            
            self.config_listbox.bind('<<ListboxSelect>>', self.on_predefined_select)
            
            # Description area
            desc_label = ttk.Label(parent, text="Description:")
            desc_label.pack(anchor=tk.W, pady=(10, 5))
            
            self.description_text = tk.Text(parent, height=4, wrap=tk.WORD, state=tk.DISABLED)
            self.description_text.pack(fill=tk.X, pady=(0, 10))
            
            # Load button
            ttk.Button(parent, text="Load Selected Configuration", 
                      command=self.load_predefined_config).pack()
            
        def setup_custom_tab(self, parent):
            # Create scrollable frame
            canvas = tk.Canvas(parent)
            scrollbar = ttk.Scrollbar(parent, orient="vertical", command=canvas.yview)
            scrollable_frame = ttk.Frame(canvas)
            
            scrollable_frame.bind(
                "<Configure>",
                lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
            )
            
            canvas.create_window((0, 0), window=scrollable_frame, anchor="nw")
            canvas.configure(yscrollcommand=scrollbar.set)
            
            canvas.pack(side="left", fill="both", expand=True)
            scrollbar.pack(side="right", fill="y")
            
            # Group options by category
            categories = {}
            for option_name, option_info in CONFIG_OPTIONS.items():
                category = option_info.get('category', 'Other')
                if category not in categories:
                    categories[category] = []
                categories[category].append((option_name, option_info))
            
            # Create UI for each category
            for category, options in categories.items():
                # Category frame
                cat_frame = ttk.LabelFrame(scrollable_frame, text=category, padding=10)
                cat_frame.pack(fill=tk.X, padx=5, pady=5)
                
                for option_name, option_info in options:
                    self.create_option_widget(cat_frame, option_name, option_info)
            
            # Bind mousewheel to canvas
            def on_mousewheel(event):
                canvas.yview_scroll(int(-1*(event.delta/120)), "units")
            canvas.bind_all("<MouseWheel>", on_mousewheel)
            
        def create_option_widget(self, parent, option_name, option_info):
            option_frame = ttk.Frame(parent)
            option_frame.pack(fill=tk.X, pady=2)
            
            description = option_info['description']
            
            if option_info.get('type') == 'value':
                # Value-based option
                ttk.Label(option_frame, text=description).pack(anchor=tk.W)
                var = tk.StringVar(value=option_info['default'])
                entry = ttk.Entry(option_frame, textvariable=var)
                entry.pack(fill=tk.X, pady=(2, 0))
                self.config_vars[option_name] = var
            else:
                # Boolean option
                var = tk.BooleanVar(value=option_info['default'])
                cb = ttk.Checkbutton(option_frame, text=description, variable=var)
                cb.pack(anchor=tk.W)
                self.config_vars[option_name] = var
                
                # Add dependency note if applicable
                depends_on = option_info.get('depends_on')
                if depends_on:
                    dep_label = ttk.Label(option_frame, text=f"  (Requires: {depends_on})", 
                                        foreground='gray')
                    dep_label.pack(anchor=tk.W)
        
        def on_predefined_select(self, event):
            selection = self.config_listbox.curselection()
            if selection:
                index = selection[0]
                configs = list(PREDEFINED_CONFIGS.items())
                if index < len(configs):
                    name, info = configs[index]
                    
                    # Update description
                    self.description_text.config(state=tk.NORMAL)
                    self.description_text.delete(1.0, tk.END)
                    self.description_text.insert(1.0, info['description'])
                    self.description_text.config(state=tk.DISABLED)
        
        def load_predefined_config(self):
            selection = self.config_listbox.curselection()
            if not selection:
                messagebox.showwarning("No Selection", "Please select a configuration first.")
                return
            
            index = selection[0]
            configs = list(PREDEFINED_CONFIGS.items())
            if index < len(configs):
                name, info = configs[index]
                config = info['options']
                self.apply_config_to_ui(config)
                messagebox.showinfo("Success", f"Loaded configuration: {info['name']}")
        
        def apply_config_to_ui(self, config):
            """Apply configuration values to UI elements."""
            for option_name, var in self.config_vars.items():
                if option_name in config:
                    var.set(config[option_name])
                else:
                    # Set to default
                    default = CONFIG_OPTIONS[option_name]['default']
                    var.set(default)
        
        def get_config_from_ui(self):
            """Get current configuration from UI elements."""
            config = {}
            for option_name, var in self.config_vars.items():
                value = var.get()
                # Only include non-default values
                default = CONFIG_OPTIONS[option_name]['default']
                if value != default:
                    config[option_name] = value
            return config
        
        def load_config_file(self):
            filename = filedialog.askopenfilename(
                title="Load Configuration File",
                filetypes=[("Verilog Header", "*.vh"), ("All Files", "*.*")]
            )
            if filename:
                try:
                    config = self.generator.parse_existing_config(filename)
                    self.apply_config_to_ui(config)
                    messagebox.showinfo("Success", f"Loaded configuration from: {filename}")
                except Exception as e:
                    messagebox.showerror("Error", f"Failed to load configuration: {e}")
        
        def save_config_file(self):
            filename = filedialog.asksaveasfilename(
                title="Save Configuration File",
                defaultextension=".vh",
                filetypes=[("Verilog Header", "*.vh"), ("All Files", "*.*")]
            )
            if filename:
                self.generate_config_file(filename)
        
        def validate_config(self):
            config = self.get_config_from_ui()
            is_valid, errors = self.generator.validate_config(config)
            
            if is_valid:
                messagebox.showinfo("Validation", "Configuration is valid!")
            else:
                error_msg = "Configuration errors found:\n\n" + "\n".join(f"• {error}" for error in errors)
                messagebox.showerror("Validation Errors", error_msg)
        
        def generate_and_save(self):
            filename = filedialog.asksaveasfilename(
                title="Generate and Save Configuration",
                defaultextension=".vh",
                filetypes=[("Verilog Header", "*.vh"), ("All Files", "*.*")]
            )
            if filename:
                if self.generate_config_file(filename):
                    messagebox.showinfo("Success", f"Configuration generated and saved to:\n{filename}")
        
        def generate_config_file(self, filename):
            config = self.get_config_from_ui()
            
            # Validate first
            is_valid, errors = self.generator.validate_config(config)
            if not is_valid:
                error_msg = "Configuration errors found:\n\n" + "\n".join(f"• {error}" for error in errors)
                messagebox.showerror("Validation Errors", error_msg)
                return False
            
            try:
                success = self.generator.generate_config_file(config, filename, "Custom Configuration")
                return success
            except Exception as e:
                messagebox.showerror("Error", f"Failed to generate configuration: {e}")
                return False
    
    # Create and run GUI
    root = tk.Tk()
    app = VignaConfigGUI(root)
    root.mainloop()


if __name__ == "__main__":
    cli_interface()