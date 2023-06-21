# Quiz Builder

A nim script that takes a multiple-choice quiz in a text document and turns it into a HTML form.

A quiz is formatted as follows:

    What is the capital of Germany?
    -Paris
    *Berlin
    -London
    -Amsterdam

- Questions may have any number of answers, but require at least two
- Correct answers are marked with an asterisk
- Questions:
  - may have multiple correct answers
  - must have at least one correct answer
  - must have at least one incorrect answer

Whitespace and blank lines have no impact when importing quizzes, so you may format quizzes as you like.

## How to Use

Navigate to the `quiz` directory and in your terminal type `nim c -r main.nim`. You will be asked a series of questions.

- "Please enter the name of the quiz" - e.g., `Cities of the World`
  - The imported quiz will use this title as its filename - e.g., `cities-of-the-world.html`
- "Please enter the file path of the quiz to be imported"
  - The path of the quiz file relative to the `quiz` directory
- "Delete the existing build directory? - y/n"
  - Choose whether to remove any existing `build` directory

### CSS

If you have a `css` directory present in the `quiz` directory, it and any CSS files inside will be copied to the `build` directory and linked appropriately in the exported HTML file.