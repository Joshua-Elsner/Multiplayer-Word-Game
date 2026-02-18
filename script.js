const secretWord = "SHARK"; //Starts as shark initially
let currentRow = 0; 
let currentTile = 0;
let currentGuess = "";

const rows = document.querySelectorAll('.board-row');
const keys = document.querySelectorAll('.key'); 

keys.forEach(key => {
    key.addEventListener('click', () => {
        const letter = key.textContent.trim();

        if (letter === "ENTER") {
            //TODO: checking logic
            checkGuess();
        } else if (letter === "BACK") {
            deleteLetter();
        } else {
            addLetter(letter);
        }
    });
});

function addLetter(letter) {
    if (currentTile < 5) {
        const tile = rows[currentRow].children[currentTile]; 
        tile.textContent = letter; 
        currentGuess += letter; 
        currentTile++;
    }
}

function deleteLetter() {
    if (currentTile > 0) {
        currentTile--; 
        const tile = rows[currentRow].children[currentTile];
        tile.textContent = ""; 
        currentGuess = currentGuess.slice(0, -1);
    }
}

function checkGuess() {
    //Make sure the user actually typed a full 5-letter word 
    if (currentGuess.length !== 5) {
        return;
    }

    //Compare their guess against the secretWord SHARK letter by letter
    for (let i = 0; i < secretWord.length; i++) {
        if (currentGuess[i] === secretWord[i]) {
           rows[currentRow].children[i].classList.add('correct');
        }

        else if (secretWord.includes(currentGuess[i])) {
           rows[currentRow].children[i].classList.add('present');
        }

        else {
           rows[currentRow].children[i].classList.add('absent');
        }
    }
    //Win chekc
    if (currentGuess === secretWord) {
        document.getElementById('win-modal').classList.remove('hidden');
        return;
    }
    currentRow++;
    currentTile = 0;
    currentGuess = "";

}