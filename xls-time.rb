# coding: utf-8

require 'rubyXL'
require 'sinatra'
require 'date'
require 'tilt/erubis'

get '/' do
  redirect '/upload'
end

get '/upload' do
  erb :upload
end

post '/upload' do
  timetable = RubyXL::Parser.parse params['myfile'][:tempfile]

  @employees = {}
  timetable[0].extract_data.each do |row|
    dat, point, name = row

    @employees[name] ||= {} 
    day = dat.strftime("%m/%d/%Y")

    @employees[name][day] ||= [dat, dat] # initial value: start = quit
    if dat > @employees[name][day].last # more recent activity, update quit time
      @employees[name][day][1] = dat
    end
  end

  @employees.each do |name, days|
    current_day = days.first[1][0]
    last_day = days.to_a.last[1][0] # dirty way to get last day

    while current_day < last_day do
      index = current_day.strftime("%m/%d/%Y")
      @employees[name][index] ||= false
      current_day = current_day.next
    end
    @employees[name] = @employees[name].sort_by {|day,times| DateTime.strptime day, '%m/%d/%Y' }
  end

  i = 0
  worksheet = timetable.add_worksheet('По дням')
  @employees.each do |name, days|
    days.each do |day, times|
      worksheet.add_cell i, 0, day
      if times
        worksheet.add_cell i, 1, times[0].strftime('%H:%M')
        worksheet.add_cell i, 2, times[1].strftime('%H:%M')
        worksheet.add_cell i, 3, name
      end
      i += 1
    end
  end
  # TODO: stream
  fname = "new-#{params['myfile'][:filename]}"
  timetable.write("processed/#{fname}")
  send_file "processed/#{fname}", filename: fname
end
