#encoding: UTF-8
require 'json'
require 'nokogiri'
require 'mechanize'
require 'telegram/bot'
require 'net/http'
require 'httparty'
require 'similar_text'
# require 'google_drive'

#load 'initializers/telegram.rb'

load 'modules/bot_api.rb'
load 'modules/logs_list.rb'
load 'modules/auth.rb'
load 'modules/game_settings.rb'
load 'modules/query_to_engine.rb'
load 'modules/auto_parse_engine.rb'
load 'modules/players_stat.rb'
load 'modules/google_logs.rb'
load 'bot_modes_classes/enc.rb'

bot = Encounter.new
bot.turn_on
