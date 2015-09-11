require 'vcr_helper'
require 'reports/github_api_client'

require 'dotenv'
Dotenv.load

require 'byebug'

module Reports
  RSpec.describe GitHubAPIClient do

    describe "#user_info" do
      it "fetches info for a user", vcr: true do
        client = GitHubAPIClient.new

        data = client.user_info("octocat")

        expect(data.name).to eql("The Octocat")
        expect(data.location).to eql("San Francisco")
        expect(data.public_repos).to eql(5)
      end

      it "raises an exception when a user doesn't exist", vcr: true do
        client = GitHubAPIClient.new

        expect(->{
          client.user_info("auserthatdoesnotexist")
        }).to raise_error(Reports::Nonexistentuser)
      end
    end

  end
end
