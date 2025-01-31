#encoding: UTF-8
module Query_to_engine
#------------------------------------------------------ОТПРАВКА КОДОВ-----------------------------------------------------------

  def sendCode(text, message)
    if /^(\.)/.match(text)
      text[0] = ''
      if text[0] == ' '
        text[0] = ''
      end
    else 
      text = text.downcase.gsub(/[Ддd]/, 'D').gsub(/[Ррr]/, 'R')
    end
    @text = text
    
    if @json_engine["Level"]["MixedActions"].to_s.include?(text)
      @json_engine["Level"]["MixedActions"].each_with_index { |el|
        if el["IsCorrect"].to_s == 'true'
          if el["Answer"].to_s == text
            send('text', "\u{2705} -- #{text} -- Этот код уже был!")
            return
          end
        else el["IsCorrect"].to_s == 'false'
          if el["Answer"].to_s == text
            send('text', "\u{26D4} -- #{text} -- Этот код уже был!")
            return
          end
        end
      }
    else

      old_level = level_number.to_s
      @old_arr = old_arr.to_a

      response = @agent.post(@engine_link, params_to_send_code)
      response = JSON.parse(response.body)

      if response["EngineAction"]["LevelAction"]["IsCorrectAnswer"] == true
        whrite_engine_old_to_json
        whrite_engine_to_json
      	new_level = level_number.to_s
      	if old_level == new_level
          @new_arr = new_arr.to_a
      		send('text', "\u{2705} -- #{text} -- Код принят\nМетка №#{check_accepted_kod}" + "\n" + "Осталось - #{sectors_left}" + "\n" + "До слива - " + time_left)
          register_player(message.from.id.to_s, message.from)
          change_sector_list(message)

          if @old_arr == @new_arr
            send_bonus_help_after_kod(message)
            @old_bonuses = @json_engine["Level"]["Bonuses"]
            change_bonuses_list(message)
          end
      	else
      		send('text', "\u{2705} -- #{text} -- Выдан новый уровень!")
      		send('image', 'img/stop.png')
          register_player(message.from.id.to_s, message.from)
      	end
      else
      	send('text', "\u{26D4} -- #{text} -- Код НЕ принят!" + "\n" + "Осталось - #{sectors_left}" + "\n" + "До слива - " + time_left)
      end
    end
  end

  def reset_informations
    @type_kod = ""
    @bonus_text = ""
    @bonus_number = ""
    @bonus_name = ""
    @osn_name = ""
    @time = ""
  end

  def send_bonus_help_after_kod(message)
    @json_engine["Level"]["Bonuses"].each_with_index.map { |el|
    	if el["Answer"] != nil
     		if el["Answer"]["Answer"] == @text
     			@time = el["AwardTime"].to_i
       		@time = seconds_to_hms(@time)
        	if el["Help"] == nil
       	  	send('text', "\u{2705} Введен ответ на бонусный код №#{el["Number"].to_s} (#{@time})\n\u{1F4A1} Текст под спойлером бонуса отсутствует")
            @bonus_text = "Подсказки нет"
            @bonus_number = "#{el["Number"].to_s}"
            @bonus_name = "#{el["Name"].to_s}"
       	  	return
       		else
       	  	send('text', "\u{2705} Введен ответ на бонусный код №#{el["Number"].to_s} (#{@time})\n\u{1F4A1} Текст под спойлером бонуса\n\u{1F4A1} #{el["Help"]}")
            @bonus_text = "#{el["Help"]}"
            @bonus_number = "#{el["Number"].to_s}"
            @bonus_name = "#{el["Name"].to_s}"
       	  	return
       		end
       	end
      end
    }
  end

  def check_send_code_access
    if
      @json_engine["Level"]["IsPassed"] == false and
      @json_engine["Level"]["Dismissed"] == false and
      @json_engine["Level"]["HasAnswerBlockRule"] == false || @json_engine["Level"]["BlockDuration"] <= 0
      true
    else
      false
    end
  end

  def params_to_send_code
    {
      'LevelId' => @json_engine["Level"]["LevelId"],
      'LevelNumber' => @json_engine["Level"]["Number"],
      'LevelAction.Answer' => @text
    }
  end

  def seconds_to_hms(sec)
    "%02d:%02d:%02d" % [sec / 3600, sec / 60 % 60, sec % 60]
  end

  def time_left
  	if @json_engine["Level"]["Tasks"] != nil
  		time = @json_engine["Level"]["TimeoutSecondsRemain"]
  		time = seconds_to_hms(time)
  	else
  		return "Автопереход отсутствует"
    end
  end

  def sectors_need
 		if @json_engine["Level"]["RequiredSectorsCount"] == 0
 			return "На уровне полное закрытие"
 		else
 			@json_engine["Level"]["RequiredSectorsCount"]
 		end
  end

  def sectors_taken
    @json_engine["Level"]["PassedSectorsCount"]
  end

  def sectors_left
 		sectors_need.to_i - sectors_taken.to_i
  end

  def sectors_not_do
 		@json_engine["Level"]["Sectors"].to_a.length unless @json_engine["Level"]["Sectors"].nil?
  end

  def bonuses_not_do
    @json_engine["Level"]["Bonuses"].to_a.length unless @json_engine["Level"]["Bonuses"].nil?
  end

  def bonuses_taked
    if @json_engine["Level"]["Bonuses"] != nil
      bonus = 0
      @json_engine["Level"]["Bonuses"].each_with_index.map { |el|
        if el["IsAnswered"] == true
          bonus += 1
        end
      }
      return bonus
    end
  end

  def zad
  	if @json_engine["Level"]["Tasks"] != []
  		text = @json_engine["Level"]["Tasks"][0]["TaskText"].to_s
  			.gsub(/<(img|a href).*>/, "")
        .gsub(/<br\/>/, "\n")
        .gsub(/<script>(.|\n)*?<\/script>/, "")
        .gsub(/<\/?[A-Za-z]+[^>]*>/, "")
      if text.length > 4095
        text = "Слишком много текста в задании! Смотри движок."
      else
        text
      end
    else
      text = "Нет задания, вот тупо нет никакого текста"
  	end
  end

  def zad_coord
  	if @json_engine["Level"]["Tasks"].to_s.match(/\d+\.\d+/)
  		text = @json_engine["Level"]["Tasks"][0]["TaskText"].to_s
  		text = text.gsub(/^(?:(?!\d+\.\d+(\,\s+|\s+|\,)\d+\.\d+).)*$\s?/, '').gsub(/<\/?[A-Za-z]+[^>]*>/, "")
			text.each_line { |el|
        coords = "#{el[/\d{2,3}\.\d{3,12},?\s+\d{2,3}.\d{3,12}/]}"
        inline_kb = [
        [Telegram::Bot::Types::InlineKeyboardButton.new(text: "Ya.Maps", url: "http://maps.yandex.ru/?text=#{coords}")],
        [Telegram::Bot::Types::InlineKeyboardButton.new(text: "I.Maps", url: "http://maps.apple.com/?q=#{coords}"),
        Telegram::Bot::Types::InlineKeyboardButton.new(text: "G.Navi", url: "https://www.google.com/maps?daddr=#{coords}")]
        ]
        @markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: inline_kb)
        send('inline_text', "#{el}")
      }
  	end
  end

  def zad_url
    @number = 1
  	if @json_engine["Level"]["Tasks"].to_s.match(/(http|https|ftp|ftps)\:\/\/[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,3}(\/\S*)(?=")/)
  		text = @json_engine["Level"]["Tasks"][0]["TaskText"].to_s
  		text = text.gsub(/^(?:(?!<(img|a href).*>).)*$\s?/, "")
  		if text.match(/img/) || text.match(/href/)
  			text = text.each_line { |el|
  				send('text', "[#{@number}]\n#{el[/(http|https|ftp|ftps)\:\/\/[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,3}(\/\S*)(?=")/]}")
          @number += 1
  			}
  		end
  	end
  end

  def helps
    if @json_engine["Event"].to_s == "0"
      if @json_engine["Level"]["Helps"] != []
        @json_engine["Level"]["Helps"].each_with_index.map {|el|
          if el["HelpText"] != nil
            help = "\u{1F4A1} #Подсказка_#{el["Number"].to_s} доступна\n>> Посмотреть - /see_clue_#{el["Number"].to_s}\n"
          else
            time = el["RemainSeconds"]
            time = seconds_to_hms(time)
            help = "\u{23F0} #Подсказка_#{el["Number"].to_s}\n>> Доступ через #{time.to_s}\n"
          end
        }.join('')
      else
        "В задании не предусмотрены подсказки"
      end
    end
  end

  def auto_helps
    if @json_engine["Event"].to_s == "0"
      if @json_engine["Level"]["Helps"] != []
        open_level_info_list
        @json_engine["Level"]["Helps"].each_with_index { |el|
          number = el["Number"].to_i - 1
          if el["RemainSeconds"] == 0
            if @level_list["all_clue"].to_a[number][1] == "1" || @level_list["all_clue"].to_a[number][1] == "0"
              #send('auto_text', "\u{1F4A1} #Подсказка_#{el["Number"]} доступна\n>> Посмотреть - /see_clue_#{el["Number"]}\n")
              @clue_number = el["Number"].to_i
              auto_see_clue
              auto_see_clue_url
              @level_list["all_clue"]["#{"helps_#{el["Number"]}"}"] = "2"
            end
          else el["HelpText"].nil?
            if el["RemainSeconds"].to_i < 60
              if @level_list["all_clue"].to_a[number][1] == "0"
                send('auto_text', "\u{203C} До подсказки №#{el["Number"]} меньше минуты \u{203C}")
                @level_list["all_clue"]["#{"helps_#{el["Number"]}"}"] = "1"
              end
            end
          end
          chek_level_info_list_whrite
        }
      end
    end
  end

  def auto_see_clue
    clue = @clue_number.to_i
    clue_number = clue.to_i - 1
    if @json_engine["Level"]["Helps"][clue_number]["HelpText"].to_s == ''
      send('auto_text', "У подсказки --#{@json_engine["Level"]["Helps"][clue_number].to_s}-- нет текста")
    else
      text = @json_engine["Level"]["Helps"][clue_number]["HelpText"].to_s
        .gsub(/<br\/>/, "\n")
        .gsub(/<(img|a href).*>/, "")
        .gsub(/<script>(.|\n)*?<\/script>/, "")
        .gsub(/<\/?[A-Za-z]+[^>]*>/, "")
      send('auto_text', "\u{1F4A1} #Подсказка_#{@json_engine["Level"]["Helps"][clue_number]["Number"].to_s}\n#{text}")
    end
  end

  def auto_see_clue_url
    @number = 1
    clue = @clue_number.to_i
    clue_number = clue.to_i - 1
    if @json_engine["Level"]["Helps"][clue_number]["HelpText"].to_s.match(/<img.*>/)
      text = @json_engine["Level"]["Helps"][clue_number]["HelpText"].to_s
      text = text.gsub(/^(?:(?!<(img|a href).*>).)*$\s?/, "")
      if text.match(/img/) || text.match(/href/)
        text = text.each_line { |el|
          send('auto_text', "[#{@number}]\n#{el[/(http|https|ftp|ftps)\:\/\/[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,3}(\/\S*)(?=")/]}")
          @number += 1
        }
      end
    end
  end

  def see_clue(message)
    clue = message.text.split('_')
    clue_number = clue[2].to_i - 1
    if @json_engine["Level"]["Helps"][clue_number]["HelpText"].to_s == ''
      send('text', "У подсказки --#{@json_engine["Level"]["Helps"][clue_number].to_s}-- нет текста")
    else
      text = @json_engine["Level"]["Helps"][clue_number]["HelpText"].to_s
        .gsub(/<br\/>/, "\n")
        .gsub(/<(img|a href).*>/, "")
        .gsub(/<script>(.|\n)*?<\/script>/, "")
        .gsub(/<\/?[A-Za-z]+[^>]*>/, "")
      send('text', "\u{1F4A1} #Подсказка_#{@json_engine["Level"]["Helps"][clue_number]["Number"].to_s}\n#{text}")
    end
  end

  def see_clue_url(message)
    @number = 1
    clue = message.text.split('_')
    clue_number = clue[2].to_i - 1
    if @json_engine["Level"]["Helps"][clue_number]["HelpText"].to_s.match(/<img.*>/)
      text = @json_engine["Level"]["Helps"][clue_number]["HelpText"].to_s
      text = text.gsub(/^(?:(?!<(img|a href).*>).)*$\s?/, "")
      if text.match(/img/) || text.match(/href/)
        text = text.each_line { |el|
          send('text', "[#{@number}]\n#{el[/(http|https|ftp|ftps)\:\/\/[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,3}(\/\S*)(?=")/]}")
          @number += 1
        }
      end
    end
  end

  def penalty_helps
    if @json_engine["Level"]["PenaltyHelps"] != []
      @json_engine["Level"]["PenaltyHelps"].each_with_index.map {|el|
        penalty = seconds_to_hms(el["Penalty"].to_i)
        if el["RemainSeconds"] == 0
          if el["PenaltyHelpState"] == 1
            help = "\u{2705} #Штрафная_подсказка_#{el["Number"].to_s} (#{penalty}) использована\n>> #{el["PenaltyComment"]}\n>> Посмотреть - /pen_clue_#{el["Number"].to_s}\n"
          else
            help = "\u{26A0} #Штрафная_подсказка_#{el["Number"].to_s} (#{penalty}) доступна\n>> #{el["PenaltyComment"]}\n>> Открыть - /open_clue_#{el["Number"].to_s}\n"
          end
        else
          time = el["RemainSeconds"]
          time = seconds_to_hms(time)
          help = "\u{23F0} #Штрафная_подсказка_#{el["Number"].to_s} (#{penalty})\n>> #{el["PenaltyComment"]}\n>> Будет доступна через #{time.to_s}\n"
        end
      }.join('')
    else
      "В задании нет штрафных подсказок"
    end
  end

  def see_penalty_clue(message)
    clue = message.text.split('_')
    clue_number = clue[2].to_i - 1
    if @json_engine["Level"]["PenaltyHelps"][clue_number]["HelpText"].to_s == ''
      send('text', "У подсказки --#{@json_engine["Level"]["PenaltyHelps"][clue_number].to_s}-- нет текста")
    else
      text = @json_engine["Level"]["PenaltyHelps"][clue_number]["HelpText"].to_s
        .gsub(/<br\/>/, "\n")
        .gsub(/<(img|a href).*>/, "")
        .gsub(/<script>(.|\n)*?<\/script>/, "")
        .gsub(/<\/?[A-Za-z]+[^>]*>/, "")
      send('text', "#Штрафная_подсказка_#{@json_engine["Level"]["PenaltyHelps"][clue_number]["Number"].to_s}\n#{text}")
    end
  end

  def open_penalty_clue(message)
    clue = message.text.split('_')
    clue_number = clue[2].to_i - 1
    clue_id = @json_engine["Level"]["PenaltyHelps"][clue_number]["HelpId"].to_s
    @penalty_help = "http://#{@domen}.en.cx/gameengines/encounter/play/#{@game}/?pid=#{clue_id}&pact=1"
    response = @agent.get(@penalty_help)
    whrite_engine_to_json
    if @json_engine["Level"]["PenaltyHelps"][clue_number]["HelpText"].to_s == ''
      send('text', "У подсказки --#{@json_engine["Level"]["PenaltyHelps"][clue_number].to_s}-- нет текста")
    else
      text = @json_engine["Level"]["PenaltyHelps"][clue_number]["HelpText"].to_s
        .gsub(/<font color.*?>/, "\n[выделено_цветом]\n")
        .gsub(/<\/font>/, "\n[выделено_цветом]\n")
        .gsub(/<br\/>/, "\n")
      send('text', "#Штрафная_подсказка_#{@json_engine["Level"]["PenaltyHelps"][clue_number]["Number"].to_s}\n#{text}")
    end
  end

  def see_bonus(message)
    bonus = message.text.split('_')
    bonus_number = bonus[2].to_i - 1
    if @json_engine["Level"]["Bonuses"][bonus_number]["Task"].to_s == ''
      send('text', "У бонуса --#{@json_engine["Level"]["Bonuses"][bonus_number]["Name"].to_s}-- нет загадки")
    else
      text = @json_engine["Level"]["Bonuses"][bonus_number]["Task"].to_s
        .gsub(/<br\/>/, "\n")
        .gsub(/<(img|a href).*>/, "")
        .gsub(/<script>(.|\n)*?<\/script>/, "")
        .gsub(/<\/?[A-Za-z]+[^>]*>/, "")
      send('text', text)
    end
  end

  def see_bonus_url(message)
    @number = 1
    bonus = message.text.split('_')
    bonus_number = bonus[2].to_i - 1
    text = @json_engine["Level"]["Bonuses"][bonus_number]["Task"].to_s
    text = text.gsub(/^(?:(?!<(img|a href).*>).)*$\s?/, "")
    if text.match(/img/) || text.match(/href/)
      text = text.each_line { |el|
        send('text', "[#{@number}]\n#{el[/(http|https|ftp|ftps)\:\/\/[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,3}(\/\S*)/]}")
        @number += 1
      }
    end
  end

  def sum_penalty
    if @json_engine["Level"]["PenaltyHelps"].nil?
      return "N/A"
    else
      @json_engine["Level"]["PenaltyHelps"].to_a.length
    end
  end

  def sum_helps
    if @json_engine["Level"]["Helps"].nil?
      return "N/A"
    else
      @json_engine["Level"]["Helps"].to_a.length
    end
  end


  def admin_message
    if @json_engine["Event"].to_s == "0"
      if @json_engine["Level"]["Messages"] != ''
  		text = @json_engine["Level"]["Messages"].each_with_index.map {|el|
  			admin = el["OwnerLogin"].to_s
  			a_text = el["MessageText"].to_s
  			message = "\u{203C} Сообщение от организатора - #{admin}\u{203C}\n#{a_text}"
  		}.join
      end
  	end
  end

  def level_number
    @now_level = 1
    @json_engine["Levels"].each_with_index { |el|
      if el["IsPassed"].to_s == "true"
        @now_level += 1
      end
    }
    @now_level.to_s
  end

  def sum_level_number
    if @json_engine["Levels"].nil?
      return "N/A"
    else
      @json_engine["Levels"].to_a.length
    end
  end

  def level_name
    if @json_engine["Level"]["Name"].nil?
      return "N/A"
    else
      @json_engine["Level"]["Name"] 
    end
  end

  def ko_sector
    if @check_number == true
      @json_engine["Level"]["Sectors"].map { |el|
        if el["Answer"] != nil
        	if el["Answer"]["Login"].to_s == @login.to_s
        		open_level_info_list
        		number = el["Order"].to_i - 1
        		"#{el["Order"]}) \u{2705} #{el["Name"]} (#{el["Answer"]["Answer"]}, #{@level_list["all_sectors"].to_a[number][1]})\n"
        	else
          	"#{el["Order"]}) \u{2705} #{el["Name"]} (#{el["Answer"]["Answer"]}, #{el["Answer"]["Login"]})\n"
          end
        else
          "#{el["Order"]}) \u{1F526} #{el["Name"]}\n"
        end
      }.join('') + "\nНе показывать взятые - /taked_off"
    else
      @json_engine["Level"]["Sectors"].map { |el|
        if el["Answer"] == nil
          "#{el["Order"]}) \u{1F526} #{el["Name"]}\n"
        end
      }.join('') + "\nПоказывать взятые - /taked_on"
    end
    
  end

  def ko_bonus
    if @check_number == true
      @json_engine["Level"]["Bonuses"].map { |el|
        if el["Answer"] != nil
          "#{el["Number"]}) \u{2705} #{el["Name"]} (#{el["Answer"]["Answer"]}, #{el["Answer"]["Login"]})\n"
        else
          "#{el["Number"]}) \u{1F526} #{el["Name"]} (/see_bonus_#{el["Number"]})\n"
        end
      }.join('') + "\nНе показывать взятые - /taked_off"
    else
      @json_engine["Level"]["Bonuses"].map { |el|
        if el["Answer"] == nil
          "#{el["Number"]}) \u{1F526} #{el["Name"]} (/see_bonus_#{el["Number"]})\n"
        end
      }.join('') + "\nПоказывать взятые - /taked_on"
    end
  end

  def old_arr # текущее состояние кодов до пробития кода
    text = @json_engine["Level"]["Sectors"]
  end

  def new_arr # текущее состояние кодов после пробития кода
    text = @json_engine["Level"]["Sectors"]
  end

  def check_accepted_kod # проверяет какой код взят
    if @old_arr == @new_arr
      return "Бонусный код"
    else
      @old_arr.each_with_index {|item, index| return (index + 1).to_s if @new_arr[index] != @old_arr[index] }
    end
  end

  def chek_auto_timeleft
    if @json_engine["Level"] != ''
      if @json_engine["Event"].to_s == "0"
        @time = @json_engine["Level"]["TimeoutSecondsRemain"]
        if @time < 65
          if @timeleft_1_min == 0
            send('auto_text', "\u{203C} До слива осталась 1 минута \u{203C}")
            @timeleft_1_min = 1
          end
        elsif @time < 600
          if @timeleft_10_min == 0
            send('auto_text', "\u{203C} До слива осталось 10 минут \u{203C}")
            @timeleft_10_min = 1
          end
        end
      end
    end
  end
end
