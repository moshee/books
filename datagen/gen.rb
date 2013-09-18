#!/usr/bin/env ruby
# encoding: utf-8

require 'randexp'
require 'erb'

$files = {}
Dir['*.txt'].each do |file|
  $files[File.basename(file, '.txt').intern] = File.open(file).each_line.map(&:chomp)
end

def sample(sym)
  p = $files[sym.intern].sample.sub('[', '').sub(']', '').tr('[]', '()').gsub('( )', ' ').gsub('|)', ')').gsub('(|', '(').gsub('||', '|')
  Regexp.new(p).gen end

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
  "( #{args.join(', ')} )"
end

def rec(n)
  n.times.map { tuple *yield }.join(",\n") + ';' end

class Numeric
  def pad2
    self.to_s.rjust(2, '0')
  end
end

def text(*args)
  "'#{args.join(' ')}'" end

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

CJK = 0x4e00..0x9fff

def cjk_name
  n = rand 3..4
  n.times.map { rand CJK }.pack('U' * n)
end


def bytea(length=64)
  text ("\\x" + /[a-f0-9]{#{length}}/.gen) end

email_re = /\w{1,20}@\w{3,20}\.(com|net|org|us|eu|co\.jp|mx)/

def email
  email_re.gen end

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

puts ERB.new(File.open('testdata.sql').read).result
