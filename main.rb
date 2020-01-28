require 'rubygems'
require 'bundler'
require 'bundler/setup'

require 'rainbow'
require "rainbow/ext/string"
require 'rainbow/refinement'
using Rainbow

require 'active_record'
Bundler.require(:default)
# ActiveRecord::Base.establish_connection(
#   :adapter => "sqlite3",
#   :database  => "longman_audio.sqlite3"
# )
# "content"	TEXT,
# "audio"	TEXT,
# "collins"	TEXT,
# "explanation"	TEXT
class Audio < ActiveRecord::Base
  establish_connection(
  :adapter => "sqlite3",
  :database  => "longman_audio.sqlite3"
  )

  def rainbow_explanation
    temp = self.explanation.clone
    /\[c\s?(.*?)\](.*?)\[\/c\]/
    temp = temp.gsub(/\[c\s?(.*?)\](.*?)\[\/c\]/) do |str|
      # $1, $2, $`, $&, and $'
      # puts $1, $2, $`, $&, $'
      color = $1.strip.to_sym
      color = :green if color.empty?
      $2.color(color)
    end
    # puts temp
    temp = temp.gsub(/{{Roman}}(.*?){{\/Roman}}/, '\1'.white)

    temp = temp.gsub(/\[b\s?\](.*?)\[\/b\]/, '\1'.bright.white)
    temp = temp.gsub(/\[p\s?\](.*?)\[\/p\]/, '\1'.green)
    temp = temp.gsub(/\[u\s?\](.*?)\[\/u\]/, '\1'.underline)
    temp = temp.gsub(/\[i\s?\](.*?)\[\/i\]/, '\1'.italic)
    temp = temp.gsub(/\[sup\s?\](.*?)\[\/sup\]/, ' ' +'\1'.inverse)
    temp = temp.gsub(/\[\/m\]/, '')
    # temp = temp.gsub(/\[s\s?\](.*?)\[\/s\]/, 'https://memorysheep.com/longmandsl/\1'.underline)
    temp = temp.gsub(/\[s\s?\](.*?)\[\/s\]/, '')
     

    temp
  end
end

# "content"	TEXT,
# "audio"	TEXT,
# "error_size"	TEXT,
# "created_at"	timestamp,
# "updated_at"	timestamp,

class DictationLog < ActiveRecord::Base
  establish_connection(
    :adapter => "sqlite3",
    :database  => "user.sqlite3"
    )
end
class Word < ActiveRecord::Base
  establish_connection(
    :adapter => "sqlite3",
    :database  => "shanbay.db"
    )
  def zh
    # {"en_definitions":{"s":["pleasantly (even unrealistically) optimistic"],"n":["a contented state of being happy and healthy and prosperous","an unaccented beat (especially the last beat of a measure)"]},"uk_audio":"http://media.shanbay.com/audio/uk/upbeat.mp3","conent_id":17076,"cn_definition":{"pos":"","defn":"n. 上升, [音]弱音拍\nadj. 乐观的"},"num_sense":1,"content_type":"vocabulary","id":17076,"definition":" n. 上升, [音]弱音拍\nadj. 乐观的","content_id":17076,"en_definition":{"pos":"s","defn":"pleasantly (even unrealistically) optimistic"},"object_id":17076,"content":"upbeat","pron":"'ʌpbi:t","pronunciation":"'ʌpbi:t","audio":"http://media.shanbay.com/audio/us/upbeat.mp3","us_audio":"http://media.shanbay.com/audio/us/upbeat.mp3"}
    shanbay = JSON.parse self.json
    shanbay["definition"]
  end
end

puts "共 #{Audio.count} 个单词音频"
puts "共 #{Word.count} 个扇贝单词解释"
puts "共 #{DictationLog.count} 条日志记录"

# result = ActiveRecord::Base.connection.execute('select content, collins, count(*) as count from audios where collins=3 GROUP BY content ORDER BY count(*) asc;')
# collins3 = result.map{|r| r["content"]}

# puts collins3

puts '听写开始......'.color(:red)
# puts Rainbow("this is red").red + " and " + Rainbow("this on yellow bg").bg(:yellow) + " and " + Rainbow("even bright underlined!").underline.bright

# words = File.read('words.txt').lines.map(&:strip)
# words.shuffle!
# puts "单词个数：#{words.size}".cyan 
# puts words.sample(10)

$dictation_num = 0

def dictation_word(audio)
  $dictation_num += 1
  uk_audio = audio.audio

  # 音标美音特殊处理 \[s\](.*?)\[\/s\]
  if uk_audio.start_with?("bre_")
    us_audio = audio.explanation.scan(/\[s\](\s?ame.*?)\[\/s\]/)[0]
    if !us_audio.nil? && !us_audio.empty?
      # 修改为美音 音标
      uk_audio = us_audio[0]

    end
    
  end
  audio_address = "https://memorysheep.com/longmandsl/" + uk_audio
  
  # 音标
  prons = audio.explanation.scan(/[^\[{]\s?\/(.*?[^\[])\/\s?/)[0]
  if !prons.nil? && !prons.empty?
    # 修改为美音 音标
    pron = prons[0]
    pron = pron.gsub(/\[i\s?\](.*?)\[\/i\]/, '\1'.italic)

  end


  error_size = 0
  loop do
    # puts "播放 ".red + "#{audio_address}"
    if error_size == 0
      puts ""
      puts "--------------------- 第 #{$dictation_num} 题---------------------"
      puts "请听写 ♫ ".green
    else
      # puts "重听".red
    end
    
    `mplayer -fs #{audio_address}`
    print "> "

    begin
      input_str = gets
      # return input_str.nil?
      input_str.chomp!
      input_str.strip!

    rescue SystemExit, Interrupt
      puts "\n再见~".green
      exit
    ensure
      
    end


    if input_str.strip.downcase == audio.content.strip.downcase
      if error_size < 3
        puts "正确 ✔ ".color(:green)
      end
      if error_size < 5
        puts audio.rainbow_explanation
        shanbay = Word.find_by(word: audio.content)
        puts shanbay.zh.green if !shanbay.nil?
      end
      DictationLog.create content: audio.content, audio: audio.audio, error_size: error_size
      break
    else
      error_size += 1
      if error_size >= 3 && error_size < 5
        puts "错误#{error_size}次以上 ☹".color(:cyan) + "\t 提示：".green+"/#{pron}/".bright
      elsif error_size >= 5
        puts audio.rainbow_explanation
        shanbay = Word.find_by(word: audio.content)
        puts shanbay.zh.green if !shanbay.nil?
      else
        puts "错误 ✖ ".red
      end
    end

  end
end

collins = Audio.where(collins: 3).pluck(:content)
# collins3 = result.map{|r| r["content"]}
# TODO: 跳过已经会默写的单词
knwon_words = DictationLog.where(error_size: 0).pluck(:content).uniq
 
unknown_words = collins - knwon_words
# require 'pry'
# binding.pry
# puts knwon_words
unknown_words.shuffle.each do |word|
  audios = Audio.where content: word
  audios.select{|audio| audio.audio.start_with?("bre_") && audio.explanation.match?(/[^\[]\/.*?[^\[]\//)}.each do |audio|
    dictation_word(audio)
    
  end
  # ap audios.first(3)
  # gets
end
