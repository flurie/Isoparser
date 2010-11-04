require 'zlib'
require 'date'
require 'open-uri'

#start date is date from which logs were first made available
$start_date = Date.civil(y=2010, m=10, d=11)
#this can bug if there's a day change without a new game, so I don't get today
$end_date = Date.today - 1 

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
    @deck.values.inject {|count, cards| count += cards}
    return count
  end
end

class Game
  attr_accessor :set, :players, :winner
  def initialize set, players, winner
    @set = set
    @players = players
    if winner 
      @players.each do |player|
        if player.name == winner
          @winner = player
        end
      end
    else
      @winner = nil
    end
  end
end

def get_game_names(date)
  start_string = "http://dominion.isotropic.org/gamelog/games-"
  end_string = ".csv"
  date_string = "%04d%02d%02d" % [date.year, date.mon, date.day]
  yearmon_string = "%04d%02d" % [date.year, date.mon]
  day_string = "%02d" % date.day
  names ||= []
  open(start_string + date_string + end_string) do |f|
    f.each_line do |line|
      data = line.split(',')
      names << "http://dominion.isotropic.org/gamelog/#{yearmon_string}/#{day_string}/" + data[2] if data[3].to_i > 1 #eliminate solo games
    end
    date += 1
  end
  return names
end


def singular name
  #all ending in y
  if name =~ /ies$/
    return name.sub(/ies$/, 'y')
  elsif ["Goons", "Gardens", "Smugglers", "Nobles", "Ironworks"].include? name
    return name
    #witches/stashes
  elsif name =~ /hes$/
    return name.sub(/es$/, '')
  elsif name =~ /oes$/
    return name.sub(/oes$/, 'o')
  else
    return name.sub(/s$/, '')
  end
end

def parse_file(uri)
  player_list = []
  resp = open(uri)
  contents = Zlib::GzipReader.new(StringIO.new(resp.read)).read
  supply = []
  contents =~ /cards in supply: (.*)\n/
  $1.split(', ').each do |card|
    card =~ /(?:and )?<[^>]+>([\w ]+)<\/span>/
    supply << $1
  end
  deck_split = %r{\[\d+ cards\] (?:((\d+) <[^>]+>(\w+)</span>),? ?)+}
  data = contents.split(/-{22}/)[1].strip.split(/\n\n/).each do |player_data|
    player_info, opening_buys_info, deck_contents = player_data.split(/\n/)
    player_info =~ /<b>(.*): ([-\d]+) points<\/b>.*; (\d+) turns/
    player = $1
    points = $2.to_i
    turns = $3.to_i
    opening_buys = []
    opening_buys_info =~ /opening: <[^>]+>([\w ]+)<\/span> \/ <[^>]+>([\w ]+)<\/span>/
    opening_buys << $1 << $2
    deck = {}
    begin
      deck_contents.sub!(/\[\d+ cards\] /, "").split(', ').each do |card|
        card =~ /(\d+) <[^>]+>([\w ]+)<\/span>/
        #deal with plurals
        if $1.to_i > 1
          deck[singular($2)] = $1.to_i
          #already singular
        else
          deck[$2] = $1.to_i
        end
      end
    rescue #no cards
      deck = {}
    end
    #turn order
    contents =~ /Turn order is (.*)/
    players = $1.split(/, /)
    if players.size == 1 #two players
      players = players[0].split(/ and then /)
      players[-1].sub!(/.$/, '')
    else
      players.each do |name|
        if name =~ /and then/
          name.sub!(/and then /, '').sub!(/.$/, '')
        end
      end
    end
    players.each_index do |index|
      if players[index] == player
        player_list[index] = Player.new(player, points, turns, deck, opening_buys)
      end
    end
  end
  if contents  =~ /<pre>(.*) wins!/
    winner = $1
  else
    winner = nil
  end
  return Game.new(supply, player_list, winner)
end

def get_game_data date
  game_list = []
  get_game_names(date).each do |game|
    p "getting game #{game}"
    begin
      game_list << parse_file(game)
    rescue
      p "could not get game #{game}!"
    end
  end
  return game_list
end

date = Date.parse(ARGV[0])
file_name = "domstats%04d%02d%02d.rbdata" % [date.year, date.month, date.day]
file = open(file_name, 'w+')
file << Marshal.dump(get_game_data(date))
file.close


