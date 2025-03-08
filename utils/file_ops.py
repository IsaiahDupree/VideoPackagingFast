"""
File operations utilities for the Video Processor application.
"""
import os
import json
import logging
import shutil
import platform
import subprocess
import tempfile

logger = logging.getLogger("VideoProcessor")

def load_results(folder_path, terminal_output_func=None):
    """Load results from a folder and return a TreeData object for display"""
    import PySimpleGUI as sg
    
    try:
        treedata = sg.TreeData()
        
        for root, dirs, files in os.walk(folder_path):
            # Only show our output files
            files = [f for f in files if f in ["transcript.txt", "social_media.txt", "social_media.json"]]
            
            if files:  # Only add folders that have our output files
                folder = os.path.basename(root)
                parent = os.path.dirname(root)
                parent_key = os.path.basename(parent) if parent != folder_path else ""
                
                if parent_key:
                    treedata.Insert(parent_key, folder, folder, [root])
                else:
                    treedata.Insert("", folder, folder, [root])
                
                for file in files:
                    file_path = os.path.join(root, file)
                    try:
                        if file.endswith('.json'):
                            with open(file_path, 'r', encoding='utf-8') as f:
                                content = json.load(f)
                                size = len(json.dumps(content, ensure_ascii=False))
                        else:
                            size = os.path.getsize(file_path)
                        treedata.Insert(folder, os.path.join(folder, file), "{} ({})".format(file, size), [file_path])
                    except Exception as e:
                        logger.error("Error reading file {}: {}".format(file, str(e)))
                        treedata.Insert(folder, os.path.join(folder, file), "{} (error reading)".format(file), [file_path])
        
        if terminal_output_func:
            terminal_output_func(f"Loaded results from: {folder_path}")
            
        return treedata
    except Exception as e:
        logger.error(f"Error loading results: {str(e)}")
        if terminal_output_func:
            terminal_output_func(f"Error loading results: {str(e)}", "ERROR")
        return sg.TreeData()

def display_file_content(file_path, terminal_output_func=None):
    """Read and format file content for display"""
    try:
        if file_path.endswith('.json'):
            with open(file_path, 'r', encoding='utf-8') as f:
                content = json.load(f)
                # Format JSON content for better readability
                formatted_content = json.dumps(content, indent=2, ensure_ascii=False)
                
            if terminal_output_func:
                terminal_output_func(f"Viewing file: {os.path.basename(file_path)}")
                
            return formatted_content
        else:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                
            if terminal_output_func:
                terminal_output_func(f"Viewing file: {os.path.basename(file_path)}")
                
            return content
    except Exception as e:
        error_msg = f"Error reading file: {str(e)}"
        logger.error(error_msg)
        
        if terminal_output_func:
            terminal_output_func(error_msg, "ERROR")
            
        return error_msg

def ensure_directory_exists(directory_path):
    """
    Ensure a directory exists, creating it if necessary.
    
    Args:
        directory_path (str): Path to the directory
        
    Returns:
        bool: True if the directory exists or was created successfully, False otherwise
    """
    try:
        os.makedirs(directory_path, exist_ok=True)
        return True
    except Exception as e:
        logger.error(f"Error creating directory {directory_path}: {str(e)}")
        return False

def get_temp_directory():
    """
    Get a platform-appropriate temporary directory.
    
    Returns:
        str: Path to a temporary directory
    """
    return tempfile.gettempdir()

def get_documents_directory():
    """
    Get the user's Documents directory in a platform-agnostic way.
    
    Returns:
        str: Path to the user's Documents directory
    """
    if platform.system() == 'Windows':
        return os.path.expanduser('~\\Documents')
    else:  # macOS or Linux
        return os.path.expanduser('~/Documents')

def open_file_explorer(path):
    """
    Open the file explorer at the specified path in a platform-agnostic way.
    
    Args:
        path (str): Path to open in file explorer
        
    Returns:
        bool: True if successful, False otherwise
    """
    try:
        if platform.system() == 'Windows':
            os.startfile(path)
        elif platform.system() == 'Darwin':  # macOS
            subprocess.run(['open', path], check=True)
        else:  # Linux
            subprocess.run(['xdg-open', path], check=True)
        return True
    except Exception as e:
        logger.error(f"Error opening file explorer at {path}: {str(e)}")
        return False

