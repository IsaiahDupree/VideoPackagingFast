"""
Logger module for the Video Processor application.
"""
import os
import logging
import datetime
from queue import Queue

# Create logs directory if it doesn't exist
LOG_DIR = os.path.expanduser("~/Documents/VideoProcessor_Logs")
os.makedirs(LOG_DIR, exist_ok=True)

# Global status queue for communication between threads
status_queue = Queue()

def setup_logger():
    """Set up and configure the application logger"""
    # Create a timestamp for the log file
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = os.path.join(LOG_DIR, f"video_processor_{timestamp}.log")
    
    # Configure the logger
    logger = logging.getLogger("VideoProcessor")
    logger.setLevel(logging.INFO)
    
    # Create file handler
    file_handler = logging.FileHandler(log_file)
    file_handler.setLevel(logging.INFO)
    
    # Create console handler
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)
    
    # Create formatter
    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
    file_handler.setFormatter(formatter)
    console_handler.setFormatter(formatter)
    
    # Add handlers to logger
    logger.addHandler(file_handler)
    logger.addHandler(console_handler)
    
    # Log application start
    logger.info(f"Application started. Log file: {log_file}")
    
    return logger

# Initialize the logger
logger = setup_logger()

def log_exception(logger, e, context="", terminal_output_func=None):
    """Log an exception with full traceback"""
    import traceback
    
    error_msg = f"{context}: {str(e)}"
    tb_str = traceback.format_exc()
    logger.error(error_msg)
    logger.error(tb_str)
    
    if terminal_output_func:
        terminal_output_func(error_msg, "ERROR")
        terminal_output_func("Traceback:", "ERROR")
        for line in tb_str.split('\n'):
            if line.strip():
                terminal_output_func(f"  {line}", "ERROR")
    
    return error_msg

def graceful_shutdown():
    """Perform cleanup operations before application shutdown"""
    logger.info("Performing graceful shutdown")
    # Add any cleanup operations here
    logger.info("Application shutdown complete")
