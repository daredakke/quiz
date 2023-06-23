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

Whitespace and blank lines are ignored.

## How to Use

Ensure you have [Nim](https://nim-lang.org/) installed.

Navigate to the `quiz` directory in your terminal and type `nim c -r main.nim`. You will be asked a series of questions.

- "Please enter the name of the quiz" - e.g., `Cities of the World`
  - The imported quiz will use this title as its filename - e.g., `cities-of-the-world.html`
- "Please enter the file path of the quiz to be imported" - e.g., `quizzes/testquiz.txt`
  - The path of the quiz file relative to the `quiz` directory
- "Delete the existing build directory? - y/n"
  - Choose whether to remove any existing `build` directory

### CSS

If you have a `css` directory present in the `quiz` directory, any CSS files inside will be merged and minified in the order that they appear in the directory before being written as a single stylesheet to the `build` directory and linked appropriately in the exported HTML file.