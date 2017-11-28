require "octokit"
require "active_support/time"
require "colored2"
require "pry"

Octokit.configure do |c|
  c.login = "nickcharlton"
  c.password = ENV["GITHUB_TOKEN"]
end

repo = Octokit.repo("thoughtbot/administrate")

pulls = repo.rels[:pulls].get

loop do
  pulls.data.each do |pull|
    author = pull.user.login
    comments = pull.rels[:comments].get.data

    break if comments.empty?

    replies_by_author = comments.map do |i|
      i if i.user.login == author
    end.compact

    replies_within_days = replies_by_author.select do |comment|
      comment.created_at > 28.days.ago
    end

    if replies_within_days.none?
      puts "Title:".underlined << " #{pull.title}"
      puts "Last reply:".underlined << " #{comments.last.created_at}"
      puts "URL:".underlined << " #{pull.html_url}"
      puts
    end
  end

  break unless pulls.rels[:next]
  pulls = pulls.rels[:next].get
end
