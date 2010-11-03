require 'date'

class Player
  attr_accessor :name, :score, :turns, :deck, :opening, :ppt
  def initialize name, score, turns, deck, opening
    @name = name
    @score = score
    @turns = turns
    @deck = deck
    @opening = opening
    @ppt = @score.to_f/@turns
  end
  def deck_size
    count = 0
    @deck.each_value {|cards| count += cards}
    return count
  end
end

class Game
  attr_accessor :set, :players, :winner
  def initialize set, players
    @set = set
    @players = players
    high_score = 0
    @players.each { |player|
      if player.score > high_score
        @winner = player
        high_score = player.score
      end
    }
  end
end


def load_data
  end_date = Date.civil(y=2010, m=11, d=2)
  date = Date.civil(y=2010, m=10, d=11)
  games = []
  while date != end_date
    file_name = "domstats%04d%02d%02d.rbdata" % [date.year, date.month, date.day]
    games += Marshal.load(open(file_name))
    date += 1
  end
  return games
end

def first_player_advantage
  games = load_data
  p "total games is #{games.size}"
  first_player_win = 0
  second_player_win = 0
  two_player_games = 0
  games.each do |game|
    if game.players.size == 2 #only 2p for now
      two_player_games += 1
      if game.winner and game.players.first.name == game.winner.name
        first_player_win += 1
      elsif game.winner and game.players[1].name == game.winner.name
        second_player_win += 1
      end
    end
  end
  p "total 2p games is #{two_player_games}"
  p "first player win rate is #{first_player_win.to_f/two_player_games}"
  p "second player win rate is #{second_player_win.to_f/two_player_games}"
end

def tie_games
  games = load_data
  tie_games = 0
  two_player_games = 0
  games.each do |game|
    if game.players.size == 2 #only 2p for now
      two_player_games += 1
      if game.winner == nil
        tie_games += 1
      end
    end
  end
  p "tie games is #{tie_games}"
end

def games_won_by_tiebreaker
  games = load_data
  broken_ties = 0
  two_player_games = 0
  games.each do |game|
    if game.players.size == 2
      two_player_games += 1
      if game.winner = game.players[1] and game.players[0].score == game.players[1].score
        broken_ties += 1
      end
    end
  end
  p "percentage of games broken by tie is #{broken_ties.to_f/two_player_games}"
end  

def first_player_extra_turn_win_margin
  games = load_data
  p1_won_equal_turns = 0
  equal_turns = 0
  games.each do |game|
    if game.players.size == 2 and game.players[0].turns == game.players[1].turns
      equal_turns += 1
      if game.players[0] == game.winner
        p1_won_equal_turns += 1
      end
    end
  end
  p "p1 won in equal turns #{p1_won_equal_turns.to_f/equal_turns*100}"
end

def opening_histogram
  games = load_data
  opening_histogram = {}
  games.each do |game|
    if game.players.size == 2
      game.players.each do |player|
        begin
          opening = player.opening.sort
        rescue
          opening = player.opening
        end
        unless opening_histogram.has_key? opening
          opening_histogram[opening] = [0, 0] #games, wins
        end
        opening_histogram[opening][0] += 1
        if player == game.winner
          opening_histogram[opening][1] += 1
        end
      end
    end
  end
  file = open('win_rates.txt', 'w')
  winrate_histogram = {}
  opening_histogram.each_pair do |opening, games_wins|
    if games_wins[0] > 9
      winrate_histogram[opening] = games_wins[1].to_f/games_wins[0]
    end
  end
  sorted_winrate = winrate_histogram.sort {|a, b| a[1] <=> b[1]}
  sorted_winrate.each do |opening, win_rate|
    file.write "win rate for #{opening[0]}, #{opening[1]} is #{win_rate}\n"
  end
  file.close
end
first_player_advantage
tie_games
first_player_extra_turn_win_margin
games_won_by_tiebreaker
opening_histogram    
