import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tetris_board/utils/piece.dart';
import 'package:tetris_board/utils/pixel.dart';
import 'package:tetris_board/utils/values.dart';


/* *
 * GameBoard
 * This is a 2x2 grid with null representing an empty space.
 * A non empty space will have the color to represent the landed pieces
 * */

//Create game board
List<List<Tetromino?>> gameBoard = List.generate(
  colLength,
  (i) => List.generate(
    rowLength,
    (j) => null,
  ),
);

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {

  //Current tetris piece
  Piece currentPiece = Piece(type: Tetromino.L);
  int currentScore = 0;
  bool gameOver = false;

  @override
  void initState() {
    super.initState();

    //Start Game
    startGame();
  }

  void startGame() {
    currentPiece.initializePiece();

    //Refresh frame rate
    Duration frameRate = const Duration(milliseconds: 600);
    gameLoop(frameRate);
  }

  //Game loop
  void gameLoop(Duration frameRate) {
    Timer.periodic(frameRate, (timer) {
      setState(() {
        clearLine();
        checkLanding();

        if (gameOver == true) {
          timer.cancel();
          showGameOverDialog();
        }

        //move current piece down
        currentPiece.movePiece(Direction.down);
      });
    });
  }

  //Game over dialog message
  void showGameOverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Game Over'),
        content: Text('Your score is: $currentScore'),
        actions: [
          TextButton(
            onPressed: () {
              resetGame();
              Navigator.pop(context);
            },
            child: Text('Play Again'),
          ),
        ],
      ),
    );
  }

  //Reset Game
  void resetGame() {
    //Clear the game board
    gameBoard = List.generate(
      colLength,
      (i) => List.generate(
        rowLength,
        (j) => null,
      ),
    );

    gameOver = false;
    currentScore = 0;
    createNewPiece();
    startGame();
  }

  //Check for collision detection
  //Return -> true if collision
  //Return -> false if no collision
  bool checkCollision(Direction direction) {
    //Loop through each position of the current piece
    for (int i=0; i<currentPiece.position.length; i++) {
      //Calculate the row and column of the current position
      int row = (currentPiece.position[i] / rowLength).floor();
      int col = currentPiece.position[i] % rowLength;

      //Adjust the row and col based on the direction
      if (direction == Direction.left) {
        col -= 1;
      } else if (direction == Direction.right) {
        col += 1;
      } else if (direction == Direction.down) {
        row += 1;
      }

      //Check if the piece is out of bounds (Either too low or too far to the left or right)
      if (row >= colLength || col < 0 || col >= rowLength) {
        return true;
      }


      // Check if the position is already occupied
      if (row >= 0 && gameBoard[row][col] != null) {
        return true;  // Collision detected
      }
    }

    return false;
  }

  void checkLanding() {
    //If going down is occupied
    if (checkCollision(Direction.down)) {
      //Mark the position as occupied on the game board
      for (int i=0; i<currentPiece.position.length; i++) {
        int row = (currentPiece.position[i] / rowLength).floor();
        int col = currentPiece.position[i] % rowLength;

        if (row >= 0 && col >= 0) {
          gameBoard[row][col] = currentPiece.type;
        }
      }

      //Once landed, create the next piece
      createNewPiece();
    }
  }

  void createNewPiece() {
    //Create a random object to generate random tetromino type
    Random random = Random();

    //Create a new piece with random type
    Tetromino type = Tetromino.values[random.nextInt(Tetromino.values.length)];
    currentPiece = Piece(type: type);
    currentPiece.initializePiece();

    /*
    Since our game over condition is if there is a piece at the top level,
    you want to check if the game is over when you create a new piece instead of
    checking every frame, because new pieces are allowed to go through the top
    level but if there is already a piece in the top level when the new piece
    is created, then game is over.
    */

    if (isGameOver()) {
      gameOver = true;
    }
  }

  //Move piece to left
  void moveLeft() {
    if (!checkCollision(Direction.left)) {
      setState(() {
        currentPiece.movePiece(Direction.left);
      });
    }
  }

  //Rotate piece to clockwise
  void rotatePiece() {
    setState(() {
      currentPiece.rotatePiece();
    });
  }

  //Move piece to right
  void moveRight() {
    if (!checkCollision(Direction.right)) {
      setState(() {
        currentPiece.movePiece(Direction.right);
      });
    }
  }

  //Clear line on completion
  void clearLine() {
    //Step 1: Loop through each row of the game board from bottom to top
    for (int row=colLength - 1; row>=0; row--) {
      //Step 2: Initialize a variable to track if the row is full
      bool rowIsFull = true;

      //Step 3: Check if the row is full (All columns in the row are filled with pieces)
      for (int col=0; col<rowLength; col++) {
        if (gameBoard[row][col] == null) {
          rowIsFull = false;
          break;
        }
      }

      //Step 4: If the row is full, clear the row and shift rows down
      if (rowIsFull) {
        //Step 5: Move all rows above the cleared row down by one position
        for (int r=row; r>0; r--) {
          //Copy the above row to the current row
          gameBoard[r] = List.from(gameBoard[r - 1]);
        }

        //Step 6: Set the top row to empty
        gameBoard[0] = List.generate(row, (index) => null);

        //Step 7: Increase the score!
        currentScore ++;
      }
    }
  }

  //Game Over
  bool isGameOver() {
    //Check if any columns in the top row are filled
    for (int col=0; col<rowLength; col++) {
      if (gameBoard[0][col] != null) {
        return true;
      }
    }

    //If the top row is empty, the game is not over
    return false;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          //Game Board Grid
          Expanded(
            flex: 1,
            child: GridView.builder(
              itemCount: rowLength * colLength,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                childAspectRatio: 1.1,
                crossAxisCount: rowLength,
              ),
              itemBuilder: (context, index) {
                //Get row and col of each index
                int row = (index / rowLength).floor();
                int col = index % rowLength;

                //Current piece
                if (currentPiece.position.contains(index)) {
                  return Pixel(
                    color: currentPiece.color,
                  );
                }
                //Landed pieces
                else if (gameBoard[row][col] != null) {
                  final Tetromino? tetrominoType = gameBoard[row][col];
                  return Pixel(
                    color: tetrominoColors[tetrominoType],
                  );
                }
                //Blank pixel
                else {
                  return Pixel(
                    color: Colors.grey[900],
                  );
                }
              },
            ),
          ),
          //Show Score
          Text(
            'Score: $currentScore',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          //Game controls
          Padding(
            padding: const EdgeInsets.only(bottom: 50.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: moveLeft,
                  icon: Icon(Icons.arrow_back_ios_new),
                  color: Colors.white,
                ),
                IconButton(
                  onPressed: rotatePiece,
                  icon: Icon(Icons.rotate_right),
                  color: Colors.white,
                ),
                IconButton(
                  onPressed: moveRight,
                  icon: Icon(Icons.arrow_forward_ios),
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
