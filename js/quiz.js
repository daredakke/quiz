function getQuizState() {
  const inputs = document.querySelectorAll("input[type='radio'], input[type='checkbox']");
  const quizState = {};

  for (const i of inputs) {
    const questionId = i.name.length > 1 ? i.name.split("-")[0] : i.name;

    if (questionId in quizState) {
      quizState[questionId].push(i.checked);
    } else {
      quizState[questionId] = [i.checked];
    }
  }
  return quizState;
}

function allQuestionsAnswered(quizState) {
  for (question in quizState) {
    let answersGiven = 0;

    for (answer of quizState[question]) {
      answersGiven += answer ? 1 : 0;
    }

    if (answersGiven === 0) {
      return false;
    }
  }

  return true;
}

function getQuizResults(quizState) {
  const quizResults = {};

  for (question in quizState) {
    quizResults[question] = true;

    for (answer in quizState[question]) {
      if (quizState[question][answer] !== quiz[question].answers[answer].isCorrect) {
        quizResults[question] = false;
      }
    }
  }

  return quizResults;
}

function outputQuizResults(quizResults) {
  let total = 0;
  let output = "";

  for (result in quizResults) {
    total += quizResults[result] ? 1 : 0;
    output += `${result + 1} - ${quizResults[result] ? "Correct" : "Wrong"}\n`
  }

  output += `\nYou scored ${total}/${quiz.length}`;

  alert(output);
}

function main() {
  const submitButton = document.querySelector("#submitQuiz");

  submitButton.addEventListener("click", () => {
    const quizState = getQuizState(quizForm);

    if (!allQuestionsAnswered(quizState)) {
      alert("Not all questions have been answered");
      return;
    }

    const quizResults = getQuizResults(quizState);
    outputQuizResults(quizResults);
  });
}

main();