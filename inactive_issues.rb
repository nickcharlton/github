require "octokit"
require "active_support/time"
require "colored2"
require "pry"

Octokit.configure do |c|
  c.login = "nickcharlton"
  c.password = ENV["GITHUB_TOKEN"]
end

repo = Octokit.repo("thoughtbot/administrate")

issues = repo.rels[:issues].get

loop do
  issues.data.each do |issue|
    break if issue.pull_request?
    break if issue.comments.zero?

    author = issue.user.login
    comments = issue.rels[:comments].get.data

    replies_by_author = comments.map do |i|
      i if i.user.login == author
    end.compact

    replies_within_days = replies_by_author.select do |comment|
      comment.created_at > 28.days.ago
    end

    if replies_within_days.none?
      puts "Title:".underlined << " #{issue.title}"
      puts "Last reply:".underlined << " #{comments.last.created_at}"
      puts "URL:".underlined << " #{issue.html_url}"
      puts
    end
  end

  break unless issues.rels[:next]
  issues = issues.rels[:next].get
end
