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
  var deleteBuildDir: string = "n"

  echo "\nPlease enter the name of the quiz - the imported quiz will use this as its filename"
  let quizTitle: string = readLine(stdin)

  echo "\nPlease enter the file path of the quiz to be imported"
  let filePath: string = readLine(stdin)

  if not fileExists(filePath):
    raise newException(FileDoesNotExist, &"Cannot find {filePath}")

  if dirExists("build"):
    echo "\nDelete the existing build directory? - y/n"
    deleteBuildDir = readLine(stdin)

  result = (
    quizTitle: quizTitle, 
    filePath: filePath, 
    deleteBuildDir: deleteBuildDir
  )


# Parse a text file of multiple-choice questions into a data structure
proc importQuizFromText(filePath: string): seq[Question] =
  var
    quizFile: File
    currentQuestion, lineNumber: int = -1

  quizFile = open(filePath, fmRead)

  for line in quizFile.lines():
    var currentLine: string = line.strip(true, true)
    inc lineNumber

    if $currentLine == "":
      continue

    elif currentLine[0] == '-':
      currentLine.removePrefix('-')
      result[currentQuestion].answers.add(Answer(text: currentLine, isCorrect: false))

    elif currentLine[0] == '*':
      currentLine.removePrefix('*')
      result[currentQuestion].answers.add(Answer(text: currentLine, isCorrect: true))
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
  var templateFile: File

  templateFile = open(path, fmRead)

  for line in templateFile.lines():
    result &= line & "\n"


proc parsedQuizDataToJSON(quiz: seq[Question]) =
  echo "parsedQuizDataToJSON()"


# Piece HTML templates together into a single HTML document and embed quiz 
# data into it
proc buildQuizHTML(quiz: seq[Question], quizTitle: string, filePath: string): string =
  var
    stylesheets: string
    pageTemplate: string
    questionTemplate: string
    answerRadioTemplate: string
    answerCheckboxTemplate: string
    idCounter: int

  pageTemplate = getHTMLTemplateAsString("templates/page.html")
  questionTemplate = getHTMLTemplateAsString("templates/question.html")
  answerRadioTemplate = getHTMLTemplateAsString("templates/answerRadio.html")
  answerCheckboxTemplate = getHTMLTemplateAsString("templates/answerCheckbox.html")

  for question in quiz:
    var
      answers: string
      templateToUse: string = answerRadioTemplate

    for i, answer in question.answers:
      if question.correctAnswerCount > 1:
        templateToUse = answerCheckboxTemplate

      answers &= templateToUse
        .replace("{{answerId}}", $i)
        .replace("{{answerText}}", answer.text)

    result &= questionTemplate
      .replace("{{questionText}}", question.text)
      .replace("{{answers}}", answers)
      .replace("{{questionId}}", $idCounter)

    inc idCounter

  if dirExists("css"):
    for f in walkDir("css"):
      let ext: string = f.path.splitFile().ext

      if ext == ".css":
        stylesheets &= &"<link rel=\"stylesheet\" href=\"{f.path}\">\n"

  result = pageTemplate
    .replace("{{stylesheets}}", stylesheets)
    .replace("{{questions}}", result)
    .replace("{{quizTitle}}", quizTitle)


# If CSS files are provided, merge them into a single minified style.css in 
# the build directory
proc copyCSSToBuildDir() =
  if not dirExists("css"):
    return

  var
    output: string
    stylesheet, outFile: File

  for f in walkDir("css"):
    # Ignore any file that isn't a stylesheet
    if f.path.splitFile().ext != ".css":
      continue

    stylesheet = open(f.path, fmRead)

    for line in stylesheet.lines():
      output &= line
        .strip(true, true)
        .replace(": ", ":")
        .replace(" {", "{")
  
  outFile = open("build/css/style.css", fmWrite)
  outFile.write(output)
  outFile.close()


proc createBuildDirStructure(deleteBuildDir: string) =
  if deleteBuildDir.toLowerAscii() != "n":
    removeDir("build")

  createDir("build")

  if dirExists("css"):
    createDir("build/css")


# Create build directory and write the quiz HTML to a HTML document that 
# reflects the title given to it
proc exportQuizAsHTML(quizHTML: string, quizTitle: string, filePath: string) =
  var outFile: File

  let
    title: string = quizTitle
    filename: string = title.replace(" ", "-").toLowerAscii()

  outFile = open(&"build/{filename}.html", fmWrite)
  outFile.write(quizHTML)
  outFile.close()


proc main() =
  let
    settings: tuple = getSettingsFromUser()
    quiz: seq[Question] = importQuizFromText(settings.filePath)
    quizHTML: string = buildQuizHTML(quiz, settings.quizTitle, settings.filePath)

  createBuildDirStructure(settings.deleteBuildDir)
  exportQuizAsHTML(quizHTML, settings.quizTitle, settings.filePath)
  copyCSSToBuildDir()

  echo "\nQuiz exported to ./build directory\n"


main()