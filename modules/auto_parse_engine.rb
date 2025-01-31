#encoding: UTF-8
module Auto_parse_engine

	def auto_parse
    @old_chek_admin_message = @new_chek_admin_message = "text"
    @new_level = @old_level = "text"
    @stop_game = 0
		
    loop do
      if @parse_status == true
      	if @game_status == true
	    			begin
	            whrite_engine_to_json
	            open_json_engine

	            if @json_engine["Event"].to_s == "0"

		            if level_number.to_s != ''
		    					@new_level = level_number.to_s
		    				end

		    				if admin_message != ''
		              @new_chek_admin_message = admin_message.to_s
		            end

	            	if admin_message != ''
		              if @old_chek_admin_message.to_s != @new_chek_admin_message.to_s
		                send('auto_text', admin_message)
		                @old_chek_admin_message = admin_message.to_s
		              end
		            end

		            if @json_engine["Level"]["Sectors"] != ''
		            	open_json_engine_old
		            	@json_engine["Level"]["Sectors"].each_with_index {|item, index| 
		            		if item["Answer"] != nil
		            			if item != @json_engine_old["Level"]["Sectors"][index]
		            				send('auto_text', "\u{2705} Код №#{item["Order"]} --#{item["Answer"]["Answer"]}--\n\u{1F612}Вбил(а) #{item["Answer"]["Login"]} в движок" + "\n" + "Осталось - #{sectors_left}" + "\n" + "До слива - " + time_left)
		            			end
		            		end
		            	}
		            end

		            if @json_engine["Level"]["Bonuses"] != ''
		            	open_json_engine_old
	            		@json_engine["Level"]["Bonuses"].each_with_index {|item, index| 
	            			if item["Answer"] != nil
	            				if item != @json_engine_old["Level"]["Bonuses"][index]
	            					if item["Help"] == nil
	            						send('auto_text', "\u{2705} Бонус №#{item["Number"]} --#{item["Answer"]["Answer"]}--\n\u{1F612}Вбил(а) #{item["Answer"]["Login"]} в движок\n\u{1F4A1}Под бонусом текста нет" + "\n" + "Осталось - #{sectors_left}" + "\n" + "До слива - " + time_left)
	            					else
	            						send('auto_text', "\u{2705} Бонус №#{item["Number"]} --#{item["Answer"]["Answer"]}--\n\u{1F612}Вбил(а) #{item["Answer"]["Login"]} в движок\n\u{1F4A1}#{item["Help"]}" + "\n" + "Осталось - #{sectors_left}" + "\n" + "До слива - " + time_left)
	            					end
	            				end
	            			end
	            		}
		            end

		            @json_engine_old = @json_engine
		            whrite_engine_old_to_json

				   			if @new_level.to_s != @old_level.to_s
				   				@waitcode = []

		              send('auto_text', "Уровень #{level_number} из #{sum_level_number} #{level_name}\n"\
		                "\u{2705} Кодов взято - #{sectors_taken}/#{sectors_need} (/ko)\n"\
		                "\u{1F526} Кодов всего - #{sectors_not_do}\n"\
		                "\u{23F0} Подсказок - #{sum_helps} (/clue)\n"\
		                "\u{26A0} Штр. подск - #{sum_penalty} (/penalty)\n"\
		                "\u{1F537} Бонусов - #{bonuses_taked}/#{bonuses_not_do} (/bon)\n"\
		                "\u{1F3C1} До слива - #{time_left} (/timeleft)".freeze)
		              
		              zad_coord

	              	send('auto_text', "#{zad}")

		              zad_url

						      if @json_engine["Level"]["Helps"] != "[]"
	              		send('auto_text', "#{helps}")
	              	end

		              if zad.to_s.match(/ ложны/i)
		                @kod_status = false
		                send('auto_text', "\u{203C} На уровне ложные коды, ввод кодов отключен! \u{203C}")
		              else
		                @kod_status = true
		              end

					        @old_level = level_number.to_s

		              @timeleft_10_min = 0
		              @timeleft_1_min = 0

		              chek_clue_list
		              chek_sector_list
		              chek_bonuses_list
					      end

		            chek_auto_timeleft

					      if @json_engine["Level"]["Helps"] != "[]"
					      	auto_helps
	            	end
	            else @json_engine["Event"].to_s == "17"
	            	if @stop_game == 0
	            		send('auto_text', "Игра закончена, всем спасибо!")
	            		@stop_game = 1
	            	end
		          end

					  sleep 3

	        	rescue => exception
	          	send('error_text', "#{exception.to_s} - блок автопостинга")
	          	if exception.to_s.include?("as robot's requests")
	            	auth_resp = @agent.post("http://#{@domen}.en.cx/Login.aspx?return=/login/signin?json=1&Login=#{@login}&Password=#{@password}")
	           		process_auth(auth_resp)
	            	send('auto_text', "Отправь еще раз!")
	          	end
	          	sleep 1
	          end
	      end
	    else
	      sleep 3
	    end
    end
  end

end
