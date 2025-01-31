#encoding: UTF-8

class Encounter
  include BotApi
  include Logs
  include Authorization
  include Game_settings
  include Query_to_engine
  include Auto_parse_engine
  include Players_stat
  include Google_logs

  def initialize
    @kod_status = true
    @check_number = false
    @parse_status = true
    @game_status = false
    @auth_status = false
    @agent = Mechanize.new
  end

  def turn_on
    Telegram::Bot::Client.run(TOKEN) do |bot|
      begin
        send('error_text', "Я ребутнулся!")
        bot.listen do |message|
          Thread.start(message) do |message|
            @chat_id = message.chat.id.to_s
            @reply_id = message.message_id.to_i
            @name = message.from.username.to_s
            check_chat(@chat_id) #для сбора статистики игроков в чатике
            case message.text
              when %r{^/stop_game}
                send('html', 'Отключение от игры, сброс сессии произведен')
                @parse_status = false
                return
            end
            process_messages(message)
            process_auth_messages(message) if @game_status
            write_to_logs(message)
          end
        end
      rescue => exception
        send('error_text', "#{exception.to_s} - блок старта бота")
      end
    end
  end

#----------------------------------------------------команды бота в любой момент времени------------------------------------------------------------------

  def process_messages(message)
    begin
    	#chat_access
    	chat_list(message)

    	if @access_enable == true
	      case message.text

	      when %r{^/help}
	        send('text', DOZOR_HELP)

	      when %r{^/auth}
	        @auth_data = message.text.split(' ')
	        unless (@auth_data[4])
	          send('text', 'Для запуска бота введите последовательно через пробел в одну строку следующие данные:
	          1) Игровой логин бота;
	          2) Пароль к игровому логину бота;
	          3) Домен;
	          4) Номер игры;
	          P.S. Для сохранности учетных данных авторизацию рекомендуется проводить с ботом в личке')
	        else
	          authorization(message)
	          send('error_text', "#{message.from.username} (#{message.from.id}) проводит авторизацию")
	        end

	      when %r{^/(kon|kod_on)}
	        @kod_status = true
	        send('html', 'Прием кодов активирован')
	        send('auto_text', "Игроком #{message.from.username} активирован прием кодов")

	      when %r{^/(koff|kod_off)}
	        @kod_status = false
	        send('html', 'Прием кодов отключен')
	        send('auto_text', "Игроком #{message.from.username} отключен прием кодов")

	      when %r{^/taked_on}
	        @check_number = true
	        send('html', 'Отображение взятых кодов активировано')

	      when %r{^/taked_off}
	        @check_number = false
	        send('html', 'Отображение взятых кодов отключено')

	      when /\d+\.\d+(\,\s+|\s+|\,)\d+\.\d+/
	        message_cord(message)

	      when %r{^/id}
	        send('html', "Твой ник в телеграме - #{message.from.username}\n"\
	          "Твой ID в телеграме - #{message.from.id}\n"\
	          "ID этого чата - #{message.chat.id}")

	      when %r{^/parse_off}
	        @parse_status = false
	        send('html', "Автопарсинг отключен")

	      when %r{^/parse_on}
	        @parse_status = true
	        send('html', "Автопарсинг включен")

	      when %r{^/all_status}
	          send('text', "1) #{chek_auth_status}\n"\
	          "2) #{chek_page_status}\n"\
	          "3) #{chek_check_number}\n"\
	          "4) #{chek_parse_status}\n"\
	          "5) #{chek_parse_dr_status}\n"\
	          "6) ID чата куда отправляется информация - #{@auto_chat_id}\n"\
	          "7) ID этого чата - #{message.chat.id}")

	      when %r{^/location}
	        send('cord', "12.34567890, 12.34567890") #место сбора перед началом игры

	      #отображение текущей статистики взятия кодов на текущей игре 
	      when %r{^/stat}
	        show_players

	      when %r{^/wk}
	        send('text', "Список отправленных кодов с уровня №#{@new_level}:\n#{@waitcode.each_with_index.map {|el, index| "#{index + 1}) #{el}\n"}.join}")
	        send('text', "Список принятых кодов с уровня №#{@new_level}:\n#{@json_engine["Level"]["Sectors"].map { |el|
	        	if el["Answer"] != nil
	        		"#{el["Order"]}) \u{2705} #{el["Name"]} (#{el["Answer"]["Answer"]}, #{el["Answer"]["Login"]})\n"
	        	end
      		}.join('')}")
	      end
	    else
	     	send('error_text', "@chat_id -> #{@chat_id}\n@name -> #{@name}")
	    end
	    #write_to_logs(message)
      
    rescue => exception
      send('error_text', "#{exception.to_s} - блок команда до авторизации")
    end
  end

