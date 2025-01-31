#encoding: UTF-8

module Google_logs
	#------------------------------------------------------ЛОГИРОВАНИЕ СВЕДЕНИЙ В ГУГЛ ТАБЛИЦЫ-----------------------------------------------------------

	KEY_FILE = 'google_sheet_secrets.json'
	FILE_URL = 'https://docs.google.com/some_your_url'

	def google_docs_sacces
		@session ||= GoogleDrive::Session.from_service_account_key(KEY_FILE)
		@spreadsheet ||= @session.spreadsheet_by_url(FILE_URL)
		@worksheet ||= @spreadsheet.worksheets.first
		@worksheet.insert_rows(@worksheet.num_rows + 1, [["#{time_log}", "#{@name}", "#{@new_level}", "#{@type_kod}", "#{@type_kod == "Основной" ? check_accepted_kod : @bonus_number}", "#{@text}", "#{@type_kod == "Основной" ? @osn_name : @bonus_name}", "#{@bonus_text}", "#{@type_kod == "Основной" ? @time = "" : @time}"]])
		@worksheet.save
	end





end