# ============================================
# PYTHON CONCEPTS PRACTICE FILE
# ============================================

print("=" * 50)
print("PYTHON CONCEPTS PRACTICE")
print("=" * 50)

# ============================================
# 1. VARIABLES AND DATA TYPES
# ============================================
print("\n" + "=" * 50)
print("1. VARIABLES AND DATA TYPES")
print("=" * 50)

# Numbers (integer and float)
age = 25                    # Integer
price = 19.99              # Float (decimal)
temperature = -5           # Negative integer
pi = 3.14159               # Float

# Strings
name = "Alice"             # String with double quotes
message = 'Hello World!'   # String with single quotes
multiline_string = """This is
a multi-line
string"""

# Booleans
is_student = True          # Boolean (True/False)
is_raining = False
has_permission = True

# Type checking
print(f"age: {age} (type: {type(age)})")
print(f"price: {price} (type: {type(price)})")
print(f"name: '{name}' (type: {type(name)})")
print(f"is_student: {is_student} (type: {type(is_student)})")

# Type conversion
num_str = "123"
num_int = int(num_str)     # Convert string to integer
float_str = "45.67"
num_float = float(float_str) # Convert string to float
int_to_str = str(age)      # Convert integer to string

print(f"\nConverted '123' to integer: {num_int}")
print(f"Converted '45.67' to float: {num_float}")
print(f"Converted 25 to string: '{int_to_str}'")

# ============================================
# 2. BASIC OPERATIONS
# ============================================
print("\n" + "=" * 50)
print("2. BASIC OPERATIONS")
print("=" * 50)

# Arithmetic operations
x = 10
y = 3

print(f"x = {x}, y = {y}")
print(f"Addition (x + y): {x + y}")
print(f"Subtraction (x - y): {x - y}")
print(f"Multiplication (x * y): {x * y}")
print(f"Division (x / y): {x / y}")
print(f"Floor Division (x // y): {x // y}")
print(f"Modulus/Remainder (x % y): {x % y}")
print(f"Exponentiation (x ** y): {x ** y}")

# String operations
first_name = "John"
last_name = "Doe"

full_name = first_name + " " + last_name  # String concatenation
print(f"\nFull name: {full_name}")
print(f"Uppercase: {full_name.upper()}")
print(f"Lowercase: {full_name.lower()}")
print(f"Title case: {full_name.title()}")
print(f"Length of name: {len(full_name)} characters")
print(f"Does name contain 'Doe'? {'Doe' in full_name}")

# String slicing
text = "Python Programming"
print(f"\nOriginal text: {text}")
print(f"First 6 characters: {text[0:6]}")
print(f"From index 7 to end: {text[7:]}")
print(f"Last 11 characters: {text[-11:]}")
print(f"Every other character: {text[::2]}")

# ============================================
# 3. LISTS AND TUPLES
# ============================================
print("\n" + "=" * 50)
print("3. LISTS AND TUPLES")
print("=" * 50)

# Lists (mutable - can be changed)
fruits = ["apple", "banana", "orange", "grape"]
numbers = [1, 2, 3, 4, 5]
mixed_list = [1, "hello", True, 3.14]

print(f"Fruits list: {fruits}")
print(f"Second fruit: {fruits[1]}")
print(f"Last fruit: {fruits[-1]}")

# List operations
fruits.append("mango")           # Add item to end
fruits.insert(1, "blueberry")    # Insert at specific position
fruits.remove("banana")          # Remove specific item
popped = fruits.pop()            # Remove and return last item
fruits.sort()                    # Sort alphabetically

print(f"Modified fruits list: {fruits}")
print(f"Popped item: {popped}")
print(f"Number of fruits: {len(fruits)}")

# List slicing
numbers = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
print(f"\nNumbers list: {numbers}")
print(f"First 5 numbers: {numbers[:5]}")
print(f"Last 3 numbers: {numbers[-3:]}")
print(f"Numbers 3 to 7: {numbers[3:8]}")
print(f"Every other number: {numbers[::2]}")

# Tuples (immutable - cannot be changed)
colors = ("red", "green", "blue")
coordinates = (10.5, 20.3)

print(f"\nColors tuple: {colors}")
print(f"First color: {colors[0]}")
print(f"Number of colors: {len(colors)}")

# Trying to modify a tuple (will cause error if uncommented)
# colors[0] = "yellow"  # This will raise TypeError

# ============================================
# 4. CONDITIONALS (if/elif/else)
# ============================================
print("\n" + "=" * 50)
print("4. CONDITIONALS (if/elif/else)")
print("=" * 50)

# Simple if statement
temperature = 25
print(f"Temperature: {temperature}°C")

if temperature > 30:
    print("It's hot outside!")
