#!/usr/bin/env ruby
require 'octokit'

class CommentDumper

  attr_accessor :repo, :start_time, :end_time

  def initialize(repo, start_time: nil, end_time: nil)
    @repo = repo
    @start_time = start_time
    @end_time = end_time || Time.now
  end

  def client
    @client ||= Octokit::Client.new login: user, password: password
  end

  def pulls
    @pulls ||= fetch_pulls(@repo, start_time: @start_time, end_time: @end_time)
  end

  def pulls=(new_pulls)
    comments = nil
    @pulls = new_pulls
  end

  def repo=(new_repo)
    pulls = nil
    @repo = new_repo
  end

  def start_time=(new_start_time)
    pulls = nil
    @start_time = new_start_time
  end

  def end_time=(new_end_time)
    pulls = nil
    @end_time = new_end_time
  end

  def comments
    @comments ||= fetch_comments(pulls)
  end

  def comments=(new_comments)
    @comments = new_comments
  end

  private

  def user
    ENV.fetch('GITHUB_COMMENTS_USER')
  end

  def password
    ENV.fetch('GITHUB_COMMENTS_PASSWORD')
  end

  def fetch_pulls(repo, start_time: nil, end_time: nil)
    pulls = []
    pulls_page = client.pulls repo, state: 'all', per_page: 100,
                                    sort: 'created', direction: 'desc'
    next_page = client.last_response.rels[:next]
    continue_fetching = true

    while continue_fetching
      continue_fetching =
        collect_pull_page(pulls, pulls_page, start_time, end_time)
      if continue_fetching
        next_results = next_page.get
        pulls_page = next_results.data
        next_page = next_results.rels[:next]
      end
    end
    pulls
  end

  def collect_pull_page(pulls, pulls_page, start_time, end_time)
    pulls_page.each do |pull|
      pull_time = pull.created_at
      next if !end_time.nil? && pull_time > end_time
      return false if !start_time.nil? && pull_time < start_time
      pulls << pull
    end
    true
  end

  def fetch_comments(pulls)
    comments = []
    pulls.each do |pull|
      pull.rels[:comments].get.data.each do |comment|
        comments << {
          pull: pull,
          comment: comment
        }
      end
    end
    comments
  end
end

# [80] pry(main)> csv_string = CSV.open('test.csv', 'wb') do |csv|
# [80] pry(main)*   csv << ["Repo", "Pull Request #", "Author", "Commenter", "Comment"]
# [80] pry(main)*   all_comments.flatten.each do |c|
# [80] pry(main)*     pull = pulls_by_url[c.pull_request_url]
# [80] pry(main)*     csv << ["=HYPERLINK(\"#{pull.base.repo.html_url}\", \"#{pull.base.repo.full_name}\")", "=HYPERLINK(\"#{pull.html_url}\", \"#{pull.number}\")", pull.user.login, c.user.login, c.body]
# [80] pry(main)*   end
# [80] pry(main)* end; nil
