#encoding: UTF-8
module Players_stat
#сбор статистики по вводу кодов игроками на текущей игре
  #запись данных в файл json


  def chat_registered?(id)
    @players = JSON.parse(@players)
    return @players[id].nil? ? false : true
  end

  def register_player(id, user)
    if @players[@chat_id]['users'][id].nil?
      @players[@chat_id]['users'][id] = {}
      if user.username.nil?
        @name = user.first_name unless user.first_name.nil?
        @name += user.last_name unless user.last_name.nil?
      else
        @name = user.username
      end
      @players[@chat_id]['users'][id]["name"] = @name
      @players[@chat_id]['users'][id]["times"] = 1
      write_json_stats
    else
      @players[@chat_id]['users'][id]['times'] += 1
      write_json_stats
    end
  end

  def show_players
    if @players[@chat_id]['users'] == {}
      send('text', 'Из этого чата еще не было отправки кодов')
    else
      stats = "Статистика игроков этого чата:\n"
      @players[@chat_id]['users'].each{ |player|
        stats += '@' + player[1]['name'] + ' - ' + player[1]['times'].to_s + "\n" unless player[1]['name'].nil?
      }
      send('text', stats)
    end
  end



  def register_chat(id)
    @players[id] = {}
    @players[id]["users"] = {}
    write_json_stats
  end

  def check_chat(id)
    @players = File.open('stat.json') { |file| file.read }
    register_chat(id) unless chat_registered?(id)
  end

  def write_json_stats
    File.open('stat.json', 'w') { |file|
      if @players[@chat_id]['users'] != {}
        @players[@chat_id]['users'] = @players[@chat_id]['users'].to_a.sort_by { |_key, val| val['times'] }.reverse.to_h
      end
      file.write JSON.generate(@players)
    }
  end
end