#encoding: UTF-8
module Logs

  def create_logs
    if File.exist?('logs.txt') == false #проверка наличия файла логов
      log_file = File.open("logs.txt", 'a')
      File.open('logs.txt', 'a') { |file| 
        file.write("Дата и время, ID чата, UserName(его id), Что отправил user, Что ответил Бот") }
      return 'Файл логов создан'
    else
      return 'Файл логов существует'
    end
  end

  def write_to_logs(message)
    log_file = File.open('logs.txt', 'a') { |file| 
    file.write(time_log +
      "| #{message.chat.id}(#{message.chat.type}, #{message.chat.title})" +
      "| #{message.from.username}(#{message.from.id})" +
      "| #{message} " + 
      "|||") }
  end

  def time_log
    time = Time.new
    time.strftime("\n %d.%m.%Y %H:%M:%S")
  end

  def chat_access
    chat_access = File.read('chat_access.json')
    chat_access = JSON.parse(chat_access).to_s
  end

  def whrite_engine_to_json
    response = @agent.post(@engine_link)
    @json_engine = JSON.parse(response.body)
    File.open('engine.json', 'w') { |file|
      file.write JSON.pretty_generate(@json_engine)
    }
  end

  def open_level_info_list
    @level_list = File.read('level_info_list.json')
    @level_list = JSON.parse(@level_list)
  end

  def open_json_engine
    @json_engine = File.read('engine.json')
    @json_engine = JSON.parse(@json_engine)
  end

  def open_json_engine_old
    @json_engine_old = File.read('engine_old.json')
    @json_engine_old = JSON.parse(@json_engine_old)
  end

  def whrite_engine_old_to_json
    response = @agent.post(@engine_link)
    @json_engine_old = JSON.parse(response.body)
    File.open('engine_old.json', 'w') { |file|
      file.write JSON.pretty_generate(@json_engine_old)
    }
  end



  def chek_clue_list
    if @json_engine["Event"].to_s == "0"
      if @json_engine["Level"]["Helps"] != []
        open_json_engine
        open_level_info_list
        clue = @json_engine["Level"]["Helps"].each_with_index { |el|
          @level_list["all_clue"]["#{"helps_#{el["Number"]}"}"] = "0"
        }
        File.open('level_info_list.json', 'w') { |file|
          file.write JSON.pretty_generate(@level_list)
        }
      end
    end
  end

  def chek_sector_list
    if @json_engine["Event"].to_s == "0"
      if @json_engine["Level"]["Sectors"] != []
        open_json_engine
        open_level_info_list
        sectors = @json_engine["Level"]["Sectors"].each_with_index { |el|
          @level_list["all_sectors"]["#{el["Order"].to_s}"] = "nobody"
        }
        chek_level_info_list_whrite
      end
    end
  end

  def chek_bonuses_list
    if @json_engine["Event"].to_s == "0"
      if @json_engine["Level"]["Bonuses"] != []
        open_json_engine
        open_level_info_list
        bonuses = @json_engine["Level"]["Bonuses"].each_with_index { |el|
          @level_list["all_bonuses"]["#{el["Number"].to_s}"] = "nobody"
        }
        chek_level_info_list_whrite
      end
    end
  end

  def change_sector_list(message)
    open_level_info_list
    sectors = @json_engine["Level"]["Sectors"].each_with_index { |el|
    	if el["IsAnswered"].to_s == "true"
    		if el["Answer"]["Answer"].to_s == @text
	    		if el["Answer"]["Login"].to_s != @login.to_s
	      		@level_list["all_sectors"]["#{el["Order"].to_s}"] = el["Answer"]["Login"].to_s
	      	else
	      		@level_list["all_sectors"]["#{el["Order"].to_s}"] = "#{message.from.username.to_s}"
	      	end
	      	chek_level_info_list_whrite
	      	return
	      end
      end
    }
  end

  def change_bonuses_list(message)
    open_level_info_list
    bonuses = @json_engine["Level"]["Bonuses"].each_with_index { |el|
      if el["IsAnswered"].to_s == "true"
        if el["Answer"]["Answer"].to_s == @text
          if el["Answer"]["Login"].to_s != @login.to_s
            @level_list["all_sectors"]["#{el["Number"].to_s}"] = el["Answer"]["Login"].to_s
          else
            @level_list["all_sectors"]["#{el["Number"].to_s}"] = "#{message.from.username.to_s}"
          end
          chek_level_info_list_whrite
          return
        end
      end
    }
  end

  def chek_level_info_list_whrite
    File.open('level_info_list.json', 'w') { |file|
      file.write JSON.pretty_generate(@level_list)
    }
  end

end