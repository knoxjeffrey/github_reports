require 'rubygems'
require 'bundler/setup'
require 'thor'

# these are required from the reports executable in bin folder which adds lib folder into the load path
require 'reports/github_api_client'
require 'reports/table_printer'

require 'dotenv'
Dotenv.load

module Reports

  class CLI < Thor

    desc "user_info USERNAME", "Get information for a user"
    def user_info(username)
      puts "Getting info for #{username}..."

      client = GitHubAPIClient.new(ENV['GITHUB_TOKEN'])
      user = client.user_info(username)

      puts "name: #{user.name}"
      puts "location: #{user.location}"
      puts "public repos: #{user.public_repos}"

    rescue Error => e
      puts "ERROR #{e.message}"
      exit 1 # raises the SystemExit exception
    end

    desc "console", "Open an RB session with all dependencies loaded and API defined."
    def console
      require 'irb'
      ARGV.clear
      IRB.start
    end

    private

    def client
      @client ||= GitHubAPIClient.new
    end

  end

end