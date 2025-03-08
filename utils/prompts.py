"""
Prompt management utilities for the Video Processor application.
"""
import os
import json
import logging

# Default prompts
DEFAULT_SYSTEM_PROMPT = """You are an AI assistant that helps create social media content from video transcripts.
Your task is to generate engaging, concise, and platform-appropriate content based on the transcript provided.
Focus on extracting key points, interesting facts, and memorable quotes.
Format your response as a JSON object with fields for different social media platforms."""

DEFAULT_CONTENT_PROMPT = """Based on the following video transcript, create social media content for:
1. Twitter/X (280 characters max)
2. Instagram (engaging caption with relevant hashtags)
3. LinkedIn (professional tone, highlighting key insights)
4. YouTube (engaging description with timestamps if possible)

Include a suggested title for the video.

Transcript:
{transcript}

Format your response as a valid JSON object with the following structure:
{{
  "title": "Suggested Video Title",
  "twitter": "Twitter post content",
  "instagram": "Instagram caption with #hashtags",
  "linkedin": "LinkedIn post content",
  "youtube": "YouTube description"
}}"""

def load_prompts():
    """Load prompts from file or return defaults if file doesn't exist"""
    logger = logging.getLogger("VideoProcessor")
    
    try:
        if os.path.exists("ai_prompts.json"):
            with open("ai_prompts.json", "r", encoding="utf-8") as f:
                prompts = json.load(f)
                
            # Ensure all required prompts are present
            if "system_prompt" not in prompts:
                prompts["system_prompt"] = DEFAULT_SYSTEM_PROMPT
                logger.warning("System prompt not found in file, using default")
                
            if "content_generation_prompt" not in prompts:
                prompts["content_generation_prompt"] = DEFAULT_CONTENT_PROMPT
                logger.warning("Content generation prompt not found in file, using default")
                
            return prompts
        else:
            logger.info("Prompts file not found, using defaults")
            return {
                "system_prompt": DEFAULT_SYSTEM_PROMPT,
                "content_generation_prompt": DEFAULT_CONTENT_PROMPT
            }
    except Exception as e:
        logger.error(f"Error loading prompts: {str(e)}")
        return {
            "system_prompt": DEFAULT_SYSTEM_PROMPT,
            "content_generation_prompt": DEFAULT_CONTENT_PROMPT
        }

def save_prompts(prompts):
    """Save prompts to file"""
    logger = logging.getLogger("VideoProcessor")
    
    try:
        with open("ai_prompts.json", "w", encoding="utf-8") as f:
            json.dump(prompts, f, indent=2, ensure_ascii=False)
        logger.info("Prompts saved successfully")
        return True
    except Exception as e:
        logger.error(f"Error saving prompts: {str(e)}")
        return False
