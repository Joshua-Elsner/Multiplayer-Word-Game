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
            console.log("Submit guess:", currentGuess);
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