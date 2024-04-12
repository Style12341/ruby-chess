require './lib/chess_board'
require 'yaml'

class Chess
  attr_accessor :board, :players, :current_player

  include ChessPieces
  def initialize
    @board = ChessBoard.new
    @players = %w[White Black]
    @current_player = 'White'
  end

  # Tries to get a valid move from the player
  def get_move(player)
    print "Enter moves in the format: a2 a4 (from a2 to a4) \nMove: "
    begin
      move = gets.chomp
      move = parse_move(move)
      raise 'Game Saved' if move.nil?
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
    if move.include? 'save '
      save_game(move.split[1])
      puts 'Game saved!'
      return nil
    end
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

  def fix_save_start
    @players = %w[Black White] if @current_player == 'Black'
  end

  def game_loop
    fix_save_start
    @players.cycle do |player|
      @current_player = player
      @board.display
      puts "#{player}'s turn"
      move_piece(player)
      announce_check(other_player(player))
    end
  end

  def play
    puts 'Welcome to Chess!'
    if saved_games?
      puts 'Would you like to load a saved game? (y/n)'
      answer = gets.chomp
      load_game if answer == 'y'
    end
    puts "You can save the game at any time by typing 'save <savename>'. Ex: save game1"
    game_loop
  end

  private

  def load_data(obj)
    @board = obj.board
    @players = obj.players
    @current_player = obj.current_player
  end

  def save_game(name)
    Dir.mkdir 'saves' unless Dir.exist?('saves')
    File.open("saves/#{name}.yaml", 'w') do |file|
      file.write(YAML.dump(self))
    end
  end

  def get_entries(dir)
    begin
      entries = Dir.entries(dir)
      raise 'No entries found' if entries == ['.', '..']
    rescue StandardError => e
      puts e.message
      nil
    end
    entries
  end

  def get_user_save_input
    puts 'Which save would you like to load? (Enter the number)'
    entries = get_entries('saves')
    begin
      (entries.each_with_index do |file, index|
         puts "#{index + 1}. #{file}" unless ['.', '..'].include?(file)
       end)
      save_number = gets.chomp.to_i
      raise 'Invalid save number' if save_number < 1 || save_number > entries.length - 2
    rescue StandardError => e
      puts e.message
      retry
    end
    save_number - 1
  end

  def load_game
    save_number = get_user_save_input
    File.open("saves/#{Dir.entries('saves')[save_number]}", 'r') do |file|
      load_data(YAML.safe_load(file,
                               permitted_classes: [self.class, ChessBoard, ChessPiece, King, Queen, Rook, Bishop,
                                                   Knight, Pawn]))
    end
  end

  def saved_games?
    Dir.exist?('saves') && Dir.entries('saves').length > 2
  end
end

board = Chess.new.play
