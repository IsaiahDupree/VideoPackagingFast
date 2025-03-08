"""
Configuration management for the Video Processor application.
Handles environment variables, API keys, and other configuration settings.
"""
import os
import json
import logging
from pathlib import Path
from dotenv import load_dotenv

logger = logging.getLogger("VideoProcessor")

# Load environment variables from .env file if it exists
env_path = Path('.env')
if env_path.exists():
    load_dotenv(dotenv_path=env_path)
else:
    # Create .env file with default settings if it doesn't exist
    logger.info("Creating default .env file")
    with open('.env', 'w') as f:
        f.write("# Video Processor Configuration\n")
        f.write("# API Keys - DO NOT SHARE THESE VALUES\n")
        f.write("OPENAI_API_KEY=\n")
        f.write("\n# Application Settings\n")
        f.write("DEBUG_MODE=False\n")
    load_dotenv(dotenv_path=env_path)

def get_api_key(key_name="OPENAI_API_KEY", default_value=None):
    """
    Get API key from environment variables.
    If not found, returns the default value.
    """
    api_key = os.getenv(key_name, default_value)
    if not api_key:
        logger.warning(f"{key_name} not found in environment variables")
    return api_key

def set_api_key(api_key, key_name="OPENAI_API_KEY"):
    """
    Set API key in environment variables and .env file.
    Returns True if successful, False otherwise.
    """
    try:
        # Update in-memory environment variable
        os.environ[key_name] = api_key
        
        # Update .env file
        env_content = ""
        if os.path.exists('.env'):
            with open('.env', 'r') as f:
                lines = f.readlines()
                key_found = False
                for i, line in enumerate(lines):
                    if line.startswith(f"{key_name}="):
                        lines[i] = f"{key_name}={api_key}\n"
                        key_found = True
                if not key_found:
                    lines.append(f"{key_name}={api_key}\n")
                env_content = "".join(lines)
        else:
            env_content = f"{key_name}={api_key}\n"
        
        with open('.env', 'w') as f:
            f.write(env_content)
        
        logger.info(f"{key_name} updated successfully")
        return True
    except Exception as e:
        logger.error(f"Error setting {key_name}: {str(e)}")
        return False

def get_app_settings():
    """
    Get application settings from environment variables.
    Returns a dictionary of settings.
    """
    settings = {
        "debug_mode": os.getenv("DEBUG_MODE", "False").lower() == "true",
        # Add more settings as needed
    }
    return settings

# Default configuration
DEFAULT_CONFIG = {
    "openai": {
        "model": "gpt-4",
        "temperature": 0.7,
        "max_tokens": 1000
    },
    "whisper": {
        "model": "base",
        "language": "en"
    },
    "processing": {
        "chunk_size": 10 * 60,  # 10 minutes in seconds
        "overlap": 30,  # 30 seconds overlap between chunks
        "max_threads": 4
    },
    "ui": {
        "theme": "Default Blue"
    }
}

def load_config(config_path="config.json"):
    """
    Load configuration from a JSON file.
    If the file doesn't exist, creates it with default values.
    """
    try:
        if os.path.exists(config_path):
            with open(config_path, 'r') as f:
                config = json.load(f)
            # Merge with defaults for any missing keys
            for section, values in DEFAULT_CONFIG.items():
                if section not in config:
                    config[section] = values
                else:
                    for key, value in values.items():
                        if key not in config[section]:
                            config[section][key] = value
        else:
            config = DEFAULT_CONFIG
            with open(config_path, 'w') as f:
                json.dump(config, f, indent=4)
            logger.info(f"Created default configuration file: {config_path}")
        
        return config
    except Exception as e:
        logger.error(f"Error loading configuration: {str(e)}")
        return DEFAULT_CONFIG

def save_config(config, config_path="config.json"):
    """
    Save configuration to a JSON file.
    """
    try:
        with open(config_path, 'w') as f:
            json.dump(config, f, indent=4)
        logger.info(f"Configuration saved to {config_path}")
        return True
    except Exception as e:
        logger.error(f"Error saving configuration: {str(e)}")
        return False
