module ChessPieces
  def piece_s(piece)
    pieces = {
      'b-king' => "\u2654",
      'b-queen' => "\u2655",
      'b-rook' => "\u2656",
      'b-bishop' => "\u2657",
      'b-knight' => "\u2658",
      'b-pawn' => "\u2659",
      'w-king' => "\u265A",
      'w-queen' => "\u265B",
      'w-rook' => "\u265C",
      'w-bishop' => "\u265D",
      'w-knight' => "\u265E",
      'w-pawn' => "\u265F"
    }
    pieces[piece]
  end

  def sum_pos(p1, p2)
    [p1, p2].transpose.map { |x| x.reduce(:+) }
  end

  def white?(piece)
    piece == w_king || piece == w_queen || piece == w_rook || piece == w_bishop || piece == w_knight || piece == w_pawn
  end

  def black?(piece)
    piece == b_king || piece == b_queen || piece == b_rook || piece == b_bishop || piece == b_knight || piece == b_pawn
  end

  def w_queen
    piece_s('w-queen')
  end

  def w_rook
    piece_s('w-rook')
  end

  def w_bishop
    piece_s('w-bishop')
  end

  def w_knight
    piece_s('w-knight')
  end

  def w_king
    piece_s('w-king')
  end

  def w_pawn
    piece_s('w-pawn')
  end

  def b_king
    piece_s('b-king')
  end

  def b_queen
    piece_s('b-queen')
  end

  def b_rook
    piece_s('b-rook')
  end

  def b_bishop
    piece_s('b-bishop')
  end

  def b_knight
    piece_s('b-knight')
  end

  def b_pawn
    piece_s('b-pawn')
  end
end

class ChessPiece
  include ChessPieces
  attr_reader :symbol, :position, :has_moved, :translations

  def initialize(symbol, pos)
    @symbol = symbol
    @translations = []
    @eat_translations = []
    @max_multiplier = 8
    @position = [pos[0], pos[1]]
    @has_moved = false
  end

  def alive?
    @state == 'alive'
  end

  def set_pos(pos)
    @position = pos
  end

  def valid_move?(pos)
    @translations.each do |trans|
      (@max_multiplier + 1).times do |i|
        result = sum_pos(@position, trans.map { |x| x * i })
        return trans if result == pos
      end
    end
    false
  end

  def valid_eat?(pos, _piece = nil)
    valid_move?(pos)
  end
end

class King < ChessPiece
  def initialize(symbol, pos)
    super
    @castle_translations = [[0, 2], [0, -2]]
    @translations = [[1, 1], [1, 0], [1, -1], [0, 1],
                     [0, -1], [-1, 1], [-1, 0], [-1, -1]]
    @max_multiplier = 1
  end

  def valid_castle?(pos)
    @castle_translations.each do |trans|
      return true if sum_pos(@position, trans) == pos
    end
    false
  end
end

class Queen < ChessPiece
  def initialize(symbol, pos)
    super
    @translations = [[1, 1], [1, 0], [1, -1], [0, 1],
                     [0, -1], [-1, 1], [-1, 0], [-1, -1]]
  end
end

class Rook < ChessPiece
  def initialize(symbol, pos)
    super
    @translations = [[1, 0], [0, 1], [0, -1], [-1, 0]]
  end
end

class Bishop < ChessPiece
  def initialize(symbol, pos)
    super
    @translations = [[1, 1], [1, -1], [-1, 1], [-1, -1]]
  end
end

class Knight < ChessPiece
  def initialize(symbol, pos)
    super
    @translations = [[2, 1], [2, -1], [1, 2], [1, -2],
                     [-2, 1], [-2, -1], [-1, 2], [-1, -2]]
    @max_multiplier = 1
  end
end

class Pawn < ChessPiece
  attr_accessor :en_passant_right, :en_passant_left, :ate_en_passant

  def initialize(symbol, pos)
    super
    if symbol == w_pawn
      @translations = [[1, 0]]
      @eat_translations = [[1, 1], [1, -1]]
    else
      @translations = [[-1, 0]]
      @eat_translations = [[-1, 1], [-1, -1]]
    end
    @max_multiplier = 2
    @en_passant_right = false
    @en_passant_left = false
    @ate_en_passant = false
  end

  def check_en_passant
    if white?(symbol)
      return [1, 1] if @en_passant_right

      return [1, -1] if @en_passant_left
    else
      return [-1, 1] if @en_passant_right

      return [-1, -1] if @en_passant_left
    end
    false
  end

  def valid_eat?(pos, piece)
    @ate_en_passant = false
    @eat_translations.each do |trans|
      aux_pos = sum_pos(@position, trans)
      if check_en_passant == trans
        @ate_en_passant = true
        return trans
      end
      next if piece == '*'

      return trans if aux_pos == pos && white?(symbol) != white?(piece&.symbol)
    end
    @en_passant_left = false
    @en_passant_right = false
    res = valid_move?(pos)

    @max_multiplier = 1 if res
    res
  end
end
