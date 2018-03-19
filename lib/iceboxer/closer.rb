require 'octokit'
require 'active_support/all'

module Iceboxer
  class Closer

    def initialize(repo)
      @repo = repo
    end

    def perform
      closers.each do |closer|
        issues = Octokit.search_issues(closer[:search])
        puts "#{@repo}: [CLOSERS] Found #{issues.items.count} issues..."
        issues.items.each do |issue|

          nag(issue, closer)
        end
      end
    end

    def closers
      [
        {
          :search => "repo:#{@repo} is:issue is:open label:\:no_entry_sign:For Stack Overflow\" NOT \"Stack Overflow\" in:comments NOT \"StackOverflow\" in:comments created:>2018-03-12",
          :message => "This issue looks like a question that would be best asked on [Stack Overflow](http://stackoverflow.com/questions/tagged/react-native).\n\nStack Overflow is amazing for Q&A: it has a reputation system, voting, the ability to mark a question as answered. Because of the reputation system it is likely the community will see and answer your question there. This also helps us use the GitHub bug tracker for bugs only.\n\nWill close this as this is really a question that should be asked on Stack Overflow.",
          :close_reason => "For Stack Overflow"
        },
        {
          :search => "repo:#{@repo} is:issue is:open label:\":clipboard:No Template\" -label:\"Core Team\" -label:\"For Discussion\" updated:<#{7.days.ago.to_date.to_s}",
          :message => "This issue was marked as lacking information required by the issue template. There has been no activity on this issue for a while, so I will go ahead and close it.\n\nIf you found this thread after encountering the same issue in the [latest release](https://github.com/facebook/react-native/releases), please feel free to create a new issue with up-to-date information by clicking [here](https://github.com/facebook/react-native/issues/new).\n\nIf you are the author of this issue and you believe this issue was closed in error (i.e. you have edited your issue to ensure it meets the template requirements), please let us know.",
          :close_reason => "Missing information, issue not updated in last seven days"
        }        
      ]
    end

    def nag(issue, reason)
      add_labels(issue, ["Ran Commands"])
      Octokit.add_comment(@repo, issue.number, reason[:message])
      Octokit.close_issue(@repo, issue.number)

      puts "🚫 [CLOSERS] #{issue.html_url}: #{issue.title} --> #{reason[:close_reason]}"
    end

    def message(reason)
      <<-MSG.strip_heredoc
      <!-- 
        {
          "closed_by":"react-native-bot",
          "close_reason": "#{reason[:close_reason]}"
        }
      -->
      #{reason[:message]}
      MSG
    end

    def add_labels(issue, labels)
      new_labels = []

      labels.each do |label|
        new_labels.push label unless issue_contains_label(issue, label)
      end

      if new_labels.count > 0
        puts "📍 [LABELS] #{issue.html_url}: #{issue.title} --> Adding #{new_labels}"
        Octokit.add_labels_to_an_issue(@repo, issue.number, new_labels)
      end
    end

    def issue_contains_label(issue, label)
      existing_labels = []

      issue.labels.each do |issue_label| 
        existing_labels.push issue_label.name if issue_label.name
      end

      existing_labels.include? label
    end        
  end
end