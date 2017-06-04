import Data.List
import Data.Maybe
import qualified Data.Map

data Piece = White | Black | Empty deriving (Eq, Show)
type Position = (Int, Int)
type Board = Data.Map.Map Position Piece

allPositions = [(x, y) | x <- [0..7], y <- [0..7]]
emptyBoard = Data.Map.fromList (zip allPositions (repeat Empty))
-- initialBoard = Data.Map.union (Data.Map.fromList [((3, 3), White), ((4, 4), White), ((3, 4), Black), ((4, 3), Black)]) emptyBoard
initialBoard = (Data.Map.fromList [
  ((3, 3), White),
  ((4, 4), White),
  ((3, 4), Black),
  ((4, 3), Black)])

opponentColor :: Piece -> Piece
opponentColor White = Black
opponentColor Black = White
opponentColor _ = Empty


directions = [(0, 1), (1, 1), (1, 0), (1, -1), (0, -1), (-1, -1), (-1, 0), (-1, 1)]


addPosition :: Position -> Position -> Position
addPosition (x1, y1) (x2, y2) = (x1 + x2, y1 + y2)


isRow :: Piece -> Board -> Position -> Position -> Bool
isRow color board position direction = isRow' True color board position direction
  where
    isRow' firstLevel color board position direction =
      if nextColor == opponentColor color then
        isRow' False color board nextPosition direction
      else
        nextColor == color && not firstLevel
      where
        nextPosition = addPosition position direction
        nextColor = fromMaybe Empty (Data.Map.lookup nextPosition board)

allLegalMoves color board = foldr
  (\position legalPositions -> if isLegalMove color board position then position : legalPositions else legalPositions)
  []
  allPositions

isLegalMove :: Piece -> Board -> Position -> Bool
-- isLegalMove color board position = fromMaybe Empty (Data.Map.lookup position board) == Empty && any (isRow color board position) directions
isLegalMove color board position = (changedPiecesOfMove color board position) /= []

makeMove :: Piece -> Board -> Position -> Board
makeMove color board position = Data.Map.union (Data.Map.fromList (zip (changedPiecesOfMove color board position) (repeat color))) board

changedPiecesOfMove :: Piece -> Board -> Position -> [Position]
changedPiecesOfMove color board position =
  if flipped /= []
    then position : flipped
    else []
  where flipped = concat (map (changedPiecesInRow color board position) directions)

changedPiecesInRow :: Piece -> Board -> Position -> Position -> [Position]
changedPiecesInRow color board position direction = changedPiecesInRow' True color board position direction
  where
    changedPiecesInRow' firstLevel color board position direction =
      if nextColor == opponentColor color then
        if restOfRow /= []
          then if not firstLevel
            then position : restOfRow
            else restOfRow
          else []
      else if nextColor == color then
        if not firstLevel
          then [position]
          else []
      else
        []
      where
        nextPosition = addPosition position direction
        nextColor = fromMaybe Empty (Data.Map.lookup nextPosition board)
        restOfRow = changedPiecesInRow' False color board nextPosition direction


numPiecesAdvantage :: Piece -> Board -> Int
numPiecesAdvantage color board = sum (map
  (\((_, _), x) ->
    if x == color
      then 1
      else if x == opponentColor color
        then -1
        else 0)
  (Data.Map.toList board))

numOptionsAdvantage :: Piece -> Board -> Int
numOptionsAdvantage color board = numOptions color board - numOptions (opponentColor color) board
  where
    numOptions color board = sum (map
      (\position -> if isLegalMove color board position then 1 else 0)
      allPositions)

advantage :: Piece -> Board -> Int
advantage color board = numPiecesAdvantage color board + 10 * numOptionsAdvantage color board



bestMove :: (Piece -> Board -> Int) -> Piece -> Board -> Position
bestMove advantageFunction color board =
  (\(x, _) -> x)
    (maximumBy
      (\(_, x) (_, y) -> compare x y)
      (map
        (\position -> (position, advantageFunction color (makeMove color board position)))
        allPositions))



minMaxAdvantage :: Int -> Piece -> Board -> Int
minMaxAdvantage depth color board =
  let
    allLegalOpponentMoves = allLegalMoves (opponentColor color) board
    allLegalProponentMoves = allLegalMoves color board
    gameOver = allLegalProponentMoves == [] && allLegalOpponentMoves == []
  in if gameOver
    then
      -- Game over, so just report something huge for the winner.
      if numPiecesAdvantage color board > 0
        then 1000000
        else -1000000
    else
      if depth <= 0
        then
          -- At the maximul depth, use the herustic.
          advantage color board
        else
          -- Recursively find the proponents worst advantage after the opponent made their best move.
          let
            nextColor = if allLegalOpponentMoves /= [] then opponentColor color else color
            legalMovesForNextColor = if nextColor /= color then allLegalOpponentMoves else allLegalProponentMoves
            maxAdvantageForNextColor =
              maximum (map
                (\position -> minMaxAdvantage (depth-1) nextColor (makeMove nextColor board position))
                legalMovesForNextColor)
          in if nextColor /= color
            then - maxAdvantageForNextColor
            else   maxAdvantageForNextColor





boardToAscii :: Board -> String
boardToAscii board =
  "\n  0 1 2 3 4 5 6 7 \n +-+-+-+-+-+-+-+-+\n" ++
  (intercalate
    "\n +-+-+-+-+-+-+-+-+\n"
    (map
      (boardToRow board)
      [0..7])) ++
  "\n +-+-+-+-+-+-+-+-+\n  0 1 2 3 4 5 6 7 \n"

boardToRow :: Board -> Int -> String
boardToRow board row = show row ++ "|" ++
  (intercalate "|" (map
    (\position -> colorToAscii (fromMaybe Empty (Data.Map.lookup position board)))
    ([(x, row) | x <- [0..7]]))) ++
  "|" ++ show row


colorToAscii :: Piece -> String
colorToAscii color =
  case color of
    Empty -> " "
    White -> "O"
    Black -> "X"


-- portion :: Int -> [a] -> [[a]]
-- portion n l = unfoldr f l
--   where f x = case x of
--     [] -> Nothing
--     xs -> Just (take n xs, drop n xs)


userMove color board = do
  -- Game Over when no one can make a move.
  let gameOver = allLegalMoves color board == [] && allLegalMoves (opponentColor color) board == []
  if gameOver
    then
      do
        putStr "Game Over\n"
        -- Print the color of the winner.

        if numPiecesAdvantage color board == 0
          then
            putStr "Tie"
          else
            if numPiecesAdvantage color board > 0
              then putStr ((colorToAscii color) ++ " won.")
              else putStr ((colorToAscii (opponentColor color)) ++ " won.")
    else
      do
        putStr (boardToAscii board)
        if color == White
          then
            -- Player move.
            do
              position <- readLn
              if not (isLegalMove color board position)
                then
                  -- Prompt again for a valid move.
                  do
                    putStr "Illegal move.\n"
                    userMove color board
                else
                  actuallyMove position
          else
            actuallyMove (bestMove (minMaxAdvantage 4) color board)
            -- AI move.
            where
              actuallyMove position =
                -- Make the move and switch player if possible, then prompt the new (or the old) player for the next move.
                do
                  let
                    resultingBoard = makeMove color board position
                    nextColor = if allLegalMoves (opponentColor color) resultingBoard /= [] then opponentColor color else color
                  userMove nextColor resultingBoard




main = do userMove White initialBoard
