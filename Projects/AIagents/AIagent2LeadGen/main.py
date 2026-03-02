import requests
from bs4 import BeautifulSoup
import re
import random
import logging
from urllib.parse import urlparse
import configparser

# Setting up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Configuration
config = configparser.ConfigParser()
config.read('config.ini')  # Assume we have a config file

class LeadGenerationAI:
    def __init__(self):
        self.leads = []
        self.scraped_data = []
        self.max_leads = int(config.get('Leads', 'max_leads', fallback=100))

    def scrape_leads(self, url):
        """
        Simulates web scraping for leads with error handling.
        """
        try:
            response = requests.get(url, timeout=10)  # Timeout to prevent hanging requests
            response.raise_for_status()  # Raise exception for non-2xx status
            soup = BeautifulSoup(response.text, 'html.parser')
            domain = urlparse(url).netloc
            emails = re.findall(r"[a-z0-9\.\-+_]+@[a-z0-9\.\-+_]+\.[a-z]+", soup.text)
            self.scraped_data.extend([email for email in emails if domain in email])  # Ensure email domain matches site domain
            logger.info(f"Scraped {len(emails)} emails from {url}")
        except requests.RequestException as e:
            logger.error(f"Error scraping from {url}: {e}")
        except Exception as e:
            logger.error(f"Unexpected error in scrape_leads: {e}")

    def qualify_leads(self):
        """
        Lead qualification with better criteria.
        """
        for lead in self.scraped_data:
            if 'business' in lead.split('@')[1] and len(self.leads) < self.max_leads:
                # Additional criteria could be added here, e.g., checking for specific keywords in the email
                self.leads.append({
                    'email': lead,
                    'score': random.randint(1, 10)
                })
        logger.info(f"Qualified {len(self.leads)} leads")

    def generate_outreach_message(self, lead):
        """
        Generates a personalized outreach message with more variability.
        """
        name = lead['email'].split('@')[0].capitalize()
        messages = [
            f"Hello {name}, we've identified your potential interest in innovative business tools. Could we discuss further?",
            f"{name}, your recent activities suggest you might benefit from our enterprise solutions. Are you open to a chat?",
            f"Hey {name}, your organization's profile matches our ideal client. Shall we schedule a brief meeting?"
        ]
        return random.choice(messages)

    def send_outreach(self):
        """
        Simulates sending outreach messages with error handling.
        """
        for lead in self.leads:
            try:
                message = self.generate_outreach_message(lead)
                # Here, you'd integrate with an actual email service API
                logger.info(f"Email sent to {lead['email']}: {message[:50]}...")  # Log only first 50 chars for privacy
            except Exception as e:
                logger.error(f"Failed to send email to {lead['email']}: {e}")

    def run(self, url):
        self.scrape_leads(url)
        self.qualify_leads()
        self.send_outreach()

if __name__ == "__main__":
    agent = LeadGenerationAI()
    try:
        agent.run(config.get('URL', 'target_url'))
    except KeyError:
        logger.error("Configuration file does not contain the target URL. Check 'config.ini'.")