#----------------------------------------------------КОМАНДЫ БОТА ТОЛЬКО ПОСЛЕ УСПЕШНОЙ АВТОРИЗАЦИИ------------------------------------------------------------------------
  def process_auth_messages(message)
    begin
    	chat_list(message)

    	if @access_enable == true
	    	open_json_engine
	      case message.text
	      when /(^(\.|\?|#))|(^[DdRrДдРр\d]{3})/
	      	sleep 0.1
	      	if check_send_code_access == true and @kod_status == true
	        	sendCode(message.text, message)
	        end
   			
	      when %r{^/zad}
          send('auto_text', "Уровень #{level_number} из #{sum_level_number} #{level_name}\n"\
            "\u{2705} Кодов взято - #{sectors_taken}/#{sectors_need} (/ko)\n"\
            "\u{1F526} Кодов всего - #{sectors_not_do}\n"\
            "\u{23F0} Подсказок - #{sum_helps} (/clue)\n"\
            "\u{26A0} Штр. подск - #{sum_penalty} (/penalty)\n"\
            "\u{1F537} Бонусов - #{bonuses_taked}/#{bonuses_not_do} (/bon)\n"\
            "\u{1F3C1} До слива - #{time_left} (/timeleft)".freeze)
	        send('text', zad)
	        zad_url

	      when %r{^/url}
	        zad_url

	      when %r{^/test}
	        change_sector_list(message)

	      when %r{^/clue}
	        send('text', "#{helps}\n\u{1F3C1} До слива - #{time_left}")

	      when %r{^/coord}
	        zad_coord

	      when %r{^/timeleft}
	        send('text', "\u{1F3C1} До слива - #{time_left}")

	      when %r{^/ko}
	      	send('text', "\u{2705} Кодов взято - #{sectors_taken}/#{sectors_need}\n\u{1F526} Кодов всего - #{sectors_not_do}")
	      	send('text', ko_sector)

	      when %r{^/bon}
	      	send('text', ko_bonus)

	      when %r{^/penalty}
	      	send('text', "\u{203C} ВНИМАНИЕ!!! подтверждения нет, при нажатии кнопки подсказка сразу откроется \u{203C}")
	      	send('text', penalty_helps)

	      when %r{^/pen_clue_\d+}
	      	see_penalty_clue(message)

	      when %r{^/open_clue_\d+}
	      	open_penalty_clue(message)

	      when %r{^/see_bonus_\d+}
	      	see_bonus(message)
	      	see_bonus_url(message)

	      when %r{^/see_clue_\d+}
	      	see_clue(message)
	      	see_clue_url(message)

	      end
	    	whrite_engine_to_json
	    else
	     	send('error_text', "@chat_id -> #{@chat_id}\n@name -> #{@name}")
	    end

    rescue => exception
    	send('error_text', "#{exception.to_s} - блок команд после авторизации")
    	if exception.to_s.include?('запросы робота')
    		@agent = Mechanize.new
	  		auth_resp = @agent.post(@ddos_link)
	    	@agent.cookie_jar.save("cookies.yaml")
	    	@agent.cookie_jar.load("cookies.yaml")
	    	send('auto_text', "Выполните последнюю команду еще раз")
	    	sleep 1
     	end
    end
  end
#----------------------------------------------------ОТВЕТЫ НА КОМАНДЫ БОТА БЕЗ ДВИЖКА (АВТОРИЗАЦИИ)--------------------------------------------------

  def message_cord(message)
    text = message.text.gsub(/^(?:(?!\d+\.\d+(\,\s+|\s+|\,)\d+\.\d+).)*$\s?/, '')
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

  def chat_list(message)
    if @auto_chat_id != @chat_id
	  	check_user = "https://api.telegram.org/bot#{TOKEN}/getChatMember?chat_id=#{@auto_chat_id}&user_id=#{@chat_id}"
	    answer = @agent.get(check_user)
	    result = answer.body.to_s
    	status = ["creator", "administrator", "member", "restricted"].each_with_index { |el| 
    	if result.to_s.include?(el)
    		@access_enable = true
    	end
    	}
    else
    	@access_enable = true
    end
  end
end
