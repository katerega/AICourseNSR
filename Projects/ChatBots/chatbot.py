import openai

# Set your OpenAI API key
openai.api_key = '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'

def chatbot_response(prompt):
    try:
        # Call OpenAI API to get the response for the given prompt
        response = openai.Completion.create(
            engine="text-davinci-003",  # You can use other engines like "gpt-3.5-turbo" or newer versions
            prompt=prompt,
            max_tokens=150,  # The length of the response
            n=1,  # Number of responses to generate
            stop=None,  # Stop at a specific token (optional)
            temperature=0.7,  # Controls randomness (higher is more creative)
        )
        message = response.choices[0].text.strip()
        return message
    except Exception as e:
        print(f"Error: {e}")

def main():
    print("SLUNG Chatbot (Type 'quit' to exit)")
    
    while True:
        user_input = input("You: ")
        
        if user_input.lower() == 'quit':
            print("Goodbye!")
            break
        
        response = chatbot_response(user_input)
        print("AI: " + response)

if __name__ == "__main__":
    main()
