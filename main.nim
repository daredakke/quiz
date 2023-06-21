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


proc importQuizFromText(filePath: string): seq[Question] =
  var
    quizFile: File
    quiz: seq[Question]
    currentQuestion, lineNumber: int = -1

  quizFile = open(filePath, fmRead)

  for line in quizFile.lines():
    var currentLine: string = line.strip(true, true)
    inc lineNumber

    if $currentLine == "":
      continue

    elif currentLine[0] == '-':
      currentLine.removePrefix('-')
      quiz[currentQuestion].answers.add(Answer(text: currentLine, isCorrect: false))

    elif currentLine[0] == '*':
      currentLine.removePrefix('*')
      quiz[currentQuestion].answers.add(Answer(text: currentLine, isCorrect: true))
      quiz[currentQuestion].correctAnswerCount += 1

    else:
      # Ensure previous question was valid before moving to the next one
      if currentQuestion > -1 and quiz[currentQuestion].isInvalid():
        quizFile.close()
        raise newException(InvalidQuestion, &"Invalid question on line {lineNumber}")

      inc currentQuestion

      quiz.add(Question(text: currentLine))

  quizFile.close()

  if currentQuestion > -1 and quiz[currentQuestion].isInvalid():
    raise newException(InvalidQuestion, &"Invalid question on line {lineNumber}")

  return quiz


proc getTemplateHTMLAsString(path: string): string =
  var templateFile: File

  templateFile = open(path, fmRead)

  for line in templateFile.lines():
    result = result & line & "\n"


# Piece templates together into a single HTML document and embed quiz data into it
proc buildQuizHTML(quizTitle: string, filePath: string): string =
  var
    quiz: seq[Question] = importQuizFromText(filePath)
    pageTemplate: string
    questionTemplate: string
    answerRadioTemplate: string
    answerCheckboxTemplate: string
    idCounter: int

  pageTemplate = getTemplateHTMLAsString("templates/page.html")
  questionTemplate = getTemplateHTMLAsString("templates/question.html")
  answerRadioTemplate = getTemplateHTMLAsString("templates/answerRadio.html")
  answerCheckboxTemplate = getTemplateHTMLAsString("templates/answerCheckbox.html")

  for question in quiz:
    var
      answers: string
      templateToUse: string = answerRadioTemplate

    for i, answer in question.answers:
      if question.correctAnswerCount > 1:
        templateToUse = answerCheckboxTemplate

      answers = answers & templateToUse
        .replace("{{answerId}}", $i)
        .replace("{{answerText}}", answer.text)

    result = result & questionTemplate
      .replace("{{questionText}}", question.text)
      .replace("{{answers}}", answers)
      .replace("{{questionId}}", $idCounter)

    inc idCounter

  result = pageTemplate
    .replace("{{questions}}", result)
    .replace("{{quizTitle}}", quizTitle)


proc copyCSSToBuildDir() =
  if not dirExists("css"):
    return

  copyFileToDir("css/style.css", "build")


proc exportQuizAsHTML(quizTitle: string, filePath: string, deleteBuildDir: string) =
  var outFile: File

  if deleteBuildDir.toLowerAscii() != "n":
    removeDir("build")

  createDir("build")

  let
    title: string = quizTitle
    filename: string = title.replace(" ", "-").toLowerAscii()
    output: string = buildQuizHTML(title, filePath)

  outFile = open(&"build/{filename}.html", fmWrite)
  outFile.write(output)
  outFile.close()

  copyCSSToBuildDir()


proc getSettingsFromUser() =
  var deleteBuildDir: string = "n"

  echo "\nPlease enter the name of the quiz - the imported quiz will use this as its filename"
  let quizTitle: string = readLine(stdin)

  echo "\nPlease enter the file path of the quiz to be imported"
  let filePath: string = readLine(stdin)

  if not fileExists(filePath):
    raise newException(FileDoesNotExist, &"Cannot find file at {filePath}")

  if dirExists("build"):
    echo "\nDelete the existing build directory? - y/n"
    deleteBuildDir = readLine(stdin)

  exportQuizAsHTML(quizTitle, filePath, deleteBuildDir)


proc main() =
  getSettingsFromUser()


main()