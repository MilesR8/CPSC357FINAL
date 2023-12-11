//
//  ContentView.swift
//  FinalProject
//
//  Created by Miles on 11/30/23.
//

import SwiftUI
import Foundation

class WordDataLoader{
    static func loadWordList() -> [String] {
        guard let url = Bundle.main.url(forResource: "words_dictionary", withExtension: "json")
        else{
            print("JSON file not found")
            return []
        }
        
        do{
            let data = try Data(contentsOf: url)
            let items = try JSONDecoder().decode([String].self, from: data)
            return items
        }
        catch{
            print("Error decoding JSON: \(error)")
            return []
        }
    }
    
    static func GetRandomWord() -> String{
        let items = loadWordList()
        return items.randomElement() ?? "failure"
    }
}

struct ContentView: View {
    
    @State var selection = 0
    @State private var isGameStarted = false
    @State private var isReadingRules = false
    
    var body: some View {
        NavigationView{
            VStack {
                Text("Hangman")
                    .font(.largeTitle)
                Text("By Miles Rovenger")
                    .padding(.bottom)
                
                NavigationLink(
                    destination: RulesView(),
                    isActive: $isReadingRules,
                    label: {
                        Button("Rules") {
                            isReadingRules = true
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                )
                
                NavigationLink(
                    destination: Gameplay(),
                    isActive: $isGameStarted,
                    label: {
                        Button("Play Game") {
                            isGameStarted = true
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                )
            }
        }
    }
}

struct Gameplay : View{
    @State private var secretWord = ""
    @State private var guessedLetters = Set<Character>()
    @State private var currentGuess = ""
    @State private var displayWord = ""
    @State private var incorrectGuesses = 0
    @State private var incorrectGuessLimit = 0
    @State private var totalGuesses = 0
    @State private var gameEnded = false
    @State private var playerWon = false
    
    var body: some View {
        VStack {
            if gameEnded {
                if playerWon {
                    WinView(FinalWord: displayWord)
                } else {
                    LoseView(FinalWord: displayWord, ActualWord: secretWord)
                }
            } else {
                gameView
            }
        }
    }
    
    //variable to autofocus the text field so we dont have to click on it every time (that's annoying)
    @FocusState private var isTextFieldFocused: Bool
    
    var gameView: some View {
        VStack {
            Text("Hangman Game")
                .font(.largeTitle)
            
            Text(displayedWord())
                .font(.title)
                .padding()
            
            TextField("Enter a letter - only the first letter will be used", text: $currentGuess)
            //focuses this text field
                .focused($isTextFieldFocused)
            //disable annoying autocorrect
                .disableAutocorrection(true)
            //set this field to be focused on appear
                .onAppear {
                    isTextFieldFocused = true
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onSubmit {
                    playTurn()
                    //when we submit we lose focus so we must reenable focus here
                    isTextFieldFocused = true
                }
            
            //text to show you how the game is going so far
            Text("Guessed Letters: \(String(guessedLetters))")
                .padding()
                .font(.title)
            Text("Total Guesses: \(totalGuesses)\nIncorrect Guesses: \(incorrectGuesses)/\(incorrectGuessLimit)")
                .multilineTextAlignment(.center)
                .padding()
                .font(.title)
        }.onAppear{
            //get random word
            secretWord = WordDataLoader.GetRandomWord()
            //set guess limit
            incorrectGuessLimit = secretWord.count/2
            //setup display word
            displayWord = String(repeating: "_", count: secretWord.count)
            
            
            //DEBUG STRING TO SEE SECRET WORD
            print("\(secretWord)")
        }
    }
    
    private func playTurn() {
        //get the first letter from the guess and lowercase it. if its empty dont do anything
        guard let guess = currentGuess.lowercased().first, !guessedLetters.contains(guess) else {
            currentGuess = ""
            return
        }
        
        //add the guess to the guessed letters
        guessedLetters.insert(guess)
        totalGuesses += 1
        
        //if the letter is in the word, update the display with the correct letter
        if secretWord.contains(guess) {
            updateDisplayedWord(with: guess)
            //check if the player has guessed the word
            if displayWord == secretWord {
                playerWon = true
                gameEnded = true
            }
        } else {
            //if its not in the word, add one to incorrect guesses
            incorrectGuesses += 1
            //check if the player has lost
            if incorrectGuesses == incorrectGuessLimit {
                gameEnded = true
            }
        }
        //reset the current guess string for input each round
        currentGuess = ""
    }
    
    private func updateDisplayedWord(with guess: Character) {
        //updates the display word with the new character - ensures that all cases of the letter in the word are accounted for
        for (index, letter) in secretWord.enumerated() {
            if letter == guess {
                let startIndex = displayWord.index(displayWord.startIndex, offsetBy: index)
                displayWord.replaceSubrange(startIndex...startIndex, with: String(guess))
            }
        }
    }
    
    private func displayedWord() -> String {
        //getter function for the displayed word
        var display = ""
        for letter in displayWord {
            display += "\(letter) "
        }
        return display
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct WinView: View {
    @State private var scale: CGFloat = 1.0
    var FinalWord: String
    var body: some View {
        Text("You Win!")
            .font(.title)
            .scaleEffect(scale)
            .padding()
            .animation(
                Animation.easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true)
            )
            .onAppear {
                self.scale = 2.0 // Initial scale factor
            }
            .foregroundColor(.green)
        Text("Final word: \(FinalWord)")
    }
}

struct LoseView: View {
    var FinalWord: String
    var ActualWord: String
    var body: some View {
        Text("You Lose")
            .font(.largeTitle)
            .foregroundColor(.red)
            .padding()
        Text("Final word: \(FinalWord)")
        Text("The secret word was: \(ActualWord)")
        Image("youloseface")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 100, height: 100)
    }
}

struct RulesView: View {
    var body: some View {
        VStack{
            Image("gamess")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 300, height: 300)
            Text("Welcome to Hangman. The rules of the games are simple. Each game a seceret word will be chosen. Your goal is to guess the word by typing in letters you beieve are in the word. If you guess too many wrong, you will lose the game. If you get all the letters in the word, you win. Have fun!").font(.title).padding(.horizontal, 20)
        }
    }
}
