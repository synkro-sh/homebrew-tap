# Download strategy for release assets on a *private* GitHub repository.
#
# Homebrew's default fetch sends no GitHub credentials, so a private release
# asset answers 404 and the install fails with a confusing "no such file".
# Private assets are only reachable through the REST API, by numeric asset id
# rather than by filename, with an explicit octet-stream Accept header.
#
# So this strategy resolves tag + filename to an asset id, then fetches that
# id with the user's token attached.

require "download_strategy"

class GitHubPrivateReleaseDownloadStrategy < CurlDownloadStrategy
  def initialize(url, name, version, **meta)
    super
    parse_url_pattern
    set_github_token
  end

  def parse_url_pattern
    pattern = %r{https://github\.com/([^/]+)/([^/]+)/releases/download/([^/]+)/(\S+)}
    unless @url =~ pattern
      raise CurlDownloadStrategyError, "Invalid URL pattern for GitHub release asset: #{@url}"
    end

    _, @owner, @repo, @tag, @filename = *@url.match(pattern)
  end

  def download_url
    "https://api.github.com/repos/#{@owner}/#{@repo}/releases/assets/#{asset_id}"
  end

  private

  def _fetch(url:, resolved_url:, timeout:)
    curl_download(
      download_url,
      "--header", "Accept: application/octet-stream",
      "--header", "Authorization: token #{@github_token}",
      to:      temporary_path,
      timeout: timeout,
    )
  end

  def set_github_token
    @github_token = ENV.fetch("HOMEBREW_GITHUB_API_TOKEN", nil)
    if @github_token.blank?
      raise CurlDownloadStrategyError, <<~EOS
        synkro is distributed from a private repository, so Homebrew needs a token.

        Create a token with `repo` scope at https://github.com/settings/tokens
        and export it before installing:

            export HOMEBREW_GITHUB_API_TOKEN=ghp_your_token_here
      EOS
    end

    validate_github_repository_access!
  end

  # Fail here, where the cause is nameable, rather than letting an
  # unauthorised token surface later as an opaque 404 on the asset.
  def validate_github_repository_access!
    GitHub.repository(@owner, @repo)
  rescue GitHub::API::HTTPNotFoundError
    raise CurlDownloadStrategyError, <<~EOS
      HOMEBREW_GITHUB_API_TOKEN cannot read #{@owner}/#{@repo}.

      The token is valid but lacks access to this private repository. Confirm
      you have been granted read access, and that the token carries `repo` scope.
    EOS
  end

  def asset_id
    @asset_id ||= resolve_asset_id
  end

  def resolve_asset_id
    assets = fetch_release_metadata["assets"].select { |a| a["name"] == @filename }
    if assets.empty?
      raise CurlDownloadStrategyError, "No asset named #{@filename} on release #{@tag}."
    end

    assets.first["id"]
  end

  def fetch_release_metadata
    GitHub::API.open_rest(
      "https://api.github.com/repos/#{@owner}/#{@repo}/releases/tags/#{@tag}",
    )
  end
end
