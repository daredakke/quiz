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
    quizResults[question] = { questionText: quiz[question].question, result: true };

    for (answer in quizState[question]) {
      if (quizState[question][answer] !== quiz[question].answers[answer].isCorrect) {
        quizResults[question].result = false;
      }
    }
  }

  return quizResults;
}

function createTextElement(tag, text, className = null) {
  const element = document.createElement(tag);
  element.textContent = text;

  if (className) {
    element.classList.add(className);
  }

  return element;
}

function modal() {
  const modalBox = document.querySelector("#modal");
  const closeModal = document.querySelector("#closeModal");

  const hideModal = () => {
    modalBox.classList.add("hide");
    closeModal.removeEventListener("click", hideModal);
  }

  modalBox.classList.remove("hide");
  
  closeModal.addEventListener("click", hideModal);
}

function outputQuizResults(quizResults) {
  const modalBody = document.querySelector("#modalBody");
  let total = 0;

  modalBody.textContent = "";

  modalBody.append(createTextElement("h2", "Results"));

  for (index in quizResults) {
    total += quizResults[index].result ? 1 : 0;

    modalBody.append(
      createTextElement(
        "p",
        `${Number(index) + 1} - ${quizResults[index].questionText}`,
        quizResults[index].result ? "correct" : "incorrect"
      )
    );
  }

  const quizResultText = createTextElement("b", `You scored ${total}/${quiz.length}`);
  const quizResultPara = document.createElement("p")

  quizResultPara.classList.add("modal-result")
  quizResultPara.append(quizResultText)
  modalBody.append(quizResultPara);

  modal();
}

function outputQuizError() {
  const modalBody = document.querySelector("#modalBody");

  modalBody.textContent = "";

  modalBody.append(createTextElement("h2", "Error"));
  modalBody.append(createTextElement("p", "Not all questions have been answered."));

  modal();
}

function main() {
  const submitButton = document.querySelector("#submitQuiz");

  submitButton.addEventListener("click", () => {
    const quizState = getQuizState(quizForm);

    if (!allQuestionsAnswered(quizState)) {
      outputQuizError();
      return;
    }

    outputQuizResults(getQuizResults(quizState));
  });
}

main();