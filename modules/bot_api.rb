#encoding: UTF-8
module BotApi
    
  TOKEN = 'token'.freeze
  DOZOR_HELP = "Список команд:\n\n"\
    "Ввод кодов:\n"\
    "1) Бот принимает циферные коды как есть (345925)\n"\
    "2) Бот принимает все через точку (.такойкод)\n"\
    "Прием кодов визуализирован: \u{2705} - код принят, \u{26D4} - не принят\n\n"\
    "/all_status - общий статус настроек\n"\
    "/ko - Остатки кодов\n"\
    "/bon - Остатки бонусов\n"\
    "/zad - Текст задания\n"\
    "/coord - Координаты из задания, если есть\n"\
    "/url - Все ссылки из задания\n"\
    "/clue - Информация по подсказкам\n"\
    "/penalty - Информация по штрафным подсказкам\n"\
    "/timeleft - Оставшееся время до слива\n"\
    "/kod_on (/kon) - активация ввода кодов\n"\
    "/kod_off (/koff) - отключение ввода кодов\n"\
    "/taked_on - включает в выдачу /ko отображение взятых кодов\n"\
    "/taked_off - исключает в выдаче /ko отображение взятых кодов\n"\
    "/parse_on - активация парсинга движка\n"\
    "/parse_off - отключение парсинга движка\n".freeze

 def send(mode, text, html = 'code')
    @auto_chat_id = "-1234567890" #сюда писать ID чата куда будет автоматически отсылаться информация
    Telegram::Bot::Client.run(TOKEN) do |bot|
      case mode
      when 'text'
        bot.api.send_message(
          chat_id: @chat_id,
          reply_to_message_id: @reply_id,
          text: text
        )

      when 'inline_text'
        bot.api.send_message(
          chat_id: @chat_id,
          text: text,
          reply_markup: @markup,
          reply_to_message_id: @reply_id
        )

      #модуль для автопостинга инфы в игровой чатик 
      when 'auto_text'
        bot.api.send_message(
          chat_id: @auto_chat_id,
          text: text
        )

      when 'error_text'
        bot.api.send_message(
          chat_id: 1234567890,
          text: text
        )

      when 'wait_code'
        bot.api.send_message(
          chat_id: @wait_code_chats,
          text: text
        )

      when 'image'
        bot.api.send_sticker(
          chat_id: @chat_id,
          reply_to_message_id: @reply_id,
          sticker: Faraday::UploadIO.new(text, 'image/png')
        )

      when 'cord'
        text = text.split(/\s|,\s/)
        bot.api.send_location(
          chat_id: @chat_id,
          reply_to_message_id: @reply_id,
          latitude: text[0].to_f,
          longitude: text[1].to_f
        )

      when 'files'
        bot.api.send_document(
          chat_id: @chat_id,
          document: Faraday::UploadIO.new(text, 'image/png')
        )

      when 'html'
        bot.api.send_message(
          chat_id: @chat_id,
          reply_to_message_id: @reply_id,
          text: "<#{html}>" + text + "</#{html}>",
          parse_mode: 'HTML'
        )

      when 'chat_members'
        bot.api.get_chat(
          chat_id: @auto_chat_id
        )

      end
      break
    end
  end

  def get_page(link)
    page = @agent.get(link)
    page = Nokogiri::HTML(page.body)
    page.encoding = 'utf-8'
    page
  end
end

