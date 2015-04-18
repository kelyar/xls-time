require 'rubyXL'
require 'sinatra'
require 'date'

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
    day = dat.strftime("%Y%m%d")

    @employees[name][day] ||= [dat, dat] # initial value: start = quit
    if dat > @employees[name][day].last # more recent activity, update quit time
      @employees[name][day][1] = dat
    end
  end

  erb :result
end
