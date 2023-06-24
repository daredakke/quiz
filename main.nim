import std/os
import std/strutils
import std/strformat

type InvalidQuestion = object of CatchableError
type FileDoesNotExist = object of CatchableError


type Answer = object
  text: string
  isCorrect: bool


type Question = object
  text: string
  answers: seq[Answer]
  correctAnswerCount: int


proc isInvalid(self: Question): bool =
  if self.correctAnswerCount > 0 and self.correctAnswerCount < self.answers.len:
    return false

  return true


# Get the quiz title and file path of the quiz text document from the 
# user while also providing the option to remove any existing build
# directory
proc getSettingsFromUser(): tuple =
  echo "\nPlease enter the name of the quiz"
  let quizTitle: string = readLine(stdin)

  echo "\nPlease enter the file path of the quiz to be imported"
  let filePath: string = readLine(stdin)

  if not fileExists(filePath):
    raise newException(FileDoesNotExist, &"Cannot find {filePath}")

  result = (
    quizTitle: quizTitle,
    filename: quizTitle.replace(" ", "-").toLowerAscii(),
    filePath: filePath
  )


# Parse a text file of multiple-choice questions into a data structure
proc importQuizDataFromText(filePath: string): seq[Question] =
  let quizFile: File = open(filePath, fmRead)
  var currentQuestion, lineNumber: int = -1

  for line in quizFile.lines():
    var currentLine: string = line.strip(true, true)
    inc lineNumber

    if $currentLine == "":
      continue

    elif currentLine[0] == '-':
      currentLine.removePrefix('-')
      result[currentQuestion].answers.add(Answer(text: currentLine.strip(true, true), isCorrect: false))

    elif currentLine[0] == '*':
      currentLine.removePrefix('*')
      result[currentQuestion].answers.add(Answer(text: currentLine.strip(true, true), isCorrect: true))
      result[currentQuestion].correctAnswerCount += 1

    else:
      # Ensure previous question was valid before moving to the next one
      if currentQuestion > -1 and result[currentQuestion].isInvalid():
        quizFile.close()
        raise newException(InvalidQuestion, &"Invalid question on line {lineNumber}")

      inc currentQuestion

      result.add(Question(text: currentLine))

  quizFile.close()

  if currentQuestion > -1 and result[currentQuestion].isInvalid():
    raise newException(InvalidQuestion, &"Invalid question on line {lineNumber}")


proc getHTMLTemplateAsString(path: string): string =
  let templateFile: File = open(path, fmRead)

  for line in templateFile.lines():
    result &= line & "\n"


# Piece HTML templates together into a single HTML document and embed quiz 
# data into it
proc buildQuizWebpageAsString(quiz: seq[Question], quizTitle: string): string =
  let
    pageTemplate: string = getHTMLTemplateAsString("assets/templates/page.html")
    questionTemplate: string = getHTMLTemplateAsString("assets/templates/question.html")
    answerTemplate: string = getHTMLTemplateAsString("assets/templates/answer.html")

  var idCounter: int

  for question in quiz:
    var
      answers: string
      answerType: string = "radio"
      questionId: string = $idCounter

    for i, answer in question.answers:
      if question.correctAnswerCount > 1:
        answerType = "checkbox"
        questionId = &"{$idCounter}-{$i}"

      answers &= answerTemplate
        .replace("{{type}}", answerType)
        .replace("{{answerId}}", $i)
        .replace("{{answerText}}", answer.text)
        .replace("{{questionId}}", questionId)

    result &= questionTemplate
      .replace("{{questionText}}", question.text)
      .replace("{{answers}}", answers)
      .replace("{{questionId}}", $(idCounter + 1))

    inc idCounter

  result = pageTemplate
    .replace("{{questions}}", result)
    .replace("{{quizTitle}}", quizTitle)


proc getQuizDataAsJavaScriptString(quiz: seq[Question]): string =
  var data: string

  for question in quiz:
    data &= "{question:\"" & question.text & "\",answers:["

    for answer in question.answers:
      data &= "{answer:\"" & answer.text & "\",isCorrect:" & $answer.isCorrect & "},"

    data &= "]},"

  result = &"\nconst quiz = [{data}];\n\n"


proc getQuizJavaScriptAsString(): string =
  let quizScript: File = open("assets/js/quiz.js", fmRead)

  for line in quizScript.lines():
    result &= &"{line}\n"

  quizScript.close()


# If CSS files are provided, merge them into a single minified style.css in 
# the build directory
proc getStylesheetString(): string =
  if not dirExists("assets/css"):
    return

  for f in walkDir("assets/css"):
    # Ignore any file that isn't a stylesheet
    if f.path.splitFile().ext != ".css":
      continue

    let stylesheet: File = open(f.path, fmRead)

    for line in stylesheet.lines():
      result &= &"{line}\n"

    stylesheet.close()


# Embed CSS and JS into the webpage
proc embedFilesInWebpage(webpage: string, script: string, stylesheet: string): string =
  result = webPage
    .replace("{{script}}", script)
    .replace("{{stylesheet}}", &"\n{stylesheet}")


proc createQuizzesFolder() =
  if not dirExists("exports"):
    createDir("exports")
  

# Create build directory and write the quiz HTML to a HTML document that 
# reflects the title given to it
proc exportQuizWebpageToHTML(filename: string, webpage: string) =
  let outFile: File = open(&"exports/{filename}.html", fmWrite)

  outFile.write(webpage)
  outFile.close()


proc main() =
  let
    settings: tuple = getSettingsFromUser()
    quiz: seq[Question] = importQuizDataFromText(settings.filePath)
    quizDataString: string = getQuizDataAsJavaScriptString(quiz)
    quizScriptString: string = getQuizJavaScriptAsString()
    combinedQuizScript: string = quizDataString & quizScriptString
    stylesheetString: string = getStylesheetString()
    quizWebpageBase: string = buildQuizWebpageAsString(quiz, settings.quizTitle)
    quizWebpageComplete: string = embedFilesInWebpage(quizWebpageBase, combinedQuizScript, stylesheetString)

  createQuizzesFolder()
  exportQuizWebpageToHTML(settings.filename, quizWebpageComplete)

  echo &"\nQuiz exported to ./exports/{settings.filename}.html\n"


main()