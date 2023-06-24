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
  let templateFile: File = open(path, fmRead)

  for line in templateFile.lines():
    result &= line & "\n"


# Piece HTML templates together into a single HTML document and embed quiz 
# data into it
proc buildQuizWebPageAsString(quiz: seq[Question], quizTitle: string, filePath: string): string =
  let
    pageTemplate: string = getHTMLTemplateAsString("templates/page.html")
    questionTemplate: string = getHTMLTemplateAsString("templates/question.html")
    answerTemplate: string = getHTMLTemplateAsString("templates/answer.html")

  var
    stylesheets: string
    idCounter: int

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

  if dirExists("css"):
    for f in walkDir("css"):
      let ext: string = f.path.splitFile().ext

      if ext == ".css":
        stylesheets &= &"<link rel=\"stylesheet\" href=\"{f.path}\">\n"

  result = pageTemplate
    .replace("{{stylesheets}}", stylesheets)
    .replace("{{questions}}", result)
    .replace("{{quizTitle}}", quizTitle)


proc createBuildDirStructure(dirName: string) =
  if dirExists(dirName):
    removeDir(dirName)

  createDir(dirName)
  createDir(&"{dirName}/js")

  if dirExists("css"):
    createDir(&"{dirName}/css")


proc convertQuizDataToJavaScript(quiz: seq[Question]): string =
  var data: string

  for question in quiz:
    data &= "{question:\"" & question.text & "\",answers:["

    for answer in question.answers:
      data &= "{answer:\"" & answer.text & "\",isCorrect:" & $answer.isCorrect & "},"

    data &= "]},"

  result = &"const quiz = [{data}];"


# Create build directory and write the quiz HTML to a HTML document that 
# reflects the title given to it
proc exportQuizWebPageToHTML(dirName: string, quizWebPage: string) =
  let outFile: File = open(&"{dirName}/quiz.html", fmWrite)

  outFile.write(quizWebPage)
  outFile.close()


proc exportJavaScript(dirName: string, quizDataAsJavaScript: string) =
  let quizDataOutFile: File = open(&"{dirName}/js/quizData.js", fmWrite)

  copyFile("js/quiz.js", &"{dirName}/js/quiz.js")

  quizDataOutFile.write(quizDataAsJavaScript)
  quizDataOutFile.close()


# If CSS files are provided, merge them into a single minified style.css in 
# the build directory
proc exportCSS(dirName: string) =
  if not dirExists("css"):
    return

  var output: string

  for f in walkDir("css"):
    # Ignore any file that isn't a stylesheet
    if f.path.splitFile().ext != ".css":
      continue

    let stylesheet: File = open(f.path, fmRead)

    for line in stylesheet.lines():
      output &= line
        .strip(true, true)
        .replace(": ", ":")
        .replace(" {", "{")
  
  let outFile: File = open(&"{dirName}/css/style.css", fmWrite)

  outFile.write(output)
  outFile.close()


proc main() =
  let
    settings: tuple = getSettingsFromUser()
    dirName: string = settings.quizTitle.replace(" ", "-").toLowerAscii()
    quiz: seq[Question] = importQuizDataFromText(settings.filePath)
    quizWebPage: string = buildQuizWebPageAsString(quiz, settings.quizTitle, settings.filePath)
    quizDataAsJavaScript: string = convertQuizDataToJavaScript(quiz)

  createBuildDirStructure(dirName)
  exportQuizWebPageToHTML(dirName, quizWebPage)
  exportJavaScript(dirName, quizDataAsJavaScript)
  exportCSS(dirName)

  echo &"\nQuiz exported to ./{dirName} directory\n"


main()