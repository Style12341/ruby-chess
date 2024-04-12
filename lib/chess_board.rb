require './lib/chess_piece'

class ChessBoard
  include ChessPieces
  def initialize
    @board = Array.new(8) { Array.new(8, '*') }
    initial_pieces
  end

  def get_piece(pos)
    @board[pos[0]][pos[1]]
  end

  def castle(move)
    from = move[0]
    to = move[1]
    piece = @board[from[0]][from[1]]
    return false if piece.has_moved || !piece.valid_castle?(to)

    if to[1] - from[1] == 2
      rook = @board[to[0]][7]
      return false if !free_check_path?(from, to, [0, 2]) || rook.has_moved

      @board[to[0]][5] = rook
      rook.set_pos([to[0], 5])
      @board[to[0]][7] = '*'
      @board[from[0]][from[1]] = '*'
      @board[to[0]][6] = piece
    else
      rook = @board[to[0]][0]
      return false if !free_check_path?(from, to, [0, -2]) || rook.has_moved

      @board[to[0]][3] = rook
      rook.set_pos([to[0], 3])
      @board[to[0]][0] = '*'
      @board[from[0]][from[1]] = '*'
      @board[to[0]][2] = piece
      piece.set_pos([to[0], 2])
    end
    true
  end

  def king_move(move)
    return true if castle(move)

    from = move[0]
    to = move[1]
    piece = @board[from[0]][from[1]]
    trans = piece.valid_eat?(to)
    return false unless trans
    raise 'Position is in check' if has_check?(to, get_piece_color(from))

    @board[to[0]][to[1]] = piece
    piece.set_pos(to)
    @board[from[0]][from[1]] = '*'
    true
  end

  def checkmate?(player)
    @board.each do |row|
      row.each do |piece|
        next unless piece.is_a?(King) && get_piece_color(piece.position) == player

        return piece.translations.none? do |trans|
          pos = sum_pos(piece.position, trans)
          next unless pos.all? { |x| x.between?(0, 7) }

          piece.valid_move?(pos) && has_check?(pos, player)
        end
      end
    end
  end

  def fill_en_passant(pos)
    piece1 = get_piece([pos[0], pos[1] + 1])
    piece2 = get_piece([pos[0], pos[1] - 1])
    piece1.en_passant_left = true if piece1.is_a?(Pawn)
    piece2.en_passant_right = true if piece2.is_a?(Pawn)
  end

  def eat_en_passant(from, to)
    piece = get_piece(from)
    @board[to[0]][to[1]] = piece
    piece.set_pos(to)
    @board[from[0]][from[1]] = '*'
    @board[from[0]][to[1]] = '*'
  end

  def move(move)
    from = move[0]
    to = move[1]
    piece = @board[from[0]][from[1]]
    trans = piece.valid_eat?(to, get_piece(to)) # Check if it would ve a valid move
    return false if get_piece_color(from) == get_piece_color(to)
    return king_move(move) if piece.is_a?(King)
    return false unless trans
    return false unless free_path?(from, to, trans)

    fill_en_passant(to) if piece.is_a?(Pawn) && trans && (trans[1] = -2 || trans[1] = 2)
    return eat_en_passant(from, to) if piece.is_a?(Pawn) && piece.ate_en_passant && get_piece(to) == '*'

    @board[to[0]][to[1]] = piece
    piece.set_pos(to)
    @board[from[0]][from[1]] = '*'
    true
  end

  # Returns the path of the piece that is attacking the king false if it isn't under attack
  def has_check?(pos, player)
    # Check if position is under attack
    @board.each do |row|
      row.each do |piece|
        next unless piece.is_a?(ChessPiece) && get_piece_color(piece.position) != player
        next if piece.position == pos

        trans = piece.valid_eat?(pos, @board[pos[0]][pos[1]]) # Check if it would ve a valid move
        next unless trans

        path = free_path?(piece.position, pos, trans)
        return path if trans && path
      end
    end
    false
  end

  # Returns Hash of pieces that can block the path of the attacking piece with their valid moves to block the path
  def can_block?(path, player)
    return unless path

    pieces = Hash.new { |h, k| h[k] = [] }
    path.each do |pos|
      @board.each do |row|
        row.each do |piece|
          next unless piece.is_a?(ChessPiece) && get_piece_color(piece.position) == player

          trans = piece.valid_eat?(pos, get_piece(pos))
          pieces[piece].push(pos) if trans && free_path?(piece.position, pos, trans)
        end
      end
    end
    pieces
  end

  # Returns the path of the piece that is attacking the king false if it isn't under attack
  def check?(player)
    # Check if player is in check
    @board.each do |row|
      row.each do |piece|
        return has_check?(piece.position, player) if piece.is_a?(King) && get_piece_color(piece.position) == player
      end
    end
    false
  end

  def free_path?(from, to, trans)
    return true if from == to

    # It has already been checked if it is a valid move
    # checking path
    path = []
    (0..8).each do |i|
      pos = sum_pos(from, trans.map { |x| x * i })
      return path if pos == to

      path.push(pos)
      return false if @board[pos[0]][pos[1]].is_a?(ChessPiece) && path.size > 1
    end
  end

  def free_check_path?(from, to, trans)
    return true if from == to

    player = get_piece_color(from)
    # It has already been checked if it is a valid move
    # checking path
    (1..8).each do |i|
      pos = sum_pos(from, trans.map { |x| x * i })
      return false if @board[pos[0]][pos[1]].is_a?(ChessPiece) || has_check?(pos, player)
      return true if pos == to
    end
  end

  def get_piece_color(pos)
    return unless @board[pos[0]][pos[1]].is_a?(ChessPiece)

    white?(@board[pos[0]][pos[1]].symbol) ? 'White' : 'Black'
  end

  def display
    puts '#   a b c d e f g h'
    7.downto(0) do |x|
      print "# #{x + 1} "
      (0..7).each do |y|
        print "#{display_position(x, y)} "
      end
      puts
    end
  end

  def display_position(x, y)
    if @board[x][y].is_a?(ChessPiece)
      @board[x][y].symbol
    else
      @board[x][y]
    end
  end

  def initial_pieces
    initial_pawns
    initial_others
  end

  def create_piece(piece, pos)
    case piece
    when w_pawn
      Pawn.new(piece, pos)
    when b_pawn
      Pawn.new(piece, pos)
    when w_bishop
      Bishop.new(piece, pos)
    when b_bishop
      Bishop.new(piece, pos)
    when w_knight
      Knight.new(piece, pos)
    when b_knight
      Knight.new(piece, pos)
    when w_rook
      Rook.new(piece, pos)
    when b_rook
      Rook.new(piece, pos)
    when w_queen
      Queen.new(piece, pos)
    when b_queen
      Queen.new(piece, pos)
    when w_king
      King.new(piece, pos)
    when b_king
      King.new(piece, pos)
    end
  end

  def initial_pawns
    (0..7).each do |y|
      @board[1][y] = create_piece(w_pawn, [1, y])
      @board[6][y] = create_piece(b_pawn, [6, y])
    end
  end

  def initial_others
    [0, 7].each do |x|
      @board[0][x] = create_piece(w_rook, [0, x])
      @board[7][x] = create_piece(b_rook, [7, x])
    end
    [1, 6].each do |x|
      @board[0][x] = create_piece(w_knight, [0, x])
      @board[7][x] = create_piece(b_knight, [7, x])
    end

    [2, 5].each do |x|
      @board[0][x] = create_piece(w_bishop, [0, x])
      @board[7][x] = create_piece(b_bishop, [7, x])
    end
    @board[0][3] = create_piece(w_queen, [0, 3])
    @board[0][4] = create_piece(w_king, [0, 4])
    @board[7][3] = create_piece(b_queen, [7, 3])
    @board[7][4] = create_piece(b_king, [7, 4])
  end
end
