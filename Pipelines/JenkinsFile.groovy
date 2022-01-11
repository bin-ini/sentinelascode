pipelineJob('SentinelCICDRelevantJob') {

  def repo = 'https://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@github.com/bin-ini/sentinelascode.git'

  description("Pipeline for Sentinelcode")
  
  parameters {
        stringParam('jenkinsFileSelected', '...', '...')
    }

  definition {
    cpsScm {
      scm {
        git {
          remote { url(repo) }
          branches('master')
          scriptPath("${jenkinsFileSelected}")
          extensions { }  // required as otherwise it may try to tag the repo, which you may not want
        }

      }
    }
  }
  
}
  queue('SentinelCICDRelevantJob')
