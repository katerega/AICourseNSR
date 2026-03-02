from urllib import response
from openai import OpenAI 
import os
from actions import get_response_time 
from dotenv import load_dotenv
from actions import get_response_time
from prompts import system_prompt

# load enviroment variables
load_dotenv()

#Create an instance of the OpenAI class
openai_client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

def generate_text_with_conversation(messages, model = "gpt-3.5-turbo"):
    response = openai_client.chat.completions.create(
        model=model,
        messages=messages
    )
    return response.choices[0].message.content

    #Available Actions are:
    available_actions = {
        "get_response_time": get_response_time
    }

    #define the prompt ie what you are going to ask this agent
    user_prompt = "what is the response time of google.com" 

    messages = [
        {"role": "system", "content: system_prompt"},
        {"role": "user", "content": user_prompt},
    ]

    turn_count = 1
    max_turns = 5

    while turn_count < max_turns:
        print(f"Loop: {turn_count}")
        print("--------------------")
        turn_count +=1

        response = generate_text_with_conversation

