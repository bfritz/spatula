# Prepare :server: for chef solo to run on it
module Spatula
  class Prepare < SshCommand
    def run
      upload_ssh_key if @upload_key
      send "run_for_#{os}"
    end

    def os
      etc_issue = `#{ssh_command("cat /etc/issue")}`
      case etc_issue
      when /ubuntu/i
        "ubuntu"
      when /debian/i
        "debian"
      when /fedora/i
        "fedora"
      when ""
        raise "Couldn't get system info from /etc/issue. Please check your SSH credentials."
      else
        raise "Sorry, we currently only support prepare on ubuntu, debian & fedora. Please fork http://github.com/trotter/spatula and add support for your OS. I'm happy to incorporate pull requests."
      end
    end

    def run_for_ubuntu
      ssh "sudo apt-get update"
      ssh "sudo aptitude -y install ruby irb ri libopenssl-ruby1.8 libshadow-ruby1.8 ruby1.8-dev gcc g++ rsync curl"
      ssh "curl -L 'http://rubyforge.org/frs/download.php/69365/rubygems-1.3.6.tgz' | tar xvzf -"
      ssh "cd rubygems* && sudo ruby setup.rb --no-ri --no-rdoc"
      ssh "sudo ln -sfv /usr/bin/gem1.8 /usr/bin/gem"

      ssh "sudo gem install rdoc chef ohai --no-ri --no-rdoc --source http://gems.opscode.com --source http://gems.rubyforge.org"
    end

    def run_for_debian
      ssh 'sudo apt-get update'
      ssh 'sudo apt-get install -y build-essential zlib1g-dev libssl-dev libreadline5-dev curl rsync screen vim'
      ssh 'curl -L http://rubyforge.org/frs/download.php/71096/ruby-enterprise-1.8.7-2010.02.tar.gz | tar xzvf -'
      # install REE 1.8.7 (and rubygems and irb and rake) to /usr
      ssh 'cd ruby-enterprise-1.8.7-2010.02 && sudo echo -e "\n/usr\n" | ./installer'

      ssh "sudo gem install rdoc chef ohai --no-ri --no-rdoc --source http://gems.opscode.com --source http://gems.rubyforge.org"
    end

    def run_for_fedora
      sudo = ssh('which sudo > /dev/null 2>&1') ? 'sudo' : ''
      ssh "#{sudo} yum install -y make gcc rsync sudo openssl-devel rubygems ruby-devel ruby-shadow"
      ssh "#{sudo} gem install chef --no-ri --no-rdoc --source http://gems.opscode.com --source http://gems.rubyforge.org"
    end

    def upload_ssh_key
      authorized_file = "~/.ssh/authorized_keys"
      key_file = nil
      %w{rsa dsa}.each do |key_type|
        filename = "#{ENV['HOME']}/.ssh/id_#{key_type}.pub"
        if File.exists?(filename)
          key_file = filename
          break
        end
      end
      key = File.open(key_file).read.split(' ')[0..1].join(' ')
      ssh "mkdir -p .ssh && echo #{key} >> #{authorized_file}"
      ssh "cat #{authorized_file} | sort | uniq > #{authorized_file}.tmp && mv #{authorized_file}.tmp #{authorized_file}"
    end
  end
end
