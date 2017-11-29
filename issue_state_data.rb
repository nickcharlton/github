require "octokit"
require "active_support/time"
require "colored2"
require "pry"
require "csv"

Octokit.configure do |c|
  c.login = "nickcharlton"
  c.password = ENV["GITHUB_TOKEN"]
end

repo = Octokit.repo("thoughtbot/administrate")

issues = repo.rels[:issues].get(query: { direction: "asc", state: "all" })

date_range = (repo.created_at.to_date..Date.today)
issue_events = date_range.map { |date| [date, 0] }.to_h

issue_open_events = issue_events.dup
issue_close_events = issue_events.dup

loop do
  issues.data.each do |issue|
    issue_open_events[issue.created_at.to_date] += 1

    if issue.closed_at
      issue_close_events[issue.closed_at.to_date] += 1
    end
  end

  break unless issues.rels[:next]
  issues = issues.rels[:next].get
end

accumulated_issue_count = 0
data = [
  ["date", "open_event", "close_event", "total_issues"],
]

date_range.each do |date|
  created_at_events = issue_open_events[date]
  closed_at_events = issue_close_events[date]
  accumulated_issue_count =
    accumulated_issue_count + created_at_events - closed_at_events

  data << [date, created_at_events, closed_at_events, accumulated_issue_count]
end

puts data.reduce([]) { |csv, row| csv << CSV.generate_line(row) }.join("")