elif temperature > 20:
    print("The weather is pleasant.")
elif temperature > 10:
    print("It's a bit cool.")
else:
    print("It's cold outside!")

# Multiple conditions
age = 18
has_license = True

print(f"\nAge: {age}, Has license: {has_license}")

if age >= 18 and has_license:
    print("You can drive a car.")
else:
    print("You cannot drive a car.")

# Checking if item is in list
favorite_fruits = ["apple", "banana", "mango"]
current_fruit = "banana"

print(f"\nFavorite fruits: {favorite_fruits}")
print(f"Current fruit: {current_fruit}")

if current_fruit in favorite_fruits:
    print(f"{current_fruit} is one of your favorite fruits!")
else:
    print(f"{current_fruit} is not in your favorite list.")

# ============================================
# 5. LOOPS (for and while)
# ============================================
print("\n" + "=" * 50)
print("5. LOOPS (for and while)")
print("=" * 50)

# For loop with list
print("Counting from 1 to 5:")
for i in range(1, 6):  # range(start, stop) goes from start to stop-1
    print(f"  Number: {i}")

# For loop iterating through list
print("\nFavorite colors:")
colors = ["red", "green", "blue", "yellow"]
for color in colors:
    print(f"  I like {color}")

# For loop with index
print("\nMonths with index:")
months = ["Jan", "Feb", "Mar", "Apr"]
for index, month in enumerate(months):
    print(f"  {index + 1}. {month}")

# While loop
print("\nCountdown:")
count = 5
while count > 0:
    print(f"  {count}...")
    count -= 1
print("  Blast off!")

# Loop control: break and continue
print("\nFinding first number divisible by 7:")
for num in range(1, 21):
    if num % 7 == 0:
        print(f"  Found: {num}")
        break
    print(f"  Checking {num}")

print("\nOdd numbers from 1 to 10:")
for num in range(1, 11):
    if num % 2 == 0:  # Skip even numbers
        continue
    print(f"  {num}")

# ============================================
# 6. FUNCTIONS
# ============================================
print("\n" + "=" * 50)
print("6. FUNCTIONS")
print("=" * 50)

# Basic function
def greet(name):
    """This function greets a person by name."""
    return f"Hello, {name}!"

# Function with parameters
def add_numbers(a, b):
    """Adds two numbers and returns the result."""
    return a + b

# Function with default parameter
def create_greeting(name, greeting="Hello"):
    """Creates a greeting with optional custom greeting."""
    return f"{greeting}, {name}!"

# Function that returns multiple values
def get_circle_info(radius):
    """Calculates area and circumference of a circle."""
    import math
    area = math.pi * radius ** 2
    circumference = 2 * math.pi * radius
    return area, circumference  # Returns a tuple

# Using the functions
print(greet("Alice"))
print(f"5 + 3 = {add_numbers(5, 3)}")
print(create_greeting("Bob"))
print(create_greeting("Charlie", "Good morning"))

circle_area, circle_circumference = get_circle_info(5)
print(f"Circle with radius 5: Area = {circle_area:.2f}, Circumference = {circle_circumference:.2f}")

# ============================================
# 7. DICTIONARIES
# ============================================
print("\n" + "=" * 50)
print("7. DICTIONARIES")
print("=" * 50)

# Creating dictionaries
student = {
    "name": "John Smith",
    "age": 20,
    "major": "Computer Science",
    "grades": [85, 90, 78, 92]
}

book = {
    "title": "The Python Guide",
    "author": "Jane Doe",
    "year": 2023,
    "pages": 350,
    "is_available": True
}

print(f"Student: {student}")
print(f"Book: {book}")

# Accessing dictionary values
print(f"\nStudent's name: {student['name']}")
print(f"Student's age: {student.get('age')}")
print(f"Book author: {book['author']}")

# Adding and modifying dictionary items
student["email"] = "john.smith@university.edu"  # Add new key-value pair
student["age"] = 21  # Update existing value

book["rating"] = 4.5  # Add new key-value pair

print(f"\nUpdated student: {student}")
print(f"Updated book: {book}")

# Dictionary methods
print(f"\nAll student keys: {list(student.keys())}")
print(f"All book values: {list(book.values())}")
print(f"All book items: {list(book.items())}")

# Looping through dictionaries
print("\nStudent information:")
for key, value in student.items():
    print(f"  {key}: {value}")

# Nested dictionary
library = {
    "book1": {"title": "Python Basics", "author": "Author A", "year": 2022},
    "book2": {"title": "Data Science", "author": "Author B", "year": 2023},
    "book3": {"title": "Web Development", "author": "Author C", "year": 2021}
}

print(f"\nNested dictionary (Library):")
for book_id, book_info in library.items():
    print(f"  {book_id}: {book_info['title']} by {book_info['author']} ({book_info['year']})")

