class User::StashReposController < User::ScmReposController

  before_filter :authenticate


  def index
    status_message = ''
    status_success = true
    task_status = ''

    if current_user.stash_token.nil?
      status_message = 'Your VersionEye account is not connected to Stash.'
      status_success = false
      task_status = StashService::A_TASK_DONE
    else
      task_status = StashService.cached_user_repos current_user
      user_repos = current_user.stash_repos
      if user_repos && user_repos.count > 0
        user_repos = user_repos.desc(:created_at)
      end

      if task_status == StashService::A_TASK_DONE and user_repos.count == 0
        status_message = %w{
          We couldn't find any repositories in your Stash account.
          If you think that's an error please contact the VersionEye team.
        }.join(' ')
        status_success = false
      end
    end

    render json: {
      success: status_success,
      task_status: task_status,
      repos: user_repos,
      message: status_message
    }.to_json
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    render text: "An error occured. We are not able to import Stash repositories. Please contact the VersionEye team.", status: 503
  end


end
