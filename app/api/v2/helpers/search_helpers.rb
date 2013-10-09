module SearchHelpers
  def process_search_results(raw_results)
    results = []
    raw_results['items'].each  do |item|
      results << {
        id: item['id'],
        name: item['full_name'],
        language: item['language'],
        owner_name: item['owner']['login'],
        owner_type: item['owner']['type'].to_s.downcase,
        private: item['private'],
        fork: item['fork'],
        html_url: item['html_url'],
        git_url: item['git_url'],
        size: item['size'],
        watchers: item['watchers_count'],
        forks: item['forks_count'],
        issues: item['open_issues'],
        score: item['score']
      }
    end

    results
  end
end