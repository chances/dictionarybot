# DictionaryBot
########################################################
# Written by Chance Snow - enigma <chances@cat.pdx.edu>
# Licensed under the MIT License
# See LICENSE file for more info
########################################################

require 'yaml'
require 'cinch'
#require 'cinch/plugins/identify'
require 'date'
require 'wordnik'

@debug = false
if ARGV.length > 0
  if ARGV.include?('--debug')
    @debug = true
    puts 'DEBUG MODE'
  end
end

dictionarybot = Cinch::Bot.new do
  configure do |c|
    #Load configuration
    exit unless File.exists?(File.expand_path('~/.bots/dictionarybot.yml'))
    config = YAML::load_file(File.expand_path('~/.bots/dictionarybot.yml'))
    
    exit unless config.has_key?('channels') or config['channels'].length == 0
    
    Wordnik.configure do |wordnik_config|
      wordnik_config.api_key = config['wordnik_api_key']
    end
    #Configure bot
    c.server = 'iss.cat.pdx.edu'
    c.port = 6697
    c.ssl.use = true
    c.nick = 'dictionarybot'
    c.realname = 'Enigma\'s DictionaryBot'
    if ARGV.include?('--debug')
      c.channels = config['debug']['channels']
    else
      c.channels = config['channels']
    end
    c.messages_per_second = 20
    #c.plugins.plugins = [Cinch::Plugins::Identify]
    #c.plugins.options[Cinch::Plugins::Identify] = {
    #  :password => 'dictionarybotiscool',
    #  :type => :nickserv
    #}
  end
  
  helpers do
    @help = 'See https://github.com/chances/dictionarybot#usage'
    
    # Abbreviate a given part of speech
    # 
    def pos(part_of_speech)
      case part_of_speech
      when 'noun'
        'n'
      when 'adjective'
        'adj'
      when 'verb'
        'v'
      when 'adverb'
        'adv'
      when 'interjection'
        'interj'
      when 'pronoun'
        'pron'
      when 'preposition'
        'prep'
      when 'abbreviation'
        'abbr'
      when 'auxiliary-verb'
        'aux v'
      when 'conjunction'
        'conj'
      when 'definite-article'
        'definite article'
      when 'family-name'
        'fam'
      when 'idiom'
        'idiom'
      when 'imperative'
        'imper'
      when 'noun-plural'
        'n pl'
      when 'noun-posessive'
        'n posessive'
      when 'past-participle'
        'past part'
      when 'phrasal-prefix'
        'phrasal prefix'
      when 'proper-noun'
        'proper n'
      when 'proper-noun-plural'
        'proper n pl'
      when 'proper-noun-posessive'
        'proper n posessive'
      when 'verb-intransitive'
        'vi'
      when 'verb-transitive'
        'vt'
      else
        part_of_speech.nil? ? nil : part_of_speech.gsub('-',' ')
      end
    end
    
    def define(word, result_limit=3)
      result_limit = result_limit < 0 ? 3 : result_limit > 8 ? 8 : result_limit
      results = Wordnik.word.get_definitions(word, :use_canonical => true, :limit => result_limit)
      if not results.is_a?(String) and results.length > 0
        info "Defining #{word} with #{result_limit} definitions"
        response = ''
        attrib = ''
        count = 1
        for definition in results
          pos_abbr = pos(definition['partOfSpeech'])
          if not pos_abbr.nil?
            response += "#{count}: (#{pos(definition['partOfSpeech'])}) #{definition['text']}\n"
          else
            response += "#{count}: #{definition['text']}\n"
          end
          attrib = definition['attributionText']
          count += 1
        end
        response += attrib
      else
        info "ERROR: Failed to retrieve definitions for #{word}"
        nil
      end
    end

    def wotd(date=nil)
      #TODO: Be smarter about this and cache the result for the day.
      result = nil
      if date.nil?
        result = Wordnik.words.get_word_of_the_day
        date = DateTime.now
      else
        result = Wordnik.words.get_word_of_the_day(:date => date)
        date = Date.parse(date).to_datetime
      end
      if not result.nil? and not result.is_a?(String) and result['id'].is_a?(Integer)
        info 'Giving word of the day'
        #publish_date = DateTime.parse(result['publishDate'])
        response = "Word of the day for #{date.strftime('%a, %b %d, %Y')}: \u0002#{result['word']}\u0002\n"
        for definition in result['definitions']
          pos_abbr = pos(definition['partOfSpeech'])
          if not pos_abbr.nil?
            response += "(#{pos(definition['partOfSpeech'])}) #{definition['text']}\n"
          else
            response += "#{definition['text']}\n"
          end
        end
        response += "Entymology: #{result['note']}"
      else
        info 'ERROR: Failed to retrieve word of the day'
      end
    end
  end
  
  on :connect do |m|
    info '------------------------------------------------'
    for channel in m.bot.config.channels
      info "Joining #{channel.split(' ')[0]}"
    end
    info '------------------------------------------------'
  end
  
  on :channel, /^!help dictionarybot$/ do |m|
    m.reply(@help)
  end
  on :channel, /^!dictionary (\w+)\s*(.*)/ do |m, command, args|
    from = m.user.nick
    case command
    when /help/
      m.reply(@help)
    when /(define)/
      args = args.strip.split(' ')
      if args.length > 0
        word = args[0]
        results = 3
        if args.length > 1
          begin
            number = Integer(args[1])
            results = number
          rescue
            m.reply 'Usage: !dictionary define <word> [results=3]'
          end
        end
        response = define(word, results)
        if response.nil?
          m.reply "No definitions found for #{word}"
        else
          for line in response.split('\n')
            m.reply line
          end
        end
      else
        m.reply 'Usage: !dictionary define <word> [results=3]'
      end
    when /leave/
      if from == 'enigma'
        info "Leaving #{m.channel}"
        m.bot.part(m.channel)
      end
    when /quit/
      if from == 'enigma'
        info 'Quitting IRC'
        m.bot.quit('Quitting at the request of my master')
      end
    end
  end
  on :channel, /^define: (\w+)\b/ do |m, word|
    response = define(word)
    if response.nil?
      m.reply "No definitions found for #{word}"
    else
      for line in response.split('\n')
        m.reply line
      end
    end
  end
  on :channel, /^!wordoftheday\s?(yesterday|today|tomorrow|\d{4}-\d{2}-\d{2})?\b/ do |m, arg|
    response = nil
    if not arg.nil? and arg.include?('-')
      response = wotd(arg)
    elsif not arg.nil? and arg.include?('yesterday')
      response = wotd(Date.today.prev_day.strftime('%Y-%m-%d'))
    elsif not arg.nil? and arg.include?('tomorrow')
      response = wotd(Date.today.next_day.strftime('%Y-%m-%d'))
    else
      response = wotd()
    end
    unless response.nil?
      for line in response.split('\n')
        m.reply line
      end
    end
  end
  on :channel, /^!wotd\b/ do |m|
    response = wotd()
    unless response.nil?
      for line in response.split('\n')
        m.reply line
      end
    end
  end
end

#Set log file
log_file = File.open(File.expand_path('~/.bots/dictionarybot.log'), 'a')
log_file.sync = true
dictionarybot.loggers << Cinch::Logger.new(log_file)
dictionarybot.loggers.level = :info
dictionarybot.loggers.first.level  = :info

log_file.puts '================================================'
log_file.puts DateTime.now.strftime('%a, %b %d, %Y - %I:%M:%S %p')
log_file.puts '------------------------------------------------'

if @debug
  log_file.puts 'DEBUG MODE'
  log_file.puts '------------------------------------------------'
end

dictionarybot.start
