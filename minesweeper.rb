require 'yaml'
require 'colorize'

class MineSweeper
  attr_accessor :board
  def initialize(board_and_bombs = [9,10], save_file = "new" )
    if save_file != "new"
      save_contents = []
      File.readlines(save_file).each { |line| save_contents << line }
      new_board = YAML.load(save_contents[0..-2].join(""))
      @total_time = save_contents.last.to_f
    else
      new_board = Board.new(board_and_bombs[0],board_and_bombs[1])
      new_board.generate
      @total_time = 0
    end

    @board = new_board
  end

  def flag(position)
    x, y = position
    @board.board[x][y].flagged = true
    @board.board[x][y].display_value = "F ".red
  end

  def unflag(position)
    x, y = position
    @board.board[x][y].flagged = false
    @board.board[x][y].display_value = "* "
  end

  def reveal(position)
    x, y = position
    if @board.board[x][y].bombed
      return true
    elsif !@board.board[x][y].revealed
      bomb_free_neighbors, number_of_bombs = check_neighbors(x, y)
      @board.board[x][y].revealed = true

      if number_of_bombs == 0
        @board.board[x][y].display_value = "_ ".light_white
        bomb_free_neighbors.each { |tile| reveal(tile) }
      else
        @board.board[x][y].display_value = number_of_bombs.to_s.light_white + " "
      end
    end
    false
  end

  def play
    start_time = Time.now
    has_lost = false
    has_won = false

    until has_won
      @board.display
      puts
      p "Pick a tile to reveal or flag:"
      input = gets.chomp.split(" ")
      input[0] = input[0].to_i
      input[1] = input[1].to_i

      if input[2] == "f"
        flag([input[0], input[1]])
      elsif input[2] == "u"
        unflag([input[0], input[1]])
      elsif input[2] == "s"
        @total_time = Time.now - start_time
        save(input[3])
        p "Game saved to #{input[3]}"
        break
      else
        has_lost = reveal([input[0],input[1]])
      end
      if has_lost
        p "You lose!"
        break
      end
      has_won = has_won?
    end
    if has_lost
      reveal_bombs
      @board.display
    end
    if has_won
      @total_time = Time.now - start_time + @total_time
      p "You've won in #{@total_time} seconds!"
    end

  end

  def reveal_bombs
    (0..@board.board.size-1).each do |row|
      (0..@board.board.size-1).each do |column|
        if @board.board[row][column].bombed
          @board.board[row][column].display_value = "B ".red
        end
      end
    end


  end

  def save(file = "save.txt")
    File.open(file, "w") do |f|
      f.puts @board.to_yaml
      f.puts @total_time
    end
  end

  def has_won?
    @board.board.each do |line|
      line.each do |tile|
        if tile.display_value == "* "
          return false
        end
      end
    end
    true
  end

  def check_neighbors(x, y)
    bomb_free_neighbors = []
    number_of_bombs = 0
    (-1..1).each do |i|
      (-1..1).each do |j|
        if  (x + i >= 0) && (x + i < @board.board.size) && (y + j >= 0) && (y + j < @board.board.size)
          if !@board.board[x + i][y + j].bombed
            bomb_free_neighbors << [x + i, y + j]
          else
            number_of_bombs += 1
          end
        end
      end
    end
    [bomb_free_neighbors, number_of_bombs]
  end

end

class Tile
  attr_accessor :bombed, :revealed, :flagged, :display_value
  def initialize(bombed = false, revealed = false, flagged = false, display_value = "* ")
    @bombed, @revealed, @flagged, @display_value = bombed, revealed, flagged, display_value
  end

  def dup

  end

end

class Board
  attr_accessor :board

  def initialize(size = 9, number_of_bombs = 10)
    # @board = Array.new(size, Array.new(size, nil))
    @board = []
    (0..size-1).each do |row|
      @board[row] = []
      (0..size-1).each do |column|
       @board[row][column] = Tile.new
      end
    end
    @size, @number_of_bombs = size, number_of_bombs
  end

  def generate
    bombs = []
    @board.map! do |line|
      line.map! do |tile|
        tile = Tile.new
      end
    end
    until bombs.count == @number_of_bombs
      potential_bomb = [rand(@size),rand(@size)]
      if !bombs.include?(potential_bomb)
        bombs << potential_bomb
      end
    end
    bombs.each do |bomb|
      @board[bomb.first][bomb.last].bombed = true
    end
  end

  def display

    top_half = "   "
    bot_half = "   "
    @size.times do |i|
      bot_half += "#{i % 10} ".yellow
      top_half += "#{i / 10 == 0 ? " " : "#{i / 10}"} ".yellow
    end
    puts top_half
    puts bot_half
    @board.each_with_index do |line, i|
      print "#{i} ".rjust(3," ").yellow
      line.each { |tile| print tile.display_value }
      puts
    end
  end
end

p "Would you like to continue from a saved game? Y/N:"
if gets.chomp.upcase == "Y"
  p "Enter the saved game name:"
  game = MineSweeper.new(gets.chomp)
else
  p "Enter board size and number of bombs:"
  game = MineSweeper.new(gets.chomp.split(" ").map(&:to_i))
end

game.play
