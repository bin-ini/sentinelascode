pipelineJob('SentinelDynamicPipelineRunner') {

    //def repositoryUrl = 'https://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@github.com/bin-ini/sentinelascode.git'

    parameters {
            stringParam('jenkinsFileSelected', 'repositoryUrl')
        }
        
   description("Placeholder Job for running the dynamic pipelines")
          

    definition {
        cpsScm {
              scm {
                git {
                  remote { url("${repositoryUrl}") }
                  branches('master')
                  scriptPath("${jenkinsFileSelected}")
                  extensions { }  // required as otherwise it may try to tag the repo, which you may not want
                }
              }
        }
  }
}
  queue('SentinelDynamicPipelineRunner')
