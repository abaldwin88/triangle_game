# A small script that finds the solution to the cracker barrel peg game / triangle game.
# Instructions along with one of the game's solution can be found here:
# http://www.joenord.com/puzzles/peggame/
# The solution is determined by building a game tree and using a depth-first search algorithm.
# Game Tree: https://en.wikipedia.org/wiki/Game_tree
# Depth First Search: https://en.wikipedia.org/wiki/Depth-first_search
# The slot's are numbered 0 - 14 in sequential order (Top to Bottom, Left to Right)
#     /0\
#    /1 2\
#   /3 4 5\
#   etc etc

class Slot
  # Represents a single slot opening of the triangle game.
  # This class holds the slot number, it's possible jump
  # dictionary and helper functions around maintaining slots.
  getter :num, :jump_dict
  @num : Int32
  @jump_dict : Hash(Int32, Int32)

  def initialize(num, jump_dict)
    # :param num: slot number corresponding to jump_from
    # :param jump_dict: possible jumps in the format {jump_over: jump_to}
    @num = num
    @jump_dict = jump_dict
    @peg = true
  end

  def peg?
    @peg
  end

  def removed?
    !@peg
  end

  def add_peg
    @peg = true
  end

  def remove_peg
    @peg = false
  end
end

class Triangle
  # Represents a single board of the triangle game.
  getter :board, :peg_count

  def initialize(remove_pegs = [] of Int32 )
    # Initializes the board for a new game.
    # board: consists of 15 Slot() objects
    # peg_count: A running total of the slots that still contain a peg

    @board = [
      Slot.new(0, { 1 => 3, 2 => 5 }),
      Slot.new(1, { 3 => 6, 4 => 8 }),
      Slot.new(2, { 4 => 7, 5 => 9 }),
      Slot.new(3, { 4 => 5, 1 => 0, 6 => 10, 7 => 12 }),
      Slot.new(4, { 7 => 11, 8 => 13 }),
      Slot.new(5, { 2 => 0, 4 => 3, 8 => 12, 9 => 14 }),
      Slot.new(6, { 3 => 1, 7 => 8 }),
      Slot.new(7, { 4 => 2, 8 => 9 }),
      Slot.new(8, { 4 => 1, 7 => 6 }),
      Slot.new(9, { 5 => 2, 8 => 7 }),
      Slot.new(10, { 6 => 3, 11 => 12 }),
      Slot.new(11, { 7 => 4, 12 => 13 }),
      Slot.new(12, { 11 => 10, 7 => 3, 8 => 5, 13 => 14 }),
      Slot.new(13, { 12 => 11, 8 => 4 }),
      Slot.new(14, { 13 => 12, 9 => 5 })
    ]

    @peg_count = 15

    remove_pegs.each do |i|
      board[i].remove_peg
      @peg_count -= 1
    end
  end

  def jump(jump_from, jump_over, jump_to)
    # Executes a jump action
    # :param jump_from: Peg number.  This is the jump_from
    # :param jump_over: Peg number to be jumped over and removed
    # :param jump_to: Empty slot number for the peg to jump into

    raise "blah" unless board[jump_from].peg?
    raise "blah"unless board[jump_over].peg?
    raise "blah" if board[jump_to].peg?

    @peg_count -= 1
    @board[jump_from].remove_peg
    @board[jump_over].remove_peg
    @board[jump_to].add_peg
  end

  def remove_first_peg(slot)
    # The first action of every game is to remove a peg from a full board
    raise "blah" unless peg_count == 15

    @peg_count -= 1
    @board[slot].remove_peg
  end

  def possible_peg_jumps(slot)
    # Determines all possible jumps given a particular slot
    # :param slot: Integer for a particular slot
    # :return: Dictionary of possible jumps in the form of {jump_over: jump_to}

    raise "blah" unless @board[slot].peg?

    result = {} of Int32 => Int32
    @board[slot].jump_dict.map do |jump_over, jump_to|
      result[jump_over] = jump_to if @board[jump_over].peg? && !@board[jump_to].peg?
    end
    result
  end

  def all_possible_jumps
    # Determine all possible jumps for the entire board
    # :return: Dictionary of Dictionaries containing slot numbers and their available jumps

    result = Hash(Int32, Hash(Int32, Int32)).new
    (0..14).each do |i|
      next unless @board[i].peg?

      jumps = possible_peg_jumps(i)
      next if jumps.empty?

      result[i] = jumps
    end
    result
  end

  def removed_pegs
    @board.map do |slot|
      slot.num if slot.removed?
    end.compact
  end
end

class GameNode
  getter :triangle, :jump, :parent

  @parent : GameNode | Nil
  @triangle : Triangle
    # Represents a single node of the game tree

  def initialize(parent, jump : Int32 | Array(Int32), triangle)
        #children: Dictionary containing a jump sequence as keys and child nodes as values.
                  #In the form of {(jump_from, jump_over, jump_to): GameNode()}
                  #Values of the children dict that are set to None represent unexplored branches.
        #:param parent: GameNode() object containing the parent node.
                       #A value of None represents the root Node.
        #:param jump: tuple containing the jump sequence at this node
        #:param triangle: Triangle() object

    # Determine whether this node is the first move of the game and act appropriately
    if jump.is_a? Int32
      triangle.remove_first_peg(jump)
    else
      triangle.jump(jump[0], jump[1], jump[2])
    end

    # Fill children dictionary with all possible jump tuples as keys
    @children = Hash(Array(Int32), GameNode | Nil).new

    all_jumps = triangle.all_possible_jumps

    all_jumps.each do |jump_from, jumps|
      jumps.each do |jump_over, jump_to|
        @children[[jump_from, jump_over, jump_to]] = nil
      end
    end

    @parent = parent
    @jump = jump
    @triangle = triangle
  end

  def next_node
    @children.each do |jump, child_node|
      return init_child_node(jump) if child_node.nil?
    end

    @parent
  end

  def init_child_node(jump)
    triangle_copy = Triangle.new(remove_pegs: triangle.removed_pegs)
    node = GameNode.new(self, jump, triangle_copy)
    @children[jump] = node
    node
  end
end

def jump_history(node)
  # Returns a list of moves from the start of the game to the passed in node
  # :param node: GameNode() object
  # :return: Move history list in chronological order

  history = Array(Int32 | Array(Int32)).new
  loop do
    history << node.not_nil!.jump
    break unless node.not_nil!.parent

    node = node.not_nil!.parent
  end
  history.reverse
end

#game_node = GameNode.new(nil, 4, Triangle.new)
game_node = GameNode.new(nil, ARGV[0].to_i, Triangle.new)

loop do
  game_node = game_node.not_nil!.next_node
  break if game_node.not_nil!.triangle.peg_count == 1
end

pp jump_history(game_node)
