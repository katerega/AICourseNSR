import logging
import configparser
from typing import Dict, List
import json
from datetime import datetime, timedelta
import requests
from requests.exceptions import RequestException
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
import os
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import smtplib
import re

# Setup for logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s', filename='client_intake_agent.log', filemode='a')
logger = logging.getLogger(__name__)

# Configuration
config = configparser.ConfigParser()
config.read('config.ini')  # Assume we have a config file

# Constants
MAX_RETRIES = 3
BACKOFF_FACTOR = 0.3
DEFAULT_TIMEOUT = 10
INTAKE_FIELDS = ['name', 'email', 'phone', 'company', 'industry', 'service_needed', 'budget', 'project_start_date']
EMAIL_REGEX = re.compile(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")

class ClientIntakeAI:
    def __init__(self):
        self.session = self._create_session()
        self.api_key = os.getenv('CRM_API_KEY', config.get('API', 'crm_api_key'))
        self.intake_fields = config.get('Intake', 'fields', fallback=','.join(INTAKE_FIELDS)).split(',')
        self.email_config = {
            'server': config.get('Email', 'smtp_server'),
            'port': int(config.get('Email', 'smtp_port')),
            'sender': config.get('Email', 'sender_email'),
            'password': os.getenv('EMAIL_PASSWORD', config.get('Email', 'sender_password'))
        }

    def _create_session(self):
        """
        Create a requests session with retry logic for robustness.
        """
        session = requests.Session()
        retry = Retry(
            total=MAX_RETRIES,
            read=MAX_RETRIES,
            connect=MAX_RETRIES,
            backoff_factor=BACKOFF_FACTOR,
            status_forcelist=[429, 500, 502, 503, 504],
            method_whitelist=frozenset(['GET', 'POST'])
        )
        adapter = HTTPAdapter(max_retries=retry)
        session.mount('https://', adapter)
        session.mount('http://', adapter)
        return session

    def collect_client_data(self) -> Dict:
        """
        Collects client data, typically through an API or form submission.

        :return: A dictionary of client details.
        """
        # Here, you would integrate with a real form or API endpoint to collect client data
        # For this example, we'll simulate with mock data
        client_data = {}
        for field in self.intake_fields:
            client_data[field] = input(f"Please enter {field}: ") if field != 'project_start_date' else self._get_project_date()
        return client_data

    def _get_project_date(self) -> str:
        """
        Helper to get a valid project start date from user input.

        :return: ISO formatted date string.
        """
        while True:
            try:
                date_str = input("Please enter project start date (YYYY-MM-DD): ")
                project_date = datetime.strptime(date_str, "%Y-%m-%d")
                if project_date < datetime.now():
                    print("Project start date cannot be in the past.")
                else:
                    return project_date.isoformat()
            except ValueError:
                print("Invalid date format. Please try again.")

    def validate_client_data(self, client_data: Dict) -> Dict:
        """
        Validates client data for completeness and correctness with more stringent checks.

        :param client_data: Dictionary containing client information.
        :return: Validation result dictionary.
        """
        errors = {}
        for field in self.intake_fields:
            if field not in client_data or not client_data[field]:
                errors[field] = "This field is required"
            elif field == 'email' and not EMAIL_REGEX.match(client_data[field]):
                errors[field] = "Invalid email format"
            elif field == 'phone' and not client_data[field].isdigit():
                errors[field] = "Phone number should only contain digits"
            elif field == 'budget':
                try:
                    float(client_data[field])
                except ValueError:
                    errors[field] = "Budget must be a number"
        return errors if errors else {'valid': True}

    def process_intake(self, client_data: Dict) -> Dict:
        """
        Process client intake by creating an account in CRM, scheduling an initial meeting, and sending a welcome email.

        :param client_data: Dictionary with client details.
        :return: A dictionary with actions taken or errors.
        """
        validation = self.validate_client_data(client_data)
        if not validation.get('valid', False):
            return {'status': 'error', 'errors': validation}

        try:
            # CRM Integration
            crm_endpoint = config.get('API', 'crm_endpoint')
            headers = {'Authorization': f'Bearer {self.api_key}'}
            response = self.session.post(crm_endpoint, headers=headers, json=client_data, timeout=DEFAULT_TIMEOUT)
            response.raise_for_status()
            client_id = response.json().get('id')

            # Schedule Meeting
            meeting_endpoint = config.get('API', 'meeting_endpoint')
            meeting_data = {'client_id': client_id, 'date': client_data['project_start_date']}
            meeting_response = self.session.post(meeting_endpoint, headers=headers, json=meeting_data, timeout=DEFAULT_TIMEOUT)
            meeting_response.raise_for_status()
            meeting_id = meeting_response.json().get('id')

            # Send Welcome Email
            self._send_welcome_email(client_data)

            return {
                'status': 'success',
                'client_id': client_id,
                'meeting_id': meeting_id,
                'message': f"Client intake successful. Meeting scheduled for {client_data['project_start_date']}."
            }
        except RequestException as e:
            logger.error(f"Failed to process intake: {e}")
            return {'status': 'error', 'message': f"An error occurred: {str(e)}"}

    def _send_welcome_email(self, client_data: Dict):
        """
        Sends a welcome email to the client using SMTP.

        :param client_data: Dictionary containing client's email address.
        """
        email_body = f"""
        Dear {client_data['name']},

        Thank you for choosing us. We've scheduled your initial meeting for {client_data['project_start_date']}.
        Looking forward to working with you!

        Best regards,
        Your Company
        """

        msg = MIMEMultipart()
        msg['From'] = self.email_config['sender']
        msg['To'] = client_data['email']
        msg['Subject'] = "Welcome to Our Service"
        msg.attach(MIMEText(email_body, 'plain'))

        try:
            with smtplib.SMTP(self.email_config['server'], self.email_config['port']) as server:
                server.starttls()
                server.login(self.email_config['sender'], self.email_config['password'])
                server.send_message(msg)
            logger.info(f"Welcome email sent to {client_data['email']}")
        except Exception as e:
            logger.error(f"Failed to send welcome email: {e}")

    def run(self):
        """
        Main method to run the client intake process.
        """
        logger.info("Starting Client Intake AI Agent")
        client_data = self.collect_client_data()
        result = self.process_intake(client_data)
        if result['status'] == 'success':
            logger.info(f"Client intake processed successfully: {result['message']}")
        else:
            logger.error(f"Client intake failed: {result.get('message', 'Unknown error')}")
            if 'errors' in result:
                logger.error(f"Validation errors: {json.dumps(result['errors'])}")
        logger.info("Client Intake Session Ended")

if __name__ == "__main__":
    try:
        agent = ClientIntakeAI()
        agent.run()
    except Exception as e:
        logger.error(f"An error occurred while running the Client Intake AI Agent: {e}")

# Note:
# - Ensure all API endpoints, authentication methods, and response formats match the actual services.
# - Implement real-time validation on the client-side for better user experience.
# - Use secure methods for storing and retrieving sensitive information like API keys and email passwords.
# - Add compliance checks for data protection laws like GDPR, particularly for email communication.
# - Consider adding more detailed logging for tracking each step of the intake process for auditing or debugging.