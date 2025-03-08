"""
Theme management for the Video Processor application.
Provides a collection of themes and functions to apply them.
"""
import PySimpleGUI as sg
import pkg_resources

# Get PySimpleGUI version
try:
    sg_version = pkg_resources.get_distribution("PySimpleGUI").version
    sg_major_version = int(sg_version.split('.')[0])
except:
    # If we can't determine the version, assume it's the latest
    sg_major_version = 5

# Define a collection of themes with custom colors and settings
THEMES = {
    "Default Blue": {
        "BACKGROUND": "#F0F0F0",
        "TEXT": "#000000",
        "INPUT": "#FFFFFF",
        "TEXT_INPUT": "#000000",
        "SCROLL": "#E3E3E3",
        "BUTTON": ("#FFFFFF", "#1E6FBA"),
        "PROGRESS": ("#1E6FBA", "#FFFFFF"),
        "BORDER": 1,
        "SLIDER_DEPTH": 0,
        "PROGRESS_DEPTH": 0,
        "COLOR_LIST": ["#1E6FBA", "#5DA7E4", "#98C6EA", "#FFFFFF", "#E3E3E3"],
        "DESCRIPTION": "Default blue theme with a professional look"
    },
    "Dark Mode": {
        "BACKGROUND": "#2E2E2E",
        "TEXT": "#FFFFFF",
        "INPUT": "#444444",
        "TEXT_INPUT": "#FFFFFF",
        "SCROLL": "#444444",
        "BUTTON": ("#FFFFFF", "#444444"),
        "PROGRESS": ("#00A1D8", "#2E2E2E"),
        "BORDER": 1,
        "SLIDER_DEPTH": 0,
        "PROGRESS_DEPTH": 0,
        "COLOR_LIST": ["#00A1D8", "#2E2E2E", "#444444", "#FFFFFF", "#AAAAAA"],
        "DESCRIPTION": "Dark theme that's easy on the eyes"
    },
    "Forest Green": {
        "BACKGROUND": "#F0F7EE",
        "TEXT": "#333333",
        "INPUT": "#FFFFFF",
        "TEXT_INPUT": "#333333",
        "SCROLL": "#DDEAD1",
        "BUTTON": ("#FFFFFF", "#4B7F52"),
        "PROGRESS": ("#4B7F52", "#FFFFFF"),
        "BORDER": 1,
        "SLIDER_DEPTH": 0,
        "PROGRESS_DEPTH": 0,
        "COLOR_LIST": ["#4B7F52", "#7FB77E", "#B1D8B7", "#FFFFFF", "#DDEAD1"],
        "DESCRIPTION": "Calming green theme inspired by nature"
    },
    "Sunset Orange": {
        "BACKGROUND": "#FFF8F0",
        "TEXT": "#333333",
        "INPUT": "#FFFFFF",
        "TEXT_INPUT": "#333333",
        "SCROLL": "#FFE6CC",
        "BUTTON": ("#FFFFFF", "#E67E22"),
        "PROGRESS": ("#E67E22", "#FFFFFF"),
        "BORDER": 1,
        "SLIDER_DEPTH": 0,
        "PROGRESS_DEPTH": 0,
        "COLOR_LIST": ["#E67E22", "#F39C12", "#FFCC99", "#FFFFFF", "#FFE6CC"],
        "DESCRIPTION": "Warm orange theme inspired by sunsets"
    },
    "Purple Haze": {
        "BACKGROUND": "#F5F0FF",
        "TEXT": "#333333",
        "INPUT": "#FFFFFF",
        "TEXT_INPUT": "#333333",
        "SCROLL": "#E6D9FF",
        "BUTTON": ("#FFFFFF", "#8E44AD"),
        "PROGRESS": ("#8E44AD", "#FFFFFF"),
        "BORDER": 1,
        "SLIDER_DEPTH": 0,
        "PROGRESS_DEPTH": 0,
        "COLOR_LIST": ["#8E44AD", "#9B59B6", "#D2B4DE", "#FFFFFF", "#E6D9FF"],
        "DESCRIPTION": "Elegant purple theme for a creative feel"
    }
}

def apply_theme(theme_name):
    """
    Apply a theme from the THEMES dictionary
    
    Args:
        theme_name (str): Name of the theme to apply
        
    Returns:
        bool: True if theme was applied successfully, False otherwise
    """
    if theme_name in THEMES:
        # Handle different PySimpleGUI versions
        if sg_major_version < 5 and hasattr(sg, 'theme_add_new'):
            # For PySimpleGUI version 4.x
            sg.theme_add_new(theme_name, THEMES[theme_name])
            sg.theme(theme_name)
            return True
        else:
            # For PySimpleGUI version 5.x+
            # Use a built-in theme that's closest to our custom theme
            fallback_themes = {
                "Default Blue": "BlueMono",
                "Dark Mode": "DarkGrey9",
                "Forest Green": "DarkGreen3",
                "Sunset Orange": "DarkAmber",
                "Purple Haze": "DarkPurple"
            }
            fallback_theme = fallback_themes.get(theme_name, "Default")
            sg.theme(fallback_theme)
            return True
    elif theme_name in sg.theme_list():
        # If it's a built-in PySimpleGUI theme
        sg.theme(theme_name)
        return True
    else:
        # Default to a standard theme if requested theme not found
        sg.theme("Default")
        return False

def get_all_themes():
    """
    Get a list of all available themes
    
    Returns:
        list: Combined list of custom themes and built-in PySimpleGUI themes
    """
    # Combine our custom themes with PySimpleGUI's built-in themes
    return list(THEMES.keys()) + [t for t in sg.theme_list() if t not in THEMES]