# ============================================
# 8. SIMPLE PROJECT: NUMBER GUESSING GAME
# ============================================
print("\n" + "=" * 50)
print("8. SIMPLE PROJECT: NUMBER GUESSING GAME")
print("=" * 50)

def number_guessing_game():
    """A simple number guessing game."""
    import random
    
    print("Welcome to the Number Guessing Game!")
    print("I'm thinking of a number between 1 and 100.")
    
    secret_number = random.randint(1, 100)
    attempts = 0
    max_attempts = 10
    
    while attempts < max_attempts:
        try:
            guess = int(input(f"\nAttempt {attempts + 1}/{max_attempts}. Enter your guess: "))
            
            if guess < 1 or guess > 100:
                print("Please enter a number between 1 and 100.")
                continue
                
            attempts += 1
            
            if guess < secret_number:
                print("Too low! Try a higher number.")
            elif guess > secret_number:
                print("Too high! Try a lower number.")
            else:
                print(f"🎉 Congratulations! You guessed the number in {attempts} attempts!")
                return
                
            # Give a hint after a few attempts
            if attempts == 5:
                if secret_number % 2 == 0:
                    print("💡 Hint: The number is even.")
                else:
                    print("💡 Hint: The number is odd.")
                    
        except ValueError:
            print("Invalid input! Please enter a number.")
    
    print(f"\nGame over! The secret number was {secret_number}.")
    print("Better luck next time!")

# Uncomment the line below to play the game:
# number_guessing_game()

# ============================================
# 9. SIMPLE PROJECT: TODO LIST MANAGER
# ============================================
print("\n" + "=" * 50)
print("9. SIMPLE PROJECT: TODO LIST MANAGER")
print("=" * 50)

def todo_list_manager():
    """A simple command-line todo list manager."""
    
    tasks = []  # List to store tasks
    task_id = 1  # ID for each task
    
    print("Welcome to your Todo List Manager!")
    print("Commands: add, view, complete, delete, exit")
    
    while True:
        print("\n" + "-" * 40)
        command = input("Enter command: ").lower().strip()
        
        if command == "exit":
            print("Goodbye! Have a productive day!")
            break
            
        elif command == "add":
            description = input("Enter task description: ").strip()
            if description:
                tasks.append({"id": task_id, "description": description, "completed": False})
                print(f"Task added with ID: {task_id}")
                task_id += 1
            else:
                print("Task description cannot be empty!")
                
        elif command == "view":
            if not tasks:
                print("No tasks in your list.")
            else:
                print("\nYour Tasks:")
                print("-" * 40)
                for task in tasks:
                    status = "✓" if task["completed"] else "○"
                    print(f"{task['id']}. [{status}] {task['description']}")
                    
        elif command == "complete":
            try:
                task_id_to_complete = int(input("Enter task ID to mark as complete: "))
                found = False
                for task in tasks:
                    if task["id"] == task_id_to_complete:
                        task["completed"] = True
                        print(f"Task {task_id_to_complete} marked as complete!")
                        found = True
                        break
                if not found:
                    print(f"No task found with ID: {task_id_to_complete}")
            except ValueError:
                print("Please enter a valid number!")
                
        elif command == "delete":
            try:
                task_id_to_delete = int(input("Enter task ID to delete: "))
                # Using list comprehension to keep only tasks with different ID
                original_length = len(tasks)
                tasks = [task for task in tasks if task["id"] != task_id_to_delete]
                
                if len(tasks) < original_length:
                    print(f"Task {task_id_to_delete} deleted!")
                else:
                    print(f"No task found with ID: {task_id_to_delete}")
            except ValueError:
                print("Please enter a valid number!")
                
        else:
            print("Unknown command! Available commands: add, view, complete, delete, exit")

# Uncomment the line below to run the todo list manager:
# todo_list_manager()

# ============================================
# PRACTICE EXERCISES
# ============================================
print("\n" + "=" * 50)
print("PRACTICE EXERCISES")
print("=" * 50)
print("Try these exercises to test your understanding:\n")

print("1. Create a list of 5 numbers and calculate their sum and average.")
print("2. Write a function that takes a string and returns it reversed.")
print("3. Create a dictionary to store information about 3 different movies.")
print("4. Write a program that prints all even numbers from 1 to 20.")
print("5. Create a temperature converter function (Celsius to Fahrenheit).")
print("6. Modify the todo list to save tasks to a file and load them on startup.")
print("7. Add difficulty levels to the number guessing game.")
print("8. Create a simple shopping cart using dictionaries and lists.")

print("\n" + "=" * 50)
print("END OF PRACTICE FILE")
print("=" * 50)