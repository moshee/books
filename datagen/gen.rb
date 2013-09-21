#!/usr/bin/env ruby
# encoding: utf-8

# TODO: - sql parsing and generator choosing
#       - enum parsing in particular
#       - cross-field combination uniqueness enforcement
#       - automatic logical sorting
#       - better generators
require 'randexp'
require 'erb'

CJK = [
  0x4e00..0x9faf, # CJK Unified 1
  0x3041..0x3094, # Hiragana
  0x30a1..0x30fc  # Katakana
]

class Randgen
  def self.ja_name(opts={})
    n = opts[:length]
    n.times.map { rand(CJK.first).chr(Encoding::UTF_8) }.join('')
  end
  def self.ja(opts={})
    n = opts[:length]
    n.times.map { rand(CJK.sample).chr(Encoding::UTF_8) }.join('')
  end
end

def cjk_name
  text /[:ja_name:]{1,2} [:ja_name:]{1,2}/.gen end

def ja_title
  text /[:ja:]{2,15}/.gen end

$files = {}
Dir['*.txt'].each do |file|
  $files[File.basename(file, '.txt').intern] = File.open(file).each_line.map(&:chomp)
end

$files[:countries].map! { |s| s.split(',').first }

def sample(sym)
  p = $files[sym.intern].sample.sub('[', '').sub(']', '').tr('[]', '()').gsub('( )', ' ').gsub('|)', ')').gsub('(|', '(').gsub('||', '|')
  text Regexp.new(p).gen end

=begin

$firstnames, $lastnames = [], []

i = 0
File.open('namedb/data/data.dat').each_line do |line|
  i += 1
  next unless i%10 == 0
  rec = line.chomp.split(',')
  $lastnames.push [rec.first, rec.last] if rec[3] == '1'
  $firstnames.push [rec.first, rec.last] if rec[4] == '1'
end

$firstnames.sort_by &:last
$lastnames.sort_by &:last
=end

def tuple(*args)
  "( #{args.map { |b| if b.nil? then 'NULL' else b end }.join(', ')} )"
end

def rec(n, repeat_chance=0.0, repeat_range=1..2)
  if repeat_chance == 0.0
    n.times.map { |n| tuple *(yield n+1) }.join(",\n") + ';'
  else
    i = 1
    display = 1
    arr = Array.new(n)
    loop do
      break if i > n
      t = rand repeat_range
      if rand > repeat_chance and t == 1
        arr[i-1] = yield display, false
        i += 1
        display += 1
        next
      end
      
      t.times do
        arr[i-1] = yield display, true
        i += 1
        break if i > n
      end
      display += 1
    end
    arr.map(&method(:tuple)).join(",\n") + ';'
  end
end

class Numeric
  def pad2
    self.to_s.rjust(2, '0')
  end
end

def text(*args)
  "'#{args.map { |s| s.gsub("'", "''") }.join(' ')}'" end

def randdate
  Time.at(rand Time.now.to_i) end

def date
  d = randdate
  text "#{d.year}-#{d.month.pad2}-#{d.day.pad2}" end

def tstz
  d = randdate
  text "#{d.year}-#{d.month.pad2}-#{d.day.pad2} #{d.hour.pad2}:#{d.min.pad2}:#{d.sec.pad2} #{d.zone}" end

def string
  text $files[:lipsum].sample end

def longstring(max=5)
  text rand(1..max).times.map { $files[:lipsum].sample }.join(' ') end

def lang(bias='en', amt=nil)
  if !amt.nil? and rand < amt
    text bias
  else
    text $files[:langs].sample
  end
end

def country
  text $files[:countries].sample end

def name
  text $files[:firstnames].sample, $files[:lastnames].sample end

def firstname
  text $files[:firstnames].sample end

def lastname
  text $files[:lastnames].sample end

def gender
  text (if rand < 0.005 then 2 else rand 0..1 end) end

def bytea(length=32)
  text('\x' + length.times.map { rand(255).to_s(16).rjust(2, '0') }.join('')) end

def email
  text /\w{1,20}@\w{3,20}\.(com|net|org|us|eu|co\.jp|mx)/.gen end

def url
  text /https?:\/\/(www\.)?\w{3,15}\.(com|org|co\.jp|net|jp)/.gen end

def bool(yes=0.5)
  if rand < yes
    'true'
  else
    'false'
  end
end

def null(chance=0.5)
  if rand < chance
    'NULL'
  else
    false
  end
end

filename = if ARGV.size.zero? then 'template.sql' else ARGV.pop end

puts ERB.new(File.open(filename).read).result
