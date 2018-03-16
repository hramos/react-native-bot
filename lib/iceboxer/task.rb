require 'octokit'
require 'active_support/all'

module Iceboxer

  @@operations = [
    Iceboxer::Closer,
    Iceboxer::Labeler,
    Iceboxer::OldVersion,
    Iceboxer::Template,
    Iceboxer::PullRequests
  ]

  def self.run
    unless ENV['GITHUB_API_TOKEN'].present?
      raise "Set GITHUB_API_TOKEN with a token with repo access"
    end

    unless ENV['ICEBOXER_REPOS'].present?
      raise "Set ICEBOXER_REPOS to repo(s) like 'org/repo1, org/repo2'"
    end

    Octokit.access_token = ENV['GITHUB_API_TOKEN']
    repositories = ENV["ICEBOXER_REPOS"].split(',').map(&:strip)

    puts "#{Octokit.rate_limit!.remaining} core API requests remaining... (search is limited to 30 req/min)"

    @@operations.each do |op|
      repositories.each do |repository|
        op.new(repository).perform
      end
    end
  end
end
