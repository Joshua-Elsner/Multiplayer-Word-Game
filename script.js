let secretWord = "SHARK"; //Starts as shark initially
let currentRow = 0; 
let currentTile = 0;
let currentGuess = "";
let isGameOver = false;

const rows = document.querySelectorAll('.board-row');
const keys = document.querySelectorAll('.key'); 

keys.forEach(key => {
    key.addEventListener('click', () => {
        if (isGameOver) return;

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

//Physical keyboard strokes
document.addEventListener('keydown', (e) => {
    if (isGameOver) return;

    if (e.key === 'Enter') {
        checkGuess();
        return;
    }

    if (e.key === 'Backspace') {
        deleteLetter();
        return; 
    }

    //Regex for a single char
    const isLetter = /^[a-zA-Z]$/.test(e.key);
    
    if (isLetter) {
        addLetter(e.key.toUpperCase());
    }
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
        isGameOver = true;
        return;
    }
    currentRow++;
    currentTile = 0;
    currentGuess = "";

    //Lose check
    if (currentRow === 6) {
        document.getElementById('lose-modal').classList.remove('hidden');
        isGameOver = true;
        
        //TODO: Add 1 to Fish Eaten on leaderboard
        console.log("Shark gets a point!");
    }

}

const tryAgainBtn = document.getElementById('try-again-btn');

tryAgainBtn.addEventListener('click', () => {
    document.getElementById('lose-modal').classList.add('hidden');

    currentRow = 0;
    currentTile = 0;
    currentGuess = "";
    isGameOver = false;

    //Clear all letters and colors from the bubbles
    for (let r = 0; r < 6; r++) {
        for (let c = 0; c < 5; c++) {
            const tile = rows[r].children[c];
            tile.textContent = "";
            tile.classList.remove('correct', 'present', 'absent');
        }
    }
});

const submitNewWordBtn = document.getElementById('submit-new-word');
const newWordInput = document.getElementById('new-word-input');

submitNewWordBtn.addEventListener('click', () => {
    const newWord = newWordInput.value.toUpperCase().trim();

    if (newWord.length !== 5) {
        alert("Must be 5 letters");
        return; 
    }

    console.log("TODO: Update databas with new word here.");
    
    secretWord = newWord; 

    //Hide the Modal and clear the input box
    document.getElementById('win-modal').classList.add('hidden');
    newWordInput.value = ""; 

    currentRow = 0;
    currentTile = 0;
    currentGuess = "";
    isGameOver = false;

    for (let r = 0; r < 6; r++) {
        for (let c = 0; c < 5; c++) {
            const tile = rows[r].children[c];
            tile.textContent = ""; 
            tile.classList.remove('correct', 'present', 'absent'); 
        }
    }

    // window.location.href = "leaderboard.html"; 
    console.log("TODO: Updating leaderboard will happen here.");
});