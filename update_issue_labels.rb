#!/usr/bin/env ruby

# update_issues: For a CSV of issue numbers and labels, set to the new values
#
# This expects a CSV that looks like: `100,label-one,label-two,`,
# the empty value at the end will be stripped out.
#
# Notably, this replaces all of the labels, removing any which are already
# there.
require "octokit"
require "csv"
require "pry"

Octokit.configure do |c|
  c.login = "nickcharlton"
  c.password = ENV["GITHUB_TOKEN"]
end

CSV.foreach("tagged-issues.csv") do |row|
  issue_id = row.shift
  labels = row.compact

  Octokit.client.replace_all_labels("thoughtbot/administrate", issue_id, labels)
end
