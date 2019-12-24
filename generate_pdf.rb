require "octokit"
require "prawn"
require "prawn/emoji"
require "pry"

Octokit.configure do |c|
  c.login = "nickcharlton"
  c.password = ENV["GITHUB_TOKEN"]
end

repo = Octokit.repo("thoughtbot/administrate")

issue_data = []
issues = repo.rels[:issues].get

loop do
  issues.data.each do |issue|
    issue_data.push(issue)
  end

  break unless issues.rels[:next]
  issues = issues.rels[:next].get
end

class HighlightCallback
  def initialize(options)
    @color = options[:color]
    @document = options[:document]
  end

  def render_behind(fragment)
    original_color = @document.fill_color
    @document.fill_color = @color
    @document.fill_rounded_rectangle(
      [fragment.top_left[0] - 2.5, fragment.top_left[1] + 2.5],
      fragment.width + 5,
      fragment.height + 5,
      7
    )

    @document.fill_color = original_color
  end
end

Prawn::Document.generate(
  "issues.pdf",
  page_size: "A6",
  page_layout: :landscape,
  margin: 10) do

  font_families.update(
    'DejaVu Sans' => {
      normal: File.expand_path("fonts/DejaVuSans.ttf", __dir__),
      bold: File.expand_path("fonts/DejaVuSans-Bold.ttf", __dir__),
      italic: File.expand_path("fonts/DejaVuSans-Oblique.ttf", __dir__),
    }
  )

  font('DejaVu Sans')

  issue_data.each_with_index do |issue, index|
    bounding_box([0, cursor - 0], width: 400, height: 65) do
      bounding_box([0, bounds.top], width: 25) do
        type = issue.key?(:pull_request) ? "git-pull-request" : "issue-opened"
        image "images/#{type}.png", width: 18
      end

      bounding_box([25, bounds.top], width: 315) do
        text_box issue[:title], at: [0, cursor], width: 315, height: 50, style: :bold, overflow: :shrink_to_fit
      end

      bounding_box([340, bounds.top], width: 60) do
        text "##{issue[:number]}", align: :right, color: "6a737d", size: 16
      end

      bounding_box([0, bounds.bottom + 15], width: 400) do
        type = issue.key?(:pull_request) ? "pull request" : "issue"
        text "<b>#{issue[:user][:login]}</b> opened this #{type} on #{issue[:created_at].strftime("%F")}", color: "586069", inline_format: true, size: 8
      end
    end

    stroke_color "586069"
    stroke do
      horizontal_rule
    end

    bounding_box([0, cursor - 10], width: 400, height: 185) do
      text_box issue[:body], at: [0, cursor], width: 400, overflow: :truncate, size: 10
    end

    bounding_box([0, cursor - 8], width: 400) do
      labels = issue[:labels].flat_map do |label|
        [
          {
            text: label[:name],
            callback: HighlightCallback.new(color: label[:color], document: self)
          },
          {
            text: "    ", # add four blank spaces between tags
          }
        ]
      end

      formatted_text labels, color: "ffffff", size: 8
    end

    start_new_page unless issue_data.count == (index + 1)
  end
end
