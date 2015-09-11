require 'rubygems'
require 'bundler/setup'
require 'thor'

# these are required from the reports executable in bin folder which adds lib folder into the load path
require 'reports/github_api_client'
require 'reports/table_printer'

require 'dotenv'
Dotenv.load

require 'byebug'

module Reports

  class CLI < Thor

    desc "user_info USERNAME", "Get information for a user"
    def user_info(username)
      puts "Getting info for #{username}..."

      client = GitHubAPIClient.new
      user = client.user_info(username)

      puts "name: #{user.name}"
      puts "location: #{user.location}"
      puts "public repos: #{user.public_repos}"

    rescue Error => e
      puts "ERROR #{e.message}"
      exit 1 # raises the SystemExit exception
    end

    desc "repositories USERNAME", "Load the repo stats for USERNAME"
    option :forks, type: :boolean, desc: "Include forks in stats", default: false

    def repositories(username)
      puts "Fetching repository statistics for #{username}..."

      client = GitHubAPIClient.new
      repos = client.public_repos_for_user(username, forks: options[:forks]).compact

      puts "#{username} has #{repos.size} public repos.\n\n"

      table_printer = TablePrinter.new(STDOUT)

      repos.each do |repo|
        table_printer.print(repo.languages, title: repo.name, humanize: true)
        puts # blank line
      end

      stats = Hash.new(0)
      repos.each do |repo|
        repo.languages.each_pair do |language, bytes|
          stats[language] += bytes
        end
      end

      table_printer.print(stats, title: "Language Summary", humanize: true, total: true)

    rescue Error => e
      puts "ERROR #{e.message}"
      exit 1
    end

    desc "activity USERNAME", "Get event types for a user"
    def activity(username)
      puts "Fetching activity for #{username}..."

      client = GitHubAPIClient.new
      events = client.public_events_for_user(username)
      puts "Fetched #{events.size} events.\n\n"

      print_activity_report(events)
    rescue Error => e
      puts "ERROR #{e.message}"
      exit 1
    end

    desc "activity", "Create a new private gist"
    def create_private_gist(description, file, content)
      puts "Creating a new private gist..."

      client = GitHubAPIClient.new
      gist = client.create_private_gist(description, file, content)
      puts "Woo hoo! New gist created at #{gist}"
    rescue Error => e
      puts "ERROR #{e.message}"
      exit 1
    end

    desc "activity", "Star a repository"
    def star_repository(username, repo)
      puts "Starring a repository..."

      client = GitHubAPIClient.new
      star = client.star_repository(username, repo)
      puts "Congrats, #{username} will feel awesome now you have starred #{repo}!"
    rescue Error => e
      puts "ERROR #{e.message}"
      exit 1
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

    def print_activity_report(events)
      table_printer = TablePrinter.new(STDOUT)
      event_types_map = events.each_with_object(Hash.new(0)) do |event, counts|
        counts[event.type] += 1
      end

      table_printer.print(event_types_map, title: "Event Summary", total: true)
      push_events = events.select { |event| event.type == "PushEvent" }
      push_events_map = push_events.each_with_object(Hash.new(0)) do |event, counts|
        counts[event.repo_name] += 1
      end

      puts # blank line
      table_printer.print(push_events_map, title: "Project Push Summary", total: true)
    end

  end

end