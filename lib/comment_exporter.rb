#!/usr/bin/env ruby
require 'csv'

class CommentExporter
  def initialize(comment_fetcher, filename)
    @fetcher = comment_fetcher
    @output = filename
  end

  def export
    CSV.open(@output, 'wb') do |csv|
      csv << ["Repo", "Pull Request #", "Pull Request Date/Time", "Author", "Commenter",
              "Comment ID", "Comment Date/Time", "Comment"]
      @fetcher.each do |c, pull|
        csv << [
          "=HYPERLINK(\"#{pull.base.repo.html_url}\", \"#{pull.base.repo.full_name}\")",
          "=HYPERLINK(\"#{pull.html_url}\", \"#{pull.number}\")",
          pull.created_at.to_s,
          pull.user.login,
          c.user.login,
          "=HYPERLINK(\"#{c.html_url}\", \"#{c.id}\")",
          c.created_at.to_s,
          c.body
        ]
      end
    end
  end
end
