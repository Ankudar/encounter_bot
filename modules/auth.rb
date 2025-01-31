#encoding: UTF-8
module Authorization
#------------------------------------------------------АВТОРИЗАЦИЯ-----------------------------------------------------------
  def authorization(message)
    begin
      @login = @auth_data[1]
      @password = @auth_data[2]
      @domen = @auth_data[3]
      @game = @auth_data[4]
      @auth_link = "http://#{@domen}.en.cx/login/signin?json=1&Login=#{@login}&Password=#{@password}"
      @engine_link = "https://#{@domen}.en.cx/GameEngines/Encounter/Play/#{@game}?json=1&"
      @ddos_link = "http://#{@domen}.en.cx/Login.aspx?return=/login/signin?json=1&Login=#{@login}&Password=#{@password}"
      @game_title_link = "http://#{@domen}.en.cx/GameDetails.aspx?gid=#{@game}"
      auth_resp = @agent.post(@auth_link)
      @agent.cookie_jar.save("cookies.yaml")
      @agent.cookie_jar.load("cookies.yaml")
      process_auth(auth_resp)
      engine_answer
      write_to_logs(message)
      whrite_engine_to_json
    rescue => exception
      send('error_text', "#{exception.to_s} - блок авторизации")
      if exception.to_s.include?('запросы робота')
        @agent = Mechanize.new
        auth_resp = @agent.post(@ddos_link)
        @agent.cookie_jar.save("cookies.yaml")
        @agent.cookie_jar.load("cookies.yaml")
        sleep 1
      end
    end
  end

  def game_link
    response = @agent.get(@engine_link)
    response = JSON.parse(response.body)
  end

  def game_title_link
    response = @agent.get(@game_title_link)
    time = response.body.to_s
    if time.include?('TimerTexttime')
      time.split(/"TimerTexttime.*">/)[1].split('<')[0].force_encoding("UTF-8")
    else
      return 'Игра уже началась!'
    end
  end

  def check_engine
    game_link["Event"]
  end

  def engine_answer
    if check_engine == 0
      @game_status = true
      send('error_text', "Игра запущена и работает нормально")
    elsif check_engine == 2
      @game_status = false
      send('error_text', "Игра с указанным ID не существует")
    elsif check_engine == 3
      @game_status = false
      send('error_text', "Запрошенная игра не соответствует запрошенному Engine")
    elsif check_engine == 4
      @game_status = false
      send('error_text', "Игрок не залогинен на сайте")
    elsif check_engine == 5
      @game_status = false
      send('error_text', "Игра не началась")
    elsif check_engine == 6
      @game_status = false
      send('error_text', "Игра закончилась")
    elsif check_engine == 7
      @game_status = false
      send('error_text', "Не подана заявка (игроком)")
    elsif check_engine == 8
      @game_status = false
      send('error_text', "Не подана заявка (командой)")
    elsif check_engine == 9
      @game_status = false
      send('error_text', "Игрок еще не принят в игру")
    elsif check_engine == 10
      @game_status = false
      send('error_text', "У игрока нет команды (в командной игре)")
    elsif check_engine == 11
      @game_status = false
      send('error_text', "Игрок не активен в команде (в командной игре)")
    elsif check_engine == 12
      @game_status = false
      send('error_text', "В игре нет уровней")
    elsif check_engine == 13
      @game_status = false
      send('error_text', "Превышено количество участников в команде (в командной игре)")
    elsif check_engine == 16
      @game_status = true
      send('error_text', "Уровень снят")
    elsif check_engine == 17
      @game_status = false
      send('error_text', "Игра закончена")
    elsif check_engine == 18
      @game_status = true
      send('error_text', "Уровень снят")
    elsif check_engine == 19
      @game_status = true
      send('error_text', "Уровень пройден автопереходом")
    elsif check_engine == 20
      @game_status = true
      send('error_text', "Все сектора отгаданы")
    elsif check_engine == 21
      @game_status = true
      send('error_text', "Уровень снят")
    elsif check_engine == 22
      @game_status = true
      send('error_text', "Таймаут уровня")
    end

    @old_text_answer = check_engine

    if @game_status == true
      whrite_engine_to_json
      t1 = Thread.new{ auto_parse }
      t1.join
    else @game_status == false
      loop do
        sleep 10
        @new_text_answer = check_engine
        if @old_text_answer != @new_text_answer
          engine_answer
        end
        if @game_status == true
          break
        end
      end
    end
  end

  def process_auth(auth_resp)
    if auth_resp.body.include?('"Error":0')
      @auth_status = true
      send('error_text', "Авторизация прошла успешно")
    elsif auth_resp.body.include?('"Error":1')
      @auth_status = false
      send('error_text', "Превышено количество неправильных  попыток авторизации")
    elsif auth_resp.body.include?('"Error":2')
      @auth_status = false
      send('error_text', "Неправильный логин или пароль")
    elsif auth_resp.body.include?('"Error":3')
      @auth_status = false
      send('error_text', "Пользователь или в сибири, или в черном списке, или на домене нельзя авторизовываться с других доменов")
    elsif auth_resp.body.include?('"Error":4')
      @auth_status = false
      send('error_text', "У пользователя в профиле включена блокировака по IP, текущий IP не входит в список разрешенных")
    elsif auth_resp.body.include?('"Error":5')
      @auth_status = false
      send('error_text', "В процессе авторизации произошла ошибка на сервере")
    elsif auth_resp.body.include?('"Error":6')
      @auth_status = false
      send('error_text', "Не используется в JSON запросах")
    elsif auth_resp.body.include?('"Error":7')
      @auth_status = false
      send('error_text', "Пользователь заблокирован администратором")
    elsif auth_resp.body.include?('"Error":8')
      @auth_status = false
      send('error_text', "Новый пользователь не активирован")
    elsif auth_resp.body.include?('"Error":9')
      @auth_status = false
      send('error_text', "Действия пользователя расценены как брутфорс")
    elsif auth_resp.body.include?('"Error":10')
      @auth_status = false
      send('error_text', "Пользователь не подтвердил E-Mail")
    end
  end
end
