#encoding: UTF-8
module Game_settings
#------------------------------------------------------СБОР ТЕКУЩИХ НАСТРОЕК БОТА И ИГРЫ-----------------------------------------------------------

  def chek_auth_status 
    if @game != nil
      return "Бот авторизован в городе - #{@domen}, учетная запись - #{@login}"
    else
      return 'Авторизуйтесь для получения данных'
    end
  end

  def chek_page_status #доделать
    if @game_status == true
      return "Игра уже идет"
    else @game_status == false
      if @auth_status == true
        "До игры - #{@game_title_link}\n"\
        "#{game_title_link}".freeze
      else
        "Авторизуйтесь для получения данных"
      end
    end
  end

  def chek_parse_status
    if @kod_status == true
      return 'Прием кодов включен'
    else
      return 'Прием кодов ВЫКЛЮЧЕН'
    end
  end

  def chek_check_number
    if @check_number == true
      return 'В остатках будут и взятые коды'
    else
      return 'В остатках будут только НЕ взятые коды'
    end
  end

  def chek_parse_dr_status
    if @parse_status == true
      return 'Автопарсинг включен'
    else
      return 'Автопарсинг выключен'
    end
  end

end