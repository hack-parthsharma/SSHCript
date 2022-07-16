require 'net/ssh'
require 'io/console'

class SSHTask
  @@host_path = nil
  @@cmds_path = nil
  @@username  = nil
  @@password  = nil

  @@hosts = []
  @@cmds  = []

  def initialize(host_path, cmds_path, username, password)
    @@host_path = host_path
    @@cmds_path = cmds_path
    @@username  = username
    @@password  = password

    parse_hosts
    parse_cmds

    run_cmds_on_hosts
  end

  # loop through each host and run each command
  def run_cmds_on_hosts
    @@hosts.each do |host|
      @@cmds.each do |cmd|
        puts "-> Connecting to #{host}..."
        run_task(host, @@username, @@password, cmd)
      end
    end
  end

  # read each line from the host file path and add it to @@hosts
  def parse_hosts
    File.open(@@host_path, 'r') do |f|
      f.each_line do |line|
        @@hosts << line.chomp
      end
    end
  end

  # read each line from the cmds file path and add it to @@cmds
  def parse_cmds
    File.open(@@cmds_path, 'r') do |f|
      f.each_line do |line|
        @@cmds << line.chomp
      end
    end
  end

  # connect to host with username, password, and execute cmd (puts stdout)
  def run_task(host, username, password, cmd)
    begin
      Net::SSH.start(host, username, :password => password) do |ssh|
        puts "-> Executing: [ #{cmd} ]"
        output = ssh.exec!(cmd)
        puts ">> #{output}"
      end
    rescue Errno::EHOSTUNREACH
      puts "[-] #{host} is unreachable."
    rescue Errno::ECONNREFUSED
      puts "[-] #{host} refused the connection."
    rescue Net::SSH::AuthenticationFailed
      puts "[-] Authentication failure."
    rescue Timeout::Error
      puts "[-] Connection timed out."
    end
  end
end

puts '-- [ sshcript'

print '-> File path of hosts: '
host_path = gets.chomp

print '-> File path of commands to execute: '
cmds_path = gets.chomp

print '-> Username for hosts: '
username = gets.chomp

print '-> Password for hosts (hidden): '
password = STDIN.noecho(&:gets).chomp
puts ''
s = SSHTask.new(host_path, cmds_path, username, password)