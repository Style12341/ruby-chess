require './lib/chess_board'

class Chess
  attr_accessor :board

  include ChessPieces
  def initialize
    @board = ChessBoard.new
    @players = %w[White Black]
    @is_checked = { 'White' => false, 'Black' => false }
  end

  # Tries to get a valid move from the player
  def get_move(player)
    print "Enter moves in the format: a2 a4 (from a2 to a4) \nMove: "
    begin
      move = gets.chomp
      move = parse_move(move)
      raise 'Invalid format or out of board bounds. Try again.' unless move.all? do |pos|
        pos.all? do |x|
          x.between?(0, 7)
        end
      end && move.length == 2
      raise 'Not your Piece. Try again.' unless @board.get_piece_color(move[0]) == player

      path = @board.check?(player)
      possible_moves = @board.can_block?(path, player)
      raise "You're in check. Try Again" if possible_moves && !possible_moves.key?(@board.get_piece(move[0]))

      moves_for_piece = possible_moves[@board.get_piece(move[0])] if possible_moves
      raise 'Invalid move. Still in check' if possible_moves && !moves_for_piece.include?(move[1])
    rescue StandardError => e
      puts e
      @board.display
      retry
    end
    move
  end

  # Parses long algebraic to matrix positions
  def parse_move(move)
    move = move.split(' ')
    move.map do |pos|
      pos = pos.split('')
      row = pos[1].to_i - 1
      col = pos[0].ord - 'a'.ord
      [row, col]
    end
  end

  def initial_announcement
    puts 'Welcome to Chess!'
    puts 'White goes first.'
    puts 'Enter moves in the format: a2 a4 (from a2 to a4)'
  end

  def move_piece(player)
    # move piece

    raise 'Illegal move. Try again.' unless @board.move(get_move(player))
  rescue StandardError => e
    puts e
    retry
  end

  def only_king?(player)
    @board.board.each do |row|
      row.each do |piece|
        if piece.is_a?(ChessPiece) && @board.get_piece_color(piece.position) == player && !piece.is_a?(King)
          return false
        end
      end
    end
    true
  end

  def check_stalemate(player)
    return unless !@board.check?(player) && board.checkmate?(player) && only_king?(player)

    @board.display
    puts 'Stalemate!'
    exit
  end

  def announce_check(player)
    return unless @board.check?(player)

    puts "#{player} is in check!"
    return unless @board.checkmate?(player)

    @board.display
    puts "#{player} is in checkmate!"
    puts "#{other_player(player)} wins!"
    exit
  end

  def other_player(player)
    player == 'White' ? 'Black' : 'White'
  end

  def play
    @players.cycle do |player|
      @board.display
      puts "#{player}'s turn"
      move_piece(player)
      announce_check(other_player(player))
    end
  end
end

board = Chess.new.play
