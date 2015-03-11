require 'html/proofer'

task :test do
  sh "bundle exec jekyll build"
  options = {
    :check_html => false,
    :verbose => false,
    :disable_external => true,
    :href_ignore => [
      '#'
    ],
    :alt_ignore => [
      /avatars\d+\.githubusercontent\.com/,
      /photon\.abstractj\.org/,
      /.*/
    ],
    :file_ignore => [
      /docs\/specs\/aerogear-cordova/,
      /docs\/guides\/aerogear-android/,
      /docs\/specs\/aerogear-ios/,
      /docs\/specs\/aerogear-js/,
      /news\/index\.html/
      #/docs\/unifiedpush/
    ]
  }
  HTML::Proofer.new("./_site", options).run
end