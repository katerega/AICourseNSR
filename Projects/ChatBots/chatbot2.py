import openai
#import openai

# Set your OpenAI API key
openai.api_key = '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'


#API_KEY = open("API_KEY", "r").read()
#openai.api_key = API_KEY

chat_log = []

while True:
    user_message = input()
    if user_message.lower() == "quit":
        break
    else:
        chat_log.append({"role": "user", "content": user_message})
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=chat_log
        )
        assistant_response = response['choices'][0]['message']['content']
        print("ChatGPT:", assistant_response.strip("\n").strip())
        chat_log.append({"role": "assistant", "content": assistant_response.strip("\n").strip()})