def is_valid_video_file(file_path):
    """Check if a file is a valid video file"""
    try:
        # List of common video file extensions
        video_extensions = ['.mp4', '.avi', '.mov', '.mkv', '.wmv', '.flv', '.webm', '.m4v', '.3gp', '.mpeg', '.mpg']
        _, ext = os.path.splitext(file_path)
        
        # Check if the extension is in our list
        if ext.lower() not in video_extensions:
            return False
            
        # Check if the file exists and is not empty
        if not os.path.exists(file_path) or os.path.getsize(file_path) == 0:
            return False
            
        # Try to open the file with moviepy to verify it's a valid video
        try:
            from moviepy.editor import VideoFileClip
            clip = VideoFileClip(file_path)
            duration = clip.duration  # This will fail if the file is not a valid video
            clip.close()
            return True
        except Exception:
            # If moviepy fails, try ffprobe as a fallback
            try:
                import subprocess
                result = subprocess.run(
                    ['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'default=noprint_wrappers=1:nokey=1', file_path],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True
                )
                # If we get a duration, it's likely a valid video
                return result.returncode == 0 and float(result.stdout.strip()) > 0
            except Exception:
                return False
    except Exception:
        return False

def create_backup(file_path):
    """Create a backup of a file"""
    try:
        if os.path.exists(file_path):
            backup_path = f"{file_path}.bak"
            shutil.copy2(file_path, backup_path)
            return backup_path
        return None
    except Exception as e:
        logger.error(f"Error creating backup of {file_path}: {str(e)}")
        return None

def restore_from_backup(backup_path, target_path):
    """Restore a file from its backup"""
    try:
        if os.path.exists(backup_path):
            shutil.copy2(backup_path, target_path)
            return True
        return False
    except Exception as e:
        logger.error(f"Error restoring from backup {backup_path}: {str(e)}")
        return False

def get_file_metadata(file_path):
    """Get metadata for a file"""
    metadata = {
        "exists": os.path.exists(file_path),
        "size": os.path.getsize(file_path) if os.path.exists(file_path) else 0,
        "modified": os.path.getmtime(file_path) if os.path.exists(file_path) else 0,
        "type": os.path.splitext(file_path)[1].lower() if os.path.exists(file_path) else "",
    }
    
    # For video files, try to get duration
    if metadata["exists"] and metadata["type"] in ['.mp4', '.avi', '.mov', '.mkv', '.wmv', '.flv', '.webm']:
        try:
            from moviepy.editor import VideoFileClip
            clip = VideoFileClip(file_path)
            metadata["duration"] = clip.duration
            metadata["width"] = clip.size[0]
            metadata["height"] = clip.size[1]
            clip.close()
        except Exception as e:
            logger.error(f"Error getting video metadata for {file_path}: {str(e)}")
    
    return metadata

def safe_delete(file_path):
    """Safely delete a file with error handling"""
    try:
        if os.path.exists(file_path):
            os.remove(file_path)
            return True
        return False
    except Exception as e:
        logger.error(f"Error deleting file {file_path}: {str(e)}")
        return False

def safe_read_json(file_path, default=None):
    """Safely read a JSON file with error handling and recovery"""
    if default is None:
        default = {}
        
    # Try to read the file
    try:
        if os.path.exists(file_path):
            with open(file_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        return default
    except json.JSONDecodeError:
        # If JSON is invalid, try to recover from backup
        backup_path = f"{file_path}.bak"
        if os.path.exists(backup_path):
            try:
                with open(backup_path, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except:
                pass
        return default
    except Exception as e:
        logger.error(f"Error reading JSON file {file_path}: {str(e)}")
        return default

def safe_write_json(file_path, data):
    """Safely write a JSON file with backup"""
    try:
        # Create backup of existing file
        if os.path.exists(file_path):
            create_backup(file_path)
            
        # Write new data
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        return True
    except Exception as e:
        logger.error(f"Error writing JSON file {file_path}: {str(e)}")
        return False
