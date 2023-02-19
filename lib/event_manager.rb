# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  file_name = "output/thanks_#{id}.html"

  File.open(file_name, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(number)
  number.gsub(/[-. ()E+]/, '')
end

def format_phone_number(clean_number)
  length_of_number = clean_number.length

  if length_of_number < 10 || length_of_number > 11 || (length_of_number == 11\
     && clean_number.start_with?('1') == false)
    'Phone number is incorrect!'
  elsif length_of_number == 11 && clean_number.start_with?('1')
    "+#{clean_number[1..10]}"
  else
    "+#{clean_number}"
  end
end

def get_time(reg_date)
  reg_date.split(' ')[1]
end

def get_date(reg_date)
  reg_date.split(' ')[0]
end

puts 'Event manager initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

parse_time = []

parse_date = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)

  number = row[:homephone]

  clean_number = clean_phone_number(number)

  correct_number = format_phone_number(clean_number)

  puts "#{name} #{correct_number}"

  reg_date = row[:regdate]

  time = get_time(reg_date)

  date = get_date(reg_date)

  parse_time.push(Time.parse(time).strftime('%k%p'))

  parse_date.push(Date.strptime(date, '%m/%d/%Y'))
end

hours = parse_time.each_with_object(Hash.new(0)) do |hour, result|
  result[hour] += 1
end

hours.each { |hour, number| puts "Hour: #{hour} - Number of registered attendees: #{number}" }

day_of_week = parse_date.each_with_object(Hash.new(0)) do |day, result|
  result[day.wday] += 1
end

day_of_week.each { |day, number| puts "The day of the week: #{day} - Number of registered attendees: #{number}" }
