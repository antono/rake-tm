# Time management tasks

TLOG = File.join(ENV['HOME'], '.tm.log')

namespace :tm do

  def project_name
    path = Pathname.new(RAILS_ROOT)
    path.split.last.to_s
  end

  def load_log
    File.open(TLOG,'w') { |f| f.write YAML.dump(Hash.new) } unless File.exist?(TLOG)
    YAML.load_file(TLOG) 
  end

  def save_log(log)
    File.open(TLOG, 'w') { |f| f.write(YAML.dump(log)) }
  end

  def report(what)
    log = load_log
    log[project_name] ||= []
    last_action = log[project_name].last.keys[0] if log[project_name].last
    unless what == last_action || log.empty?
      if log[project_name].empty? && what == 'stop'
        puts "You haven't starded tracking yet..."
        exit
      end
      log[project_name] << { what => Time.now }
      save_log(log)
    else
      puts "Last action was #{last_action}. Current have to be another!"
    end
  end

  desc 'Report start working on project'
  task :start do
    report('start')
  end

  desc 'Report finish working on project'
  task :stop do
    report('stop')
  end

  desc 'Time report'
  task :total do
    stats = {}
    log = YAML.load_file(TLOG)
    log.each_pair do |project,log| 
      puts '-' * 80, project
      total_time_spent = 0
      log.in_groups_of(2) do |first,second|
        second ||= { 'stop' => Time.now } # if tracking in progress
        if first.keys.first == 'start' && second.keys.first == 'stop'
          total_time_spent += second['stop'] - first['start']
        else
          puts 'Something wrong with start/stop symetry...'
          puts 'Check your ~/.tm.log for double start/stops...'
        end
      end
      hours   = total_time_spent / 1.hour
      minutes = (total_time_spent % 1.hour) / 1.minute
      puts "Total time spent: #{[hours.to_i,minutes.to_i].join(':')}"
    end
  end
end